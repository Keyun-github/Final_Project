import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/order_model.dart';

class DeliveryMapPage extends StatefulWidget {
  final OrderModel order;

  const DeliveryMapPage({super.key, required this.order});

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  late Timer _timer;
  double _progress = 0.0;
  int _estimatedMinutes = 25;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _progress = min(1.0, _progress + 0.02);
          _estimatedMinutes = max(1, (25 * (1 - _progress)).round());
        });
        if (_progress >= 1.0) _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPickingUp = widget.order.status == OrderStatus.pickingUp;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          isPickingUp ? 'Menuju Pickup' : 'Mengantar Pesanan',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Map Area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFE8F0FE),
              child: CustomPaint(
                painter: _MapPainter(
                  progress: _progress,
                  isPickingUp: isPickingUp,
                ),
                child: Stack(
                  children: [
                    // ETA chip
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ETA $_estimatedMinutes menit',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Progress bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 6,
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
                  ],
                ),
              ),
            ),
          ),

          // Details Panel
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destination info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPickingUp ? Icons.store : Icons.location_on,
                            color: const Color(0xFF1565C0),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPickingUp
                                    ? 'Lokasi Pickup'
                                    : 'Lokasi Pengiriman',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPickingUp
                                    ? widget.order.pickupAddress
                                    : widget.order.deliveryAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Customer info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              widget.order.customerName[0],
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  widget.order.customerPhone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Call button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF66BB6A,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Color(0xFF66BB6A),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Menghubungi ${widget.order.customerPhone}...',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Chat button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF42A5F5,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.chat,
                                color: Color(0xFF42A5F5),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Chat segera hadir'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order summary
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.itemDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          widget.order.formattedAmount,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Map Painter ---
class _MapPainter extends CustomPainter {
  final double progress;
  final bool isPickingUp;

  _MapPainter({required this.progress, required this.isPickingUp});

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
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Horizontal roads
    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.3), roadPaint);
    canvas.drawLine(Offset(0, h * 0.6), Offset(w, h * 0.6), roadPaint);

    // Vertical roads
    canvas.drawLine(Offset(w * 0.25, 0), Offset(w * 0.25, h), roadPaint);
    canvas.drawLine(Offset(w * 0.75, 0), Offset(w * 0.75, h), roadPaint);

    // Route points
    final startX = w * 0.2;
    final startY = h * 0.3;
    final endX = w * 0.8;
    final endY = h * 0.6;

    // Route line
    final routePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(startX, startY)
      ..lineTo(w * 0.25, startY)
      ..lineTo(w * 0.25, endY)
      ..lineTo(w * 0.75, endY)
      ..lineTo(endX, endY);

    canvas.drawPath(routePath, routePaint);

    // Completed portion
    final completedPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Calculate driver position along the route
    final segments = [
      [Offset(startX, startY), Offset(w * 0.25, startY)],
      [Offset(w * 0.25, startY), Offset(w * 0.25, endY)],
      [Offset(w * 0.25, endY), Offset(w * 0.75, endY)],
      [Offset(w * 0.75, endY), Offset(endX, endY)],
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

    // Start marker (pickup)
    canvas.drawCircle(
      Offset(startX, startY),
      12,
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawCircle(Offset(startX, startY), 6, Paint()..color = Colors.white);

    // End marker (delivery)
    canvas.drawCircle(
      Offset(endX, endY),
      12,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawCircle(Offset(endX, endY), 6, Paint()..color = Colors.white);

    // Driver marker
    canvas.drawCircle(
      driverPos,
      16,
      Paint()..color = const Color(0xFF1565C0).withValues(alpha: 0.2),
    );
    canvas.drawCircle(driverPos, 10, Paint()..color = const Color(0xFF1565C0));
    canvas.drawCircle(driverPos, 4, Paint()..color = Colors.white);

    // Labels
    final pickupLabel = TextPainter(
      text: TextSpan(
        text: isPickingUp ? ' Anda ' : ' Gudang ',
        style: const TextStyle(
          color: Color(0xFF1565C0),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pickupLabel.paint(
      canvas,
      Offset(startX - pickupLabel.width / 2, startY - 26),
    );

    final deliveryLabel = TextPainter(
      text: const TextSpan(
        text: ' Tujuan ',
        style: TextStyle(
          color: Color(0xFFE53935),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    deliveryLabel.paint(
      canvas,
      Offset(endX - deliveryLabel.width / 2, endY - 26),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.progress != progress;
}
