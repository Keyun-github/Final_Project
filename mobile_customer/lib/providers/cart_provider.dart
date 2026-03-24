import 'package:flutter/material.dart';
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
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

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

  void addToCart(Product product, {String? selectedUnit, double? unitPrice}) {
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
    notifyListeners();
  }

  void removeFromCart(int productId, {String? selectedUnit}) {
    _items.removeWhere(
      (item) =>
          item.product.id == productId && item.selectedUnit == selectedUnit,
    );
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
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
