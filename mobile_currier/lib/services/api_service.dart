import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Backend base URL is baked into the binary at build time via
  //   --dart-define=API_URL=https://api-kelun.ngelantour.cloud
  // For local development, pass --dart-define=API_URL=http://10.0.2.2:3000
  // (Android emulator) or http://localhost:3000 (iOS simulator).
  static const String _envBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api-kelun.ngelantour.cloud',
  );
  static String get baseUrl => _envBaseUrl;

  // ===== Orders =====
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[ApiService] fetchOrders error: status=${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] fetchOrders error: $e');
    }
    throw Exception('Failed to load orders');
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    debugPrint(
      '[ApiService] updateOrderStatus called: orderId=$orderId, status=$status',
    );
    debugPrint('[ApiService] URL: $baseUrl/orders/$orderId/status');

    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );

    debugPrint('[ApiService] Response status: ${response.statusCode}');
    debugPrint('[ApiService] Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    debugPrint('[ApiService] updateOrderStatus error: status=${response.statusCode}, body=${response.body}');
    throw Exception('Failed to update order status: ${response.statusCode}');
  }

  // ===== Driver =====
  static Future<Map<String, dynamic>?> getDriver(int driverId) async {
    final response = await http.get(Uri.parse('$baseUrl/drivers/$driverId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  static Future<bool> updatePassword({
    required int driverId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/$driverId/password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> updateVehicle({
    required int driverId,
    required String vehicleBrand,
    required String vehiclePlate,
    required String vehicleColor,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/$driverId/vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'vehicleBrand': vehicleBrand,
        'vehiclePlate': vehiclePlate,
        'vehicleColor': vehicleColor,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchOrdersByDriver(
    int driverId,
  ) async {
    try {
      final url = '$baseUrl/orders/driver/$driverId';
      debugPrint('[ApiService] fetchOrdersByDriver URL: $url');
      final response = await http.get(Uri.parse(url));
      debugPrint('[ApiService] fetchOrdersByDriver status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('[ApiService] fetchOrdersByDriver data length: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[ApiService] fetchOrdersByDriver error: status=${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] fetchOrdersByDriver error: $e');
    }
    throw Exception('Failed to load orders');
  }

  static Future<Map<String, dynamic>> assignDriverToOrder(
    int orderId,
    int driverId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/assign'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'driverId': driverId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to assign driver: ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchUnassignedOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/unassigned'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[ApiService] fetchUnassignedOrders error: status=${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] fetchUnassignedOrders error: $e');
    }
    throw Exception('Failed to load orders');
  }

  static Future<List<Map<String, dynamic>>> fetchPendingOrders() async {
    try {
      final url = '$baseUrl/orders/pending';
      debugPrint('[ApiService] fetchPendingOrders URL: $url');
      final response = await http.get(Uri.parse(url));
      debugPrint('[ApiService] fetchPendingOrders status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('[ApiService] fetchPendingOrders data length: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[ApiService] fetchPendingOrders error: status=${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] fetchPendingOrders error: $e');
    }
    throw Exception('Failed to load orders');
  }

  static Future<Map<String, dynamic>?> acceptOrder(
    int orderId,
    int driverId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'driverId': driverId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadDeliveryPhoto(
    int orderId,
    String photoPath,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$orderId/photo');
      final request = http.MultipartRequest('POST', uri);

      final fileBytes = await http.MultipartFile.fromPath('photo', photoPath);
      request.files.add(fileBytes);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // New method to save Supabase URL to backend
  static Future<bool> saveDeliveryPhotoUrl(int orderId, String photoUrl) async {
    try {
      debugPrint('[ApiService] saveDeliveryPhotoUrl called: orderId=$orderId, photoUrl=$photoUrl');

      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/photo-url'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'photoUrl': photoUrl}),
      );

      debugPrint('[ApiService] saveDeliveryPhotoUrl response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] saveDeliveryPhotoUrl error: $e');
      return false;
    }
  }

  static Future<bool> updateDriverLocation({
    required int driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      debugPrint('[ApiService] updateDriverLocation: driverId=$driverId, lat=$lat, lng=$lng');

      final response = await http.put(
        Uri.parse('$baseUrl/drivers/$driverId/location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'lat': lat, 'lng': lng}),
      );

      debugPrint('[ApiService] updateDriverLocation response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateDriverLocation error: $e');
      return false;
    }
  }

  static Future<Map<String, String?>> fetchOrderRoutes(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/routes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'routeToStore': data['routeToStore'] as String?,
          'routeToDestination': data['routeToDestination'] as String?,
        };
      }
      return {'routeToStore': null, 'routeToDestination': null};
    } catch (e) {
      debugPrint('[ApiService] fetchOrderRoutes error: $e');
      return {'routeToStore': null, 'routeToDestination': null};
    }
  }

  static Future<Map<String, dynamic>?> updateDeliveryCoords(
    int orderId,
    double lat,
    double lng,
    String status, {
    double? snappedLat,
    double? snappedLng,
  }) async {
    try {
      debugPrint('[ApiService] updateDeliveryCoords: orderId=$orderId, lat=$lat, lng=$lng, status=$status, snappedLat=$snappedLat, snappedLng=$snappedLng');

      final body = {
        'lat': lat,
        'lng': lng,
        'status': status,
      };

      if (snappedLat != null && snappedLng != null) {
        body['snappedLat'] = snappedLat;
        body['snappedLng'] = snappedLng;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/delivery-coords'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      debugPrint('[ApiService] updateDeliveryCoords response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] updateDeliveryCoords error: $e');
      return null;
    }
  }

  // ===== Chat =====
  static Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] POST error: $e');
      return null;
    }
  }

  Future<List<dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] GET error: $e');
      return [];
    }
  }

  // ===== Store Config =====
  /// Fetches the singleton store config (address + lat + lng) from the
  /// backend. Falls back to the legacy hardcoded values when the API is
  /// unreachable so the UI never breaks.
  static Future<Map<String, dynamic>> fetchStoreConfig() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/store-config'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to load store config: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('[ApiService] fetchStoreConfig error: $e');
      return {
        'address': 'Jl. Kedung Rukem IV / 55',
        'lat': -7.2628478,
        'lng': 112.7336368,
      };
    }
  }
}
