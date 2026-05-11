import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

                  // Map Placeholder (only show when delivering)
                  if (_orderData != null)
                    Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'DEBUG: status="${_orderData!['status']}"',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _MapPlaceholder(
                            onMapTap: () {},
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

// --- Map Placeholder Widget ---
class _MapPlaceholder extends StatefulWidget {
  final VoidCallback? onMapTap;

  const _MapPlaceholder({this.onMapTap});

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  double _progress = 0.3;
  int _estimatedMinutes = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + 0.02).clamp(0.0, 1.0);
        _estimatedMinutes = max(1, (25 * (1 - _progress)).round());
      });
      if (_progress >= 1.0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onMapTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              CustomPaint(
                painter: _CustomerMapPainter(progress: _progress),
                size: Size.infinite,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ETA $_estimatedMinutes menit',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 5,
                  color: Colors.grey[200],
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 12,
                right: 12,
                child: Text(
                  'Peta sedang dalam pengembangan',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Map Painter for Customer Side ---
class _CustomerMapPainter extends CustomPainter {
  final double progress;

  _CustomerMapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFE8F0FE),
    );

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFD0D8E8)
      ..strokeWidth = 0.5;

    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, h * 0.35), Offset(w, h * 0.35), roadPaint);
    canvas.drawLine(Offset(0, h * 0.65), Offset(w, h * 0.65), roadPaint);
    canvas.drawLine(Offset(w * 0.3, 0), Offset(w * 0.3, h), roadPaint);
    canvas.drawLine(Offset(w * 0.7, 0), Offset(w * 0.7, h), roadPaint);

    // Route points
    final startX = w * 0.2;
    final startY = h * 0.35;
    final endX = w * 0.8;
    final endY = h * 0.65;

    // Route line (pending portion - gray)
    final routePaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(startX, startY)
      ..lineTo(w * 0.3, startY)
      ..lineTo(w * 0.3, endY)
      ..lineTo(w * 0.7, endY)
      ..lineTo(endX, endY);

    canvas.drawPath(routePath, routePaint);

    // Completed portion (blue)
    final completedPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Calculate driver position
    final segments = [
      [Offset(startX, startY), Offset(w * 0.3, startY)],
      [Offset(w * 0.3, startY), Offset(w * 0.3, endY)],
      [Offset(w * 0.3, endY), Offset(w * 0.7, endY)],
      [Offset(w * 0.7, endY), Offset(endX, endY)],
    ];

    double totalLen = 0;
    final segLens = <double>[];
    for (final seg in segments) {
      final len = (seg[1] - seg[0]).distance;
      segLens.add(len);
      totalLen += len;
    }

    final targetDist = progress * totalLen;
    double accumulated = 0;
    Offset driverPos = Offset(startX, startY);

    for (int i = 0; i < segments.length; i++) {
      if (accumulated + segLens[i] >= targetDist) {
        final remain = targetDist - accumulated;
        final t = remain / segLens[i];
        driverPos = Offset.lerp(segments[i][0], segments[i][1], t)!;
        break;
      }
      accumulated += segLens[i];
      if (i == segments.length - 1) driverPos = segments[i][1];
    }

    // Draw completed route
    final completedPath = Path()..moveTo(startX, startY);
    accumulated = 0;
    for (int i = 0; i < segments.length; i++) {
      if (accumulated + segLens[i] >= targetDist) {
        final remain = targetDist - accumulated;
        final t = remain / segLens[i];
        final pt = Offset.lerp(segments[i][0], segments[i][1], t)!;
        completedPath.lineTo(pt.dx, pt.dy);
        break;
      }
      completedPath.lineTo(segments[i][1].dx, segments[i][1].dy);
      accumulated += segLens[i];
    }
    canvas.drawPath(completedPath, completedPaint);

    // Driver marker (start point - blue)
    canvas.drawCircle(
      Offset(startX, startY),
      10,
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawCircle(Offset(startX, startY), 5, Paint()..color = Colors.white);

    // Customer marker (end point - red)
    canvas.drawCircle(
      Offset(endX, endY),
      10,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawCircle(Offset(endX, endY), 5, Paint()..color = Colors.white);

    // Driver moving marker
    canvas.drawCircle(
      driverPos,
      14,
      Paint()..color = const Color(0xFF1565C0).withValues(alpha: 0.2),
    );
    canvas.drawCircle(driverPos, 8, Paint()..color = const Color(0xFF1565C0));
    canvas.drawCircle(driverPos, 3, Paint()..color = Colors.white);

    // Labels
    final driverLabel = TextPainter(
      text: const TextSpan(
        text: ' Driver ',
        style: TextStyle(
          color: Color(0xFF1565C0),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    driverLabel.paint(canvas, Offset(startX - driverLabel.width / 2, startY - 24));

    final customerLabel = TextPainter(
      text: const TextSpan(
        text: ' Anda ',
        style: TextStyle(
          color: Color(0xFFE53935),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    customerLabel.paint(canvas, Offset(endX - customerLabel.width / 2, endY - 24));
  }

  @override
  bool shouldRepaint(covariant _CustomerMapPainter old) =>
      old.progress != progress;
}