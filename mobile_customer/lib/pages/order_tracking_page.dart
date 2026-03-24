import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class OrderTrackingPage extends StatefulWidget {
  final String customerName;
  final String customerAddress;
  final String paymentMethod;
  final String totalAmount;

  const OrderTrackingPage({
    super.key,
    required this.customerName,
    required this.customerAddress,
    required this.paymentMethod,
    required this.totalAmount,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // Simulated driver position (starts from warehouse, moves toward customer)
  double _driverLat = -6.2000;
  double _driverLng = 106.8400;
  String _driverStatus = 'Mengambil pesanan dari toko...';
  int _statusIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _statusSteps = [
    {'label': 'Pesanan dikonfirmasi', 'icon': Icons.check_circle, 'done': true},
    {'label': 'Pembayaran berhasil', 'icon': Icons.payment, 'done': true},
    {'label': 'Driver mengambil pesanan', 'icon': Icons.store, 'done': false},
    {'label': 'Dalam perjalanan', 'icon': Icons.delivery_dining, 'done': false},
    {'label': 'Pesanan tiba', 'icon': Icons.home, 'done': false},
  ];

  @override
  void initState() {
    super.initState();
    // Simulate driver movement
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        final rng = Random();
        _driverLat += (rng.nextDouble() - 0.3) * 0.002;
        _driverLng += (rng.nextDouble() - 0.3) * 0.002;

        if (timer.tick == 3) {
          _statusIndex = 2;
          _driverStatus = 'Driver sedang mengambil pesanan...';
          _statusSteps[2]['done'] = true;
        } else if (timer.tick == 6) {
          _statusIndex = 3;
          _driverStatus = 'Driver dalam perjalanan ke lokasi Anda';
          _statusSteps[3]['done'] = true;
        } else if (timer.tick >= 10) {
          _statusIndex = 4;
          _driverStatus = 'Pesanan telah tiba!';
          _statusSteps[4]['done'] = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Map Section =====
            Container(
              height: 300,
              color: Colors.white,
              child: Stack(
                children: [
                  // Map placeholder using a styled widget
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: const BoxDecoration(color: Color(0xFFE8F5E9)),
                    child: Stack(
                      children: [
                        // Grid lines to simulate map
                        CustomPaint(
                          size: const Size(double.infinity, 300),
                          painter: _MapGridPainter(),
                        ),

                        // Driver marker
                        Positioned(
                          left: ((_driverLng - 106.83) * 5000).clamp(20, 360),
                          top: ((_driverLat + 6.21) * 5000).clamp(20, 250),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '🛵 Driver',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF6C63FF),
                                size: 36,
                              ),
                            ],
                          ),
                        ),

                        // Customer marker (fixed)
                        Positioned(
                          right: 60,
                          bottom: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '📍 Tujuan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFE53935),
                                size: 36,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status overlay
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _statusIndex >= 4
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _driverStatus,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_statusIndex < 4)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Driver Info =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(
                      0xFF6C63FF,
                    ).withValues(alpha: 0.1),
                    child: const Text(
                      'B',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budi - Driver',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Honda Vario • B 1234 XYZ',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Call button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF00C853)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling driver...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat, color: Color(0xFF6C63FF)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat coming soon')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Order Status Timeline =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Pesanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_statusSteps.length, (index) {
                    final step = _statusSteps[index];
                    final isDone = step['done'] as bool;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(
                              step['icon'] as IconData,
                              size: 22,
                              color: isDone
                                  ? const Color(0xFF00C853)
                                  : Colors.grey[300],
                            ),
                            if (index < _statusSteps.length - 1)
                              Container(
                                width: 2,
                                height: 28,
                                color: isDone
                                    ? const Color(0xFF00C853)
                                    : Colors.grey[200],
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            step['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isDone
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDone ? Colors.black87 : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Order Details =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Penerima', widget.customerName),
                  _detailRow('Alamat', widget.customerAddress),
                  _detailRow('Pembayaran', widget.paymentMethod),
                  _detailRow('Total', widget.totalAmount),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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

// Custom painter for map grid background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8E6C9)
      ..strokeWidth = 0.5;

    // Draw grid lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "roads"
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 6;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
