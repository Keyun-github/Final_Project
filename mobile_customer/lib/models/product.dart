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
final List<Product> demoProducts = [
  const Product(
    id: 1,
    name: 'Gula Pasir Premium',
    description:
        'Gula pasir putih kualitas premium, cocok untuk kebutuhan masakan dan minuman sehari-hari.',
    price: 15000,
    imageUrl: 'https://picsum.photos/seed/sugar/400/400',
    category: 'Food & Drinks',
    rating: 4.8,
    sold: 21500,
    seller: 'Distributor Sembako',
    sellerCity: 'Jakarta',
    variants: [
      ProductVariant(unitName: 'KG', price: 15000),
      ProductVariant(unitName: 'Sack 25KG', price: 360000),
      ProductVariant(unitName: 'Sack 50KG', price: 710000),
    ],
  ),
  const Product(
    id: 2,
    name: 'Kopi Kapal Api Special',
    description:
        'Kopi bubuk instan dengan aroma yang khas dan nikmat, sangat cocok menemani pagi hari Anda.',
    price: 3500,
    imageUrl: 'https://picsum.photos/seed/coffee_packet/400/400',
    category: 'Food & Drinks',
    rating: 4.9,
    sold: 15420,
    seller: 'Kopi Nusantara',
    sellerCity: 'Surabaya',
    variants: [
      ProductVariant(unitName: 'Piece', price: 3500),
      ProductVariant(unitName: 'Box', price: 82000),
    ],
  ),
  const Product(
    id: 3,
    name: 'Wireless Bluetooth Earbuds Pro',
    description:
        'Premium wireless earbuds with active noise cancellation, 30-hour battery life, and IPX5 water resistance. Perfect for music lovers and gym enthusiasts.',
    price: 299000,
    imageUrl: 'https://picsum.photos/seed/earbuds/400/400',
    category: 'Electronics',
    rating: 4.8,
    sold: 1250,
    seller: 'TechStore Official',
    sellerCity: 'Jakarta',
  ),
  const Product(
    id: 4,
    name: 'Kaos Polos Katun Premium',
    description:
        'Kaos polos bahan katun combed 30s yang adem dan nyaman dipakai sehari-hari. Tersedia dalam berbagai warna.',
    price: 89000,
    imageUrl: 'https://picsum.photos/seed/tshirt/400/400',
    category: 'Fashion',
    rating: 4.6,
    sold: 5420,
    seller: 'Fashion House',
    sellerCity: 'Bandung',
  ),
  const Product(
    id: 5,
    name: 'Sepatu Running Ultralight',
    description:
        'Sepatu olahraga ultralight dengan sol empuk untuk kenyamanan maksimal saat berlari. Bahan mesh breathable.',
    price: 459000,
    imageUrl: 'https://picsum.photos/seed/shoes/400/400',
    category: 'Fashion',
    rating: 4.7,
    sold: 890,
    seller: 'Sport Zone',
    sellerCity: 'Surabaya',
  ),
  const Product(
    id: 6,
    name: 'Tas Ransel Anti Air 30L',
    description:
        'Tas ransel kapasitas 30L dengan bahan anti air, cocok untuk sekolah, kuliah, atau travelling. Dilengkapi slot laptop 15 inch.',
    price: 175000,
    imageUrl: 'https://picsum.photos/seed/backpack/400/400',
    category: 'Fashion',
    rating: 4.5,
    sold: 3200,
    seller: 'Bag Corner',
    sellerCity: 'Yogyakarta',
  ),
  const Product(
    id: 7,
    name: 'Skincare Set Brightening',
    description:
        'Paket lengkap skincare untuk mencerahkan wajah: facial wash, toner, serum, moisturizer, dan sunscreen SPF50.',
    price: 249000,
    imageUrl: 'https://picsum.photos/seed/skincare/400/400',
    category: 'Health & Beauty',
    rating: 4.9,
    sold: 7800,
    seller: 'Beauty Official',
    sellerCity: 'Jakarta',
  ),
  const Product(
    id: 8,
    name: 'Mie Instan Premium Box (40 pcs)',
    description:
        'Mie instan premium dengan bumbu spesial. Tersedia rasa: Ayam Bawang, Soto, Kari Ayam, Goreng Spesial.',
    price: 120000,
    imageUrl: 'https://picsum.photos/seed/noodles/400/400',
    category: 'Food & Drinks',
    rating: 4.4,
    sold: 15000,
    seller: 'Grocery Mart',
    sellerCity: 'Semarang',
  ),
  const Product(
    id: 9,
    name: 'Mechanical Keyboard RGB',
    description:
        'Keyboard mekanikal dengan switch Cherry MX, backlight RGB, dan keycap PBT doubleshot. Koneksi USB-C detachable.',
    price: 550000,
    imageUrl: 'https://picsum.photos/seed/keyboard/400/400',
    category: 'Electronics',
    rating: 4.7,
    sold: 620,
    seller: 'TechStore Official',
    sellerCity: 'Jakarta',
  ),
  const Product(
    id: 10,
    name: 'Tumbler Stainless 750ml',
    description:
        'Tumbler premium bahan stainless steel, tahan panas/dingin hingga 12 jam. BPA-free dan food grade.',
    price: 135000,
    imageUrl: 'https://picsum.photos/seed/tumbler/400/400',
    category: 'Home & Living',
    rating: 4.6,
    sold: 2100,
    seller: 'Home Essentials',
    sellerCity: 'Bandung',
  ),
  const Product(
    id: 11,
    name: 'Phone Case Premium Leather',
    description:
        'Case HP bahan kulit premium dengan slot kartu. Cocok untuk iPhone dan Android flagship.',
    price: 99000,
    imageUrl: 'https://picsum.photos/seed/phonecase/400/400',
    category: 'Electronics',
    rating: 4.3,
    sold: 4500,
    seller: 'Gadget World',
    sellerCity: 'Jakarta',
  ),
  const Product(
    id: 12,
    name: 'Vitamin C 1000mg (30 Tablet)',
    description:
        'Suplemen vitamin C dosis tinggi untuk daya tahan tubuh. Aman dikonsumsi setiap hari.',
    price: 65000,
    imageUrl: 'https://picsum.photos/seed/vitamin/400/400',
    category: 'Health & Beauty',
    rating: 4.8,
    sold: 9200,
    seller: 'Health Plus',
    sellerCity: 'Surabaya',
  ),
  const Product(
    id: 13,
    name: 'Lampu LED Desk Lamp USB',
    description:
        'Lampu meja LED dengan pengaturan kecerahan 3 level. Port USB charging, hemat energi dan tahan lama.',
    price: 85000,
    imageUrl: 'https://picsum.photos/seed/desklamp/400/400',
    category: 'Home & Living',
    rating: 4.5,
    sold: 1800,
    seller: 'Home Essentials',
    sellerCity: 'Bandung',
  ),
  const Product(
    id: 14,
    name: 'Kopi Arabica Specialty 250g',
    description:
        'Biji kopi arabica specialty grade dari Toraja. Roast level: medium. Cupping score 85+.',
    price: 95000,
    imageUrl: 'https://picsum.photos/seed/coffee/400/400',
    category: 'Food & Drinks',
    rating: 4.9,
    sold: 6300,
    seller: 'Coffee Lab',
    sellerCity: 'Makassar',
  ),
];

final List<String> categories = [
  'All',
  'Electronics',
  'Fashion',
  'Health & Beauty',
  'Food & Drinks',
  'Home & Living',
];
