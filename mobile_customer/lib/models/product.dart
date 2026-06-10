class ProductVariant {
  final String unitName;
  final double price;

  const ProductVariant({required this.unitName, required this.price});

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      unitName: json['unitName'] ?? '',
      price: (json['price'] is num)
          ? json['price'].toDouble()
          : double.tryParse(json['price'].toString()) ?? 0,
    );
  }

  String get formattedPrice {
    final parts = <String>[];
    String priceStr = price.toInt().toString();
    for (int i = priceStr.length; i > 0; i -= 3) {
      int start = (i - 3 < 0) ? 0 : i - 3;
      parts.insert(0, priceStr.substring(start, i));
    }
    return 'Rp ${parts.join('.')}';
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int sold;
  final String seller;
  final String sellerCity;
  final int stock;
  final List<ProductVariant>? variants;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.5,
    this.sold = 0,
    this.seller = 'Official Store',
    this.sellerCity = 'Jakarta',
    this.stock = 0,
    this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final seller = json['seller']?.toString() ?? '';
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num)
          ? json['price'].toDouble()
          : double.tryParse(json['price']?.toString() ?? '') ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] is num)
          ? json['rating'].toDouble()
          : double.tryParse(json['rating']?.toString() ?? '') ?? 4.5,
      sold: json['sold'] ?? 0,
      seller: seller.isEmpty ? 'Official Store' : seller,
      sellerCity: json['sellerCity']?.toString() ?? 'Jakarta',
      stock: json['stock'] ?? 0,
      variants: json['variants'] != null
          ? (json['variants'] as List)
                .map((v) => ProductVariant.fromJson(v))
                .toList()
          : null,
    );
  }

  bool get hasVariants => variants != null && variants!.isNotEmpty;

  String get formattedPrice {
    final parts = <String>[];
    String priceStr = price.toInt().toString();
    for (int i = priceStr.length; i > 0; i -= 3) {
      int start = (i - 3 < 0) ? 0 : i - 3;
      parts.insert(0, priceStr.substring(start, i));
    }
    return 'Rp ${parts.join('.')}';
  }
}

// Demo product catalog data
// Intentionally left empty - products are now managed by admin via backend.
// This list is only used as a fallback when the backend API is unreachable.
// Once the API comes back online, the customer app will fetch real products.
final List<Product> demoProducts = <Product>[];


final List<String> categories = [
  'All',
  'Electronics',
  'Fashion',
  'Health & Beauty',
  'Food & Drinks',
  'Home & Living',
];
