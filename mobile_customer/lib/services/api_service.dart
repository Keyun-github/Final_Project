import 'dart:convert';
import 'package:http/http.dart' as http;

class StockException implements Exception {
  final String message;
  StockException(this.message);

  @override
  String toString() => message;
}

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
    String? deliveryDate,
    String? deliveryTime,
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

    if (deliveryDate != null) {
      body['deliveryDate'] = deliveryDate;
    }

    if (deliveryTime != null) {
      body['deliveryTime'] = deliveryTime;
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
      return {'routeToStore': null, 'routeToDestination': null};
    }
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
      // Non-201 status means booking failed
      return false;
    } catch (e) {
      print('[ApiService] Error booking time slot: $e');
      // Return false on error - don't allow order to proceed
      return false;
    }
  }

  static Future<bool> releaseTimeSlot(String date, String time) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/time-slots/release'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'date': date, 'time': time}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('[ApiService] Error releasing time slot: $e');
      return false;
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

  // ===== Midtrans Payment =====
  static Future<Map<String, dynamic>> getSnapToken({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    print('[ApiService] getSnapToken called: orderId=$orderId, amount=$amount');

    final response = await http.post(
      Uri.parse('$baseUrl/payment/snap-token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'orderId': orderId,
        'amount': amount,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
      }),
    );

    print('[ApiService] getSnapToken response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    throw Exception('Failed to get snap token: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>?> checkPaymentStatus(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('[ApiService] checkPaymentStatus error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> confirmPayment(int? orderId) async {
    try {
      if (orderId == null) return null;

      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/confirm-payment'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[ApiService] confirmPayment response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      // Surface the server's error message (e.g. "Pembayaran belum selesai")
      // so the UI can show it instead of silently failing.
      String message = 'Konfirmasi pembayaran gagal (${response.statusCode})';
      try {
        final body = json.decode(response.body);
        if (body is Map && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {
        // Keep the default message if the body isn't valid JSON.
      }
      throw Exception(message);
    } catch (e) {
      print('[ApiService] confirmPayment error: $e');
      rethrow;
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
      print('[ApiService] POST error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[ApiService] GET error: $e');
      return [];
    }
  }

  // ===== Units of Measure =====
  static Future<List<Map<String, dynamic>>> fetchUnits() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/units'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load units: ${response.statusCode}');
    } catch (e) {
      print('[ApiService] Error fetching units: $e');
      // Fallback to the five default units so the UI never breaks.
      return const [
        {'id': -1, 'name': 'KG', 'isDefault': true, 'isActive': true},
        {'id': -2, 'name': 'Box', 'isDefault': true, 'isActive': true},
        {
          'id': -3,
          'name': 'Sack - 25kg',
          'isDefault': true,
          'isActive': true
        },
        {
          'id': -4,
          'name': 'Sack - 50kg',
          'isDefault': true,
          'isActive': true
        },
        {'id': -5, 'name': 'Piece', 'isDefault': true, 'isActive': true},
      ];
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
      print('[ApiService] fetchStoreConfig error: $e');
      return {
        'address': 'Jl. Kedung Rukem IV / 55',
        'lat': -7.2628478,
        'lng': 112.7336368,
      };
    }
  }
}
