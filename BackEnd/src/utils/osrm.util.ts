import axios from 'axios';

const OSRM_BASE_URL = 'https://router.project-osrm.org';
const OSRM_TIMEOUT_MS = 10000;
const OSRM_MAX_RETRIES = 2;

/**
 * Fetch a driving route from source to destination.
 * Returns encoded polyline string or null on failure.
 */
export async function getRouteOSRM(
  source: [number, number],
  destination: [number, number],
): Promise<string | null> {
  try {
    const [srcLng, srcLat] = source;
    const [dstLng, dstLat] = destination;

    // Basic sanity check
    if (!srcLat || !srcLng || !dstLat || !dstLng) {
      console.error('[OSRM] Invalid coordinates:', { source, destination });
      return null;
    }

    const url = `${OSRM_BASE_URL}/route/v1/driving/${srcLng},${srcLat};${dstLng},${dstLat}?overview=full&geometries=polyline`;
    console.log('[OSRM] Requesting route:', url);

    const response = await axios.get(url, { timeout: OSRM_TIMEOUT_MS });

    if (
      response.data &&
      response.data.routes &&
      response.data.routes[0] &&
      response.data.routes[0].geometry
    ) {
      const polyline = response.data.routes[0].geometry as string;
      console.log('[OSRM] Got polyline, length:', polyline.length);
      return polyline;
    }
    console.log('[OSRM] No geometry in response:', JSON.stringify(response.data));
    return null;
  } catch (error: any) {
    if (error.code === 'ECONNABORTED') {
      console.error('[OSRM] Request timed out');
    } else {
      console.error('[OSRM] Error fetching route:', error?.message ?? error);
    }
    return null;
  }
}

/**
 * Snap a single GPS coordinate to the nearest road using OSRM Match API.
 * Used as a server-side fallback when the client doesn't send snapped coordinates.
 * Returns the snapped (lat, lng) tuple or null on failure.
 */
export async function snapToRoadOSRM(
  lat: number,
  lng: number,
): Promise<{ lat: number; lng: number } | null> {
  if (!lat || !lng) {
    console.error('[OSRM:snap] Invalid coordinates:', { lat, lng });
    return null;
  }

  for (let attempt = 0; attempt <= OSRM_MAX_RETRIES; attempt++) {
    try {
      const url = `${OSRM_BASE_URL}/match/v1/driving/${lng},${lat}?overview=simplified&gps_precision=10`;
      console.log(
        `[OSRM:snap] Attempt ${attempt + 1}/${OSRM_MAX_RETRIES + 1}: ${url}`,
      );

      const response = await axios.get(url, { timeout: OSRM_TIMEOUT_MS });

      if (
        response.data?.matchings &&
        response.data.matchings.length > 0 &&
        response.data.matchings[0].geometry
      ) {
        const matching = response.data.matchings[0];

        // Prefer matched "waypoint" coordinates (most accurate)
        if (matching.waypoints && matching.waypoints.length > 0) {
          const waypoint = matching.waypoints[0];
          if (
            waypoint.location &&
            Array.isArray(waypoint.location) &&
            waypoint.location.length === 2
          ) {
            // OSRM returns [lng, lat]
            const [snappedLng, snappedLat] = waypoint.location;
            if (snappedLat && snappedLng) {
              console.log(
                `[OSRM:snap] Success: ${lat},${lng} -> ${snappedLat},${snappedLng} (confidence=${matching.confidence})`,
              );
              return { lat: snappedLat, lng: snappedLng };
            }
          }
        }

        // Fallback: use first point of geometry
        const firstPoint = matching.geometry?.coordinates?.[0];
        if (firstPoint && Array.isArray(firstPoint) && firstPoint.length >= 2) {
          const [snappedLng, snappedLat] = firstPoint;
          if (snappedLat && snappedLng) {
            console.log(
              `[OSRM:snap] Success (geometry): ${lat},${lng} -> ${snappedLat},${snappedLng}`,
            );
            return { lat: snappedLat, lng: snappedLng };
          }
        }
      }
      console.warn(`[OSRM:snap] No matchings in response (attempt ${attempt + 1})`);
      return null;
    } catch (error: any) {
      const msg = error.code === 'ECONNABORTED' ? 'timed out' : error?.message ?? error;
      console.error(`[OSRM:snap] Error (attempt ${attempt + 1}): ${msg}`);
      if (attempt < OSRM_MAX_RETRIES) {
        // Wait briefly before retry
        await new Promise((r) => setTimeout(r, 500 * (attempt + 1)));
        continue;
      }
      return null;
    }
  }
  return null;
}
