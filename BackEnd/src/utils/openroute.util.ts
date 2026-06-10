import { getRouteOSRM } from './osrm.util.js';

export interface RouteResult {
  routeToStore: string | null;
  routeToDestination: string | null;
}

// Primary routing via OSRM (free, no API key required).
// Kept the function name compatible so no other files need to change.
export async function getRoute(
  source: [number, number],
  destination: [number, number],
): Promise<string | null> {
  return getRouteOSRM(source, destination);
}

export async function getRouteWithORSAndFallback(
  source: [number, number],
  destination: [number, number],
): Promise<string | null> {
  const MIN_POLYLINE_LENGTH = 10;

  let result = await getRouteOSRM(source, destination);

  if (!result || result.length < MIN_POLYLINE_LENGTH) {
    console.log(
      `[Routing] OSRM returned invalid/short polyline (length: ${result?.length ?? 0}), retrying...`,
    );
    // Retry once
    result = await getRouteOSRM(source, destination);
    if (result && result.length >= MIN_POLYLINE_LENGTH) {
      console.log('[Routing] OSRM retry succeeded, length:', result.length);
    } else {
      console.error('[Routing] OSRM failed after retry. source:', source, 'dest:', destination);
      result = null;
    }
  } else {
    console.log('[Routing] OSRM succeeded, polyline length:', result.length);
  }

  return result;
}

export async function getRouteWithRetry(
  source: [number, number],
  destination: [number, number],
  retries = 2,
): Promise<string | null> {
  for (let i = 0; i <= retries; i++) {
    const result = await getRouteOSRM(source, destination);
    if (result) return result;
    if (i < retries) {
      await new Promise((resolve) => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
  console.error('[Routing] All retries failed');
  return null;
}