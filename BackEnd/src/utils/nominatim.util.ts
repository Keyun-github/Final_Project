import axios from 'axios';

const NOMINATIM_BASE_URL = 'https://nominatim.openstreetmap.org';

export async function geocodeAddress(address: string): Promise<{ lat: number; lng: number } | null> {
  try {
    const response = await axios.get(`${NOMINATIM_BASE_URL}/search`, {
      params: {
        q: address,
        format: 'json',
        limit: 1,
      },
      headers: {
        'User-Agent': 'KelunDeliveryApp/1.0',
      },
    });

    if (response.data && response.data.length > 0) {
      return {
        lat: parseFloat(response.data[0].lat),
        lng: parseFloat(response.data[0].lon),
      };
    }
    return null;
  } catch (error) {
    console.error('[Nominatim] Geocoding error:', error);
    return null;
  }
}

export async function reverseGeocode(lat: number, lng: number): Promise<string | null> {
  try {
    const response = await axios.get(`${NOMINATIM_BASE_URL}/reverse`, {
      params: {
        lat,
        lon: lng,
        format: 'json',
      },
      headers: {
        'User-Agent': 'KelunDeliveryApp/1.0',
      },
    });

    if (response.data && response.data.display_name) {
      return response.data.display_name;
    }
    return null;
  } catch (error) {
    console.error('[Nominatim] Reverse geocoding error:', error);
    return null;
  }
}