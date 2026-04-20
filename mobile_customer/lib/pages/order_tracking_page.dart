import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class OrderTrackingPage extends StatefulWidget {
  final String customerName;
  final String customerAddress;
  final String paymentMethod;
  final String totalAmount;
  final String? deliveryTime;
  final int? orderId;

  const OrderTrackingPage({
    super.key,
    required this.customerName,
    required this.customerAddress,
    required this.paymentMethod,
    required this.totalAmount,
    this.deliveryTime,
    this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  Timer? _refreshTimer;

  String get _currentStatusText {
    if (_orderData == null) return 'Menunggu driver menerima pesanan...';
    switch (_orderData!['status']) {
      case 'pending':
        return 'Menunggu driver menerima pesanan...';
      case 'pickingUp':
        return 'Driver menuju pickup...';
      case 'pickedUp':
        return 'Driver mengambil pesanan';
      case 'delivering':
        return 'Driver dalam perjalanan ke lokasi Anda';
      case 'delivered':
        return 'Pesanan telah tiba!';
      default:
        return 'Menunggu...';
    }
  }

  int get _currentStatusIndex {
    if (_orderData == null) return 0;
    switch (_orderData!['status']) {
      case 'pending':
        return 0;
      case 'pickingUp':
      case 'pickedUp':
        return 1;
      case 'delivering':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _startAutoRefresh();
  }

  Future<void> _loadOrderData() async {
    if (widget.orderId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await ApiService.fetchOrder(widget.orderId!);
      if (mounted) {
        setState(() {
          _orderData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadOrderData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text(
          'Lacak Pesanan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Status Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Color(0xFF6C63FF),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentStatusText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (_orderData != null &&
                                      _orderData!['driver'] != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6C63FF,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(
                                                  0xFF6C63FF,
                                                ),
                                                child: Text(
                                                  _orderData!['driver']['name']
                                                          ?.toString()
                                                          .substring(0, 1) ??
                                                      'D',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _orderData!['driver']['name'] ??
                                                          'Driver',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    if (_orderData!['driver']['phone'] !=
                                                            null &&
                                                        _orderData!['driver']['phone']
                                                            .toString()
                                                            .isNotEmpty)
                                                      Text(
                                                        '📱 ${_orderData!['driver']['phone']}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_orderData!['driver']['vehiclePlate'] !=
                                                  null &&
                                              _orderData!['driver']['vehiclePlate']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.directions_car,
                                                    size: 16,
                                                    color: Color(0xFF6C63FF),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${_orderData!['driver']['vehiclePlate']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (_orderData!['driver']['vehicleBrand'] !=
                                                          null &&
                                                      _orderData!['driver']['vehicleBrand']
                                                          .toString()
                                                          .isNotEmpty) ...[
                                                    const Text(' - '),
                                                    Text(
                                                      '${_orderData!['driver']['vehicleBrand']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                  if (_orderData!['driver']['vehicleColor'] !=
                                                          null &&
                                                      _orderData!['driver']['vehicleColor']
                                                          .toString()
                                                          .isNotEmpty) ...[
                                                    const Text(' - '),
                                                    Text(
                                                      '${_orderData!['driver']['vehicleColor']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Progress Steps
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Pengiriman',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StatusStep(
                          icon: Icons.check_circle,
                          label: 'Pesanan Dikonfirmasi',
                          isDone: true,
                          isActive: _currentStatusIndex >= 0,
                        ),
                        _StatusStep(
                          icon: Icons.store,
                          label: 'Driver Menuju Pickup',
                          isDone: _currentStatusIndex >= 1,
                          isActive: _currentStatusIndex >= 1,
                        ),
                        _StatusStep(
                          icon: Icons.local_shipping,
                          label: 'Dalam Perjalanan',
                          isDone: _currentStatusIndex >= 2,
                          isActive: _currentStatusIndex >= 2,
                        ),
                        _StatusStep(
                          icon: Icons.home,
                          label: 'Pesanan Tiba',
                          isDone: _currentStatusIndex >= 3,
                          isActive: _currentStatusIndex >= 3,
                        ),
                      ],
                    ),
                  ),

                  // Order Details
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Pelanggan',
                          value: widget.customerName,
                        ),
                        _DetailRow(
                          label: 'Alamat',
                          value: widget.customerAddress,
                        ),
                        _DetailRow(
                          label: 'Pembayaran',
                          value: widget.paymentMethod,
                        ),
                        _DetailRow(label: 'Total', value: widget.totalAmount),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF6C63FF)
                  : isActive
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDone
                  ? Colors.white
                  : isActive
                  ? const Color(0xFF6C63FF)
                  : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
