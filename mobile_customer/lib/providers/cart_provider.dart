import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final String? selectedUnit;
  final double? unitPrice;
  int quantity;

  CartItem({
    required this.product,
    this.selectedUnit,
    this.unitPrice,
    this.quantity = 1,
  });

  double get effectivePrice => unitPrice ?? product.price;
  double get total => effectivePrice * quantity;

  String get formattedEffectivePrice {
    final parts = <String>[];
    String priceStr = effectivePrice.toInt().toString();
    for (int i = priceStr.length; i > 0; i -= 3) {
      int start = (i - 3 < 0) ? 0 : i - 3;
      parts.insert(0, priceStr.substring(start, i));
    }
    return 'Rp ${parts.join('.')}';
  }

  Map<String, dynamic> toJson() => {
    'productId': product.id,
    'productName': product.name,
    'selectedUnit': selectedUnit,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? _currentCustomerId;

  String _getCartKey(int customerId) => 'cart_items_$customerId';

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.total);

  String get formattedTotal {
    final parts = <String>[];
    String priceStr = totalPrice.toInt().toString();
    for (int i = priceStr.length; i > 0; i -= 3) {
      int start = (i - 3 < 0) ? 0 : i - 3;
      parts.insert(0, priceStr.substring(start, i));
    }
    return 'Rp ${parts.join('.')}';
  }

  Future<void> loadCart(int customerId, List<Product> products) async {
    debugPrint(
      '[CartProvider] loadCart CALLED customerId=$customerId products.length=${products.length}',
    );
    
    // Don't reload if we already have items for this customer
    if (_currentCustomerId == customerId && _items.isNotEmpty) {
      debugPrint('[CartProvider] already loaded, skipping');
      return;
    }
    
    _currentCustomerId = customerId;
    final cartKey = _getCartKey(customerId);
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(cartKey);

    debugPrint('[CartProvider] key=$cartKey storage=$cartJson');

    // Load from storage - handle all cases properly
    if (cartJson != null && cartJson != '[]') {
      try {
        final List<dynamic> data = json.decode(cartJson);
        debugPrint('[CartProvider] parsed data length: ${data.length}');
        if (data.isEmpty) {
          _items.clear();
          notifyListeners();
          return;
        }
        _items.clear();
        for (final item in data) {
          final productId = item['productId'] as int;
          Product product;
          if (products.isEmpty) {
            // Create placeholder product from stored data
            product = Product(
              id: productId,
              name: item['productName'] ?? 'Unknown',
              description: '',
              price: (item['unitPrice'] ?? 0).toDouble(),
              imageUrl: '',
              category: '',
              stock: 999,
            );
          } else {
            product = products.firstWhere(
              (p) => p.id == productId,
              orElse: () => Product(
                id: productId,
                name: item['productName'] ?? 'Unknown',
                description: '',
                price: (item['unitPrice'] ?? 0).toDouble(),
                imageUrl: '',
                category: '',
                stock: 0,
              ),
            );
          }
          _items.add(
            CartItem(
              product: product,
              selectedUnit: item['selectedUnit'],
              unitPrice: item['unitPrice']?.toDouble(),
              quantity: item['quantity'] ?? 1,
            ),
          );
        }
        debugPrint('[CartProvider] loaded items: ${_items.length}');
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[CartProvider] error loading cart: $e');
        _items.clear();
        notifyListeners();
      }
    }

    // If no storage data or empty, clear cart
    _items.clear();
    notifyListeners();
  }

  Future<void> saveCart() async {
    // Always save - use 0 as guest key if not logged in
    final int customerId = _currentCustomerId ?? 0;
    final cartKey = _getCartKey(customerId);
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((item) => item.toJson()).toList();
    await prefs.setString(cartKey, json.encode(data));
    debugPrint('[CartProvider] SAVED to $cartKey: ${json.encode(data)}');
  }

  void addToCart(Product product, {String? selectedUnit, double? unitPrice}) {
    debugPrint(
      '[CartProvider] addToCart product=${product.id} customerId=$_currentCustomerId',
    );
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id && item.selectedUnit == selectedUnit,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          product: product,
          selectedUnit: selectedUnit,
          unitPrice: unitPrice,
        ),
      );
    }
    saveCart();
    notifyListeners();
  }

  void removeFromCart(int productId, {String? selectedUnit}) {
    _items.removeWhere(
      (item) =>
          item.product.id == productId && item.selectedUnit == selectedUnit,
    );
    saveCart();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity, {String? selectedUnit}) {
    final index = _items.indexWhere(
      (item) =>
          item.product.id == productId && item.selectedUnit == selectedUnit,
    );
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    // Only clear in-memory - for logout
    debugPrint('[CartProvider] clearCart (in-memory only) called');
    _items.clear();
    notifyListeners();
  }
  
  void clearCartAndSave() {
    // Clear in-memory AND save empty to storage - for "Hapus Semua"
    debugPrint('[CartProvider] clearCartAndSave called');
    _items.clear();
    _saveCartDirect();
    notifyListeners();
  }
  
  void _saveCartDirect() {
    if (_currentCustomerId != null) {
      final cartKey = _getCartKey(_currentCustomerId!);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(cartKey, '[]');
      });
    }
  }

  Future<void> clearCartAndStorage() async {
    if (_currentCustomerId != null) {
      final cartKey = _getCartKey(_currentCustomerId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cartKey);
      debugPrint('[CartProvider] REMOVED storage: $cartKey');
    }
    _items.clear();
    _currentCustomerId = null;
    notifyListeners();
  }

  Future<void> clearCartStorage() async {
    if (_currentCustomerId == null) return;
    final cartKey = _getCartKey(_currentCustomerId!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cartKey, '[]');
    _items.clear();
    _currentCustomerId = null;
    notifyListeners();
  }

  Future<void> clearCartForCustomer(int customerId) async {
    final cartKey = _getCartKey(customerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cartKey, '[]');
    if (_currentCustomerId == customerId) {
      _items.clear();
      _currentCustomerId = null;
      notifyListeners();
    }
  }
}
