import 'dart:convert';
import 'package:http/http.dart' as http;

class StockException implements Exception {
  final String message;
  StockException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // For local development:
  // - Android emulator: use 10.0.2.2 to reach host's localhost
  // - iOS simulator: use localhost
  // - Physical device: Replace with your computer's local IP address (e.g., 192.168.1.x)
  // IMPORTANT: Make sure the backend is running and accessible from your device
  static const String baseUrl = 'http://localhost:3000';

  static bool _isUsingDemoData = false;
  static bool get isUsingDemoData => _isUsingDemoData;

  // ===== Customers =====
  static Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String username,
    required String phone,
    required String password,
    String address = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'username': username,
        'phone': phone,
        'password': password,
        'address': address,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    final errorBody = json.decode(response.body);
    throw Exception(errorBody['message'] ?? 'Registrasi gagal');
  }

  static Future<Map<String, dynamic>> loginCustomer({
    required String usernameOrPhone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'usernameOrPhone': usernameOrPhone,
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Username/nomor telepon atau password salah');
  }

  static Future<bool> updateCustomerAddress({
    required int customerId,
    required String address,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$customerId/address'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'address': address}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getCustomerById(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchCustomerOrders(
    int customerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/customer/$customerId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ===== Products =====
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final url = '$baseUrl/products';
      print('[ApiService] Fetching products from: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Connection timeout - backend may not be running',
              );
            },
          );
      if (response.statusCode == 200) {
        _isUsingDemoData = false;
        final List<dynamic> data = json.decode(response.body);
        print('[ApiService] Loaded ${data.length} products from API');
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load products: ${response.statusCode}');
    } catch (e) {
      print('[ApiService] Error fetching products: $e');
      _isUsingDemoData = true;
      rethrow;
    }
  }

  // ===== Orders =====
  static Future<Map<String, dynamic>> createOrder({
    int? customerId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'items': items,
    };

    if (customerId != null) {
      body['customerId'] = customerId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }

    // Handle stock error (400 or 500)
    if (response.statusCode == 400 || response.statusCode == 500) {
      final errorBody = json.decode(response.body);
      final message = errorBody['message'] ?? 'Stok tidak cukup';
      throw StockException(message);
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

  // ===== Time Slots =====
  static Future<List<Map<String, dynamic>>> fetchTimeSlots(String date) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/time-slots?date=$date'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load time slots');
    } catch (e) {
      print('[ApiService] Error fetching time slots: $e');
      // Return demo time slots if API fails
      return _generateDemoTimeSlots();
    }
  }

  static Future<bool> bookTimeSlot(String date, String time) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/time-slots/book'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'date': date, 'time': time}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('[ApiService] Error booking time slot: $e');
      // Return true in demo mode
      return true;
    }
  }

  static List<Map<String, dynamic>> _generateDemoTimeSlots() {
    final slots = <Map<String, dynamic>>[];
    for (int hour = 8; hour < 16; hour++) {
      slots.add({
        'time': '${hour.toString().padLeft(2, '0')}:00',
        'available': true,
        'bookings': 0,
        'maxBookings': 3,
      });
      slots.add({
        'time': '${hour.toString().padLeft(2, '0')}:30',
        'available': true,
        'bookings': 0,
        'maxBookings': 3,
      });
    }
    slots.add({
      'time': '16:00',
      'available': true,
      'bookings': 0,
      'maxBookings': 3,
    });
    slots.add({
      'time': '16:30',
      'available': true,
      'bookings': 0,
      'maxBookings': 3,
    });
    return slots;
  }
}
