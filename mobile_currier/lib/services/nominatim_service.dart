import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimPlace {
  final String displayName;
  final double lat;
  final double lon;
  final String placeId;

  NominatimPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.placeId,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    return NominatimPlace(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'] ?? '0') ?? 0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0,
      placeId: json['place_id']?.toString() ?? '',
    );
  }
}

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'KelunApp/1.0';

  static const String STORE_ADDRESS = 'Jl. Kedung Rukem IV / 55';
  static const double STORE_LAT = -7.2628478;
  static const double STORE_LNG = 112.7336368;

  Future<List<NominatimPlace>> searchAddress(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'countrycodes': 'id',
        'addressdetails': '1',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => NominatimPlace.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Nominatim search error: $e');
    }

    return [];
  }

  Future<NominatimPlace?> geocodeAddress(String address) async {
    final results = await searchAddress(address, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
}