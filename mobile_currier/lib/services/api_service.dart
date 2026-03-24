import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Android emulator, use 10.0.2.2 to reach host's localhost.
  // For iOS simulator or physical device on same network, use your machine's IP.
  static const String baseUrl = 'http://10.0.2.2:3000';

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
      int orderId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update order status: ${response.statusCode}');
  }
}
