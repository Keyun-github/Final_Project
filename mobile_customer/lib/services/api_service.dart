import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Web: use localhost directly (browser handles it).
  // Android emulator: use 10.0.2.2 to reach host's localhost.
  // iOS simulator / macOS / physical device: use localhost.
  // For a physical device on a different network, replace with your machine's IP.
  static const String baseUrl = 'http://localhost:3000';

  // ===== Products =====
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final url = '$baseUrl/products';
    print('[ApiService] Fetching products from: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('[ApiService] Loaded ${data.length} products from API');
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load products: ${response.statusCode}');
  }

  // ===== Orders =====
  static Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'items': items,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create order: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>?> fetchOrder(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
