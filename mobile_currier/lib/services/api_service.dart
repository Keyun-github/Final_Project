import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  // ===== Orders =====
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
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
    final response = await http.get(
      Uri.parse('$baseUrl/orders/driver/$driverId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
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
    final response = await http.get(Uri.parse('$baseUrl/orders/unassigned'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchPendingOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders/pending'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
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
}
