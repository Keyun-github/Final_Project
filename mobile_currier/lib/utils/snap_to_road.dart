import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SnapToRoadService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  static Future<LatLng?> snapToRoad(LatLng position) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/match/v1/car/${position.longitude},${position.latitude}?overview=full&geometry_simplify=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['matchings'] != null && (data['matchings'] as List).isNotEmpty) {
          final matching = data['matchings'][0];

          if (matching['geometry'] != null) {
            final encoded = matching['geometry'];
            final snappedCoords = _decodePolyline(encoded);

            if (snappedCoords.isNotEmpty) {
              return snappedCoords.first;
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) == 1 ? -(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) == 1 ? -(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 100000.0, lng / 100000.0));
    }

    return points;
  }
}