class OrderModel {
  final String id;
  final int? apiId;
  final int? driverId;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final String itemDescription;
  final int itemCount;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final double pickupLat;
  final double pickupLng;
  final double deliveryLat;
  final double deliveryLng;
  final String? deliveryPhoto;

  OrderModel({
    required this.id,
    this.apiId,
    this.driverId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.itemDescription,
    required this.itemCount,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.pickupLat = -6.2088,
    this.pickupLng = 106.8456,
    this.deliveryLat = -6.1944,
    this.deliveryLng = 106.8229,
    this.deliveryPhoto,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List? ?? [];
    final itemNames = items
        .map((i) => '${i['productName']} x${i['quantity']}')
        .join(', ');
    final itemCount = items.fold<int>(
      0,
      (sum, i) => sum + ((i['quantity'] ?? 1) as int),
    );

    return OrderModel(
      id:
          'ORD-${DateTime.tryParse(json['createdAt'] ?? '')?.toLocal().toString().substring(0, 10).replaceAll('-', '') ?? 'API'}-${String.fromCharCode(48 + (json['id'] as int? ?? 0) % 10)}${String.fromCharCode(48 + ((json['id'] as int? ?? 0) ~/ 10) % 10)}${json['id'] ?? 0}'
                  .length >
              3
          ? 'ORD-${json['id'].toString().padLeft(3, '0')}'
          : 'ORD-${json['id'] ?? 0}',
      apiId: json['id'],
      driverId: json['driverId'],
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      pickupAddress:
          json['pickupAddress'] ??
          'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
      deliveryAddress: json['deliveryAddress'] ?? '',
      itemDescription: itemNames.isNotEmpty ? itemNames : 'Order items',
      itemCount: itemCount > 0 ? itemCount : 1,
      totalAmount: (json['totalAmount'] is num)
          ? json['totalAmount'].toDouble()
          : double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0,
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      pickupLat: -6.1275,
      pickupLng: 106.8686,
      deliveryLat: -6.1944 + (json['id'] as int? ?? 0) * 0.01,
      deliveryLng: 106.8229 + (json['id'] as int? ?? 0) * 0.005,
      deliveryPhoto: json['deliveryPhoto'],
    );
  }

  String get formattedAmount {
    final formatted = totalAmount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.pickingUp:
        return 'Menuju Pickup';
      case OrderStatus.pickedUp:
        return 'Barang Diambil';
      case OrderStatus.delivering:
        return 'Dalam Perjalanan';
      case OrderStatus.delivered:
        return 'Terkirim';
    }
  }
}

enum OrderStatus {
  pending,
  pickingUp,
  pickedUp,
  delivering,
  delivered;

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'pickingUp':
        return OrderStatus.pickingUp;
      case 'pickedUp':
        return OrderStatus.pickedUp;
      case 'delivering':
        return OrderStatus.delivering;
      case 'delivered':
        return OrderStatus.delivered;
      default:
        return OrderStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.pickingUp:
        return 'pickingUp';
      case OrderStatus.pickedUp:
        return 'pickedUp';
      case OrderStatus.delivering:
        return 'delivering';
      case OrderStatus.delivered:
        return 'delivered';
    }
  }
}

List<OrderModel> demoOrders = [
  OrderModel(
    id: 'ORD-20260311-001',
    customerName: 'Budi Santoso',
    customerPhone: '081234567890',
    pickupAddress: 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
    deliveryAddress: 'Jl. Merdeka No. 42, Kelapa Gading, Jakarta Utara',
    itemDescription: 'Beras Premium 5kg (x2), Minyak Goreng 2L',
    itemCount: 3,
    totalAmount: 185000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    pickupLat: -6.1275,
    pickupLng: 106.8686,
    deliveryLat: -6.1577,
    deliveryLng: 106.9073,
  ),
  OrderModel(
    id: 'ORD-20260311-002',
    customerName: 'Siti Rahayu',
    customerPhone: '082198765432',
    pickupAddress: 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
    deliveryAddress: 'Jl. Kemang Raya No. 8, Jakarta Selatan',
    itemDescription: 'Telur Ayam 1 Box, Susu UHT 1 Box',
    itemCount: 2,
    totalAmount: 120000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    pickupLat: -6.1275,
    pickupLng: 106.8686,
    deliveryLat: -6.2615,
    deliveryLng: 106.8106,
  ),
  OrderModel(
    id: 'ORD-20260311-003',
    customerName: 'Agus Wijaya',
    customerPhone: '085678901234',
    pickupAddress: 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
    deliveryAddress: 'Jl. Sudirman No. 55, Jakarta Pusat',
    itemDescription: 'Gula Pasir 25kg (x1)',
    itemCount: 1,
    totalAmount: 325000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
    pickupLat: -6.1275,
    pickupLng: 106.8686,
    deliveryLat: -6.2088,
    deliveryLng: 106.8228,
  ),
  OrderModel(
    id: 'ORD-20260311-004',
    customerName: 'Dewi Lestari',
    customerPhone: '087812345678',
    pickupAddress: 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
    deliveryAddress: 'Jl. Cikini Raya No. 12, Jakarta Pusat',
    itemDescription: 'Tepung Terigu 50kg (x1), Kopi Bubuk 500g (x3)',
    itemCount: 4,
    totalAmount: 695000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    pickupLat: -6.1275,
    pickupLng: 106.8686,
    deliveryLat: -6.1890,
    deliveryLng: 106.8404,
  ),
  OrderModel(
    id: 'ORD-20260311-005',
    customerName: 'Riko Pratama',
    customerPhone: '089912345678',
    pickupAddress: 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
    deliveryAddress: 'Jl. Pluit Karang No. 7, Jakarta Utara',
    itemDescription: 'Sabun Cuci 5kg (x2), Minyak Goreng 5L (x1)',
    itemCount: 3,
    totalAmount: 142000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    pickupLat: -6.1275,
    pickupLng: 106.8686,
    deliveryLat: -6.1260,
    deliveryLng: 106.7969,
  ),
];
