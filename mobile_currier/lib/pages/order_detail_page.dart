import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'delivery_map_page.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;
  final Function(String, OrderStatus) onStatusUpdate;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  OrderStatus? _nextStatus() {
    switch (order.status) {
      case OrderStatus.pending:
        return OrderStatus.pickingUp;
      case OrderStatus.pickingUp:
        return OrderStatus.pickedUp;
      case OrderStatus.pickedUp:
        return OrderStatus.delivering;
      case OrderStatus.delivering:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
        return null;
    }
  }

  String _nextLabel() {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Mulai Pickup';
      case OrderStatus.pickingUp:
        return 'Barang Diambil';
      case OrderStatus.pickedUp:
        return 'Mulai Antar';
      case OrderStatus.delivering:
        return 'Selesai Antar';
      case OrderStatus.delivered:
        return 'Selesai';
    }
  }

  IconData _nextIcon() {
    switch (order.status) {
      case OrderStatus.pending:
        return Icons.directions_walk;
      case OrderStatus.pickingUp:
        return Icons.inventory_2;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.delivering:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.done_all;
    }
  }

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return const Color(0xFFFFA726);
      case OrderStatus.pickingUp:
        return const Color(0xFF42A5F5);
      case OrderStatus.pickedUp:
        return const Color(0xFF7E57C2);
      case OrderStatus.delivering:
        return const Color(0xFF26A69A);
      case OrderStatus.delivered:
        return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final isDelivered = order.status == OrderStatus.delivered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (order.status == OrderStatus.delivering ||
              order.status == OrderStatus.pickingUp)
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Color(0xFF1565C0)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryMapPage(order: order),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    isDelivered ? Icons.check_circle : Icons.local_shipping,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    order.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.id,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer info
            _InfoCard(
              title: 'Informasi Pelanggan',
              icon: Icons.person,
              children: [
                _InfoRow(label: 'Nama', value: order.customerName),
                _InfoRow(label: 'Telepon', value: order.customerPhone),
              ],
            ),
            const SizedBox(height: 12),

            // Address info
            _InfoCard(
              title: 'Alamat',
              icon: Icons.location_on,
              children: [
                _AddressSection(
                  label: 'Pickup',
                  address: order.pickupAddress,
                  icon: Icons.store,
                  color: const Color(0xFF1565C0),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                _AddressSection(
                  label: 'Pengiriman',
                  address: order.deliveryAddress,
                  icon: Icons.location_on,
                  color: const Color(0xFFE53935),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item info
            _InfoCard(
              title: 'Detail Barang',
              icon: Icons.inventory_2,
              children: [
                _InfoRow(label: 'Barang', value: order.itemDescription),
                _InfoRow(label: 'Jumlah', value: '${order.itemCount} item'),
                _InfoRow(
                  label: 'Total',
                  value: order.formattedAmount,
                  valueStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status timeline
            _InfoCard(
              title: 'Status Pengiriman',
              icon: Icons.timeline,
              children: [
                _StatusStep(
                  label: 'Pesanan Diterima',
                  isDone: true,
                  isActive: order.status == OrderStatus.pending,
                ),
                _StatusStep(
                  label: 'Menuju Pickup',
                  isDone: order.status.index >= OrderStatus.pickingUp.index,
                  isActive: order.status == OrderStatus.pickingUp,
                ),
                _StatusStep(
                  label: 'Barang Diambil',
                  isDone: order.status.index >= OrderStatus.pickedUp.index,
                  isActive: order.status == OrderStatus.pickedUp,
                ),
                _StatusStep(
                  label: 'Dalam Perjalanan',
                  isDone: order.status.index >= OrderStatus.delivering.index,
                  isActive: order.status == OrderStatus.delivering,
                ),
                _StatusStep(
                  label: 'Terkirim',
                  isDone: order.status == OrderStatus.delivered,
                  isActive: order.status == OrderStatus.delivered,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom action
      bottomNavigationBar: !isDelivered
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (order.status == OrderStatus.delivering ||
                        order.status == OrderStatus.pickingUp)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeliveryMapPage(order: order),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map, size: 20),
                            label: const Text('Peta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1565C0),
                              side: const BorderSide(color: Color(0xFF1565C0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final next = _nextStatus();
                            if (next != null) {
                              onStatusUpdate(order.id, next);
                              Navigator.pop(context);
                            }
                          },
                          icon: Icon(_nextIcon(), size: 20),
                          label: Text(
                            _nextLabel(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// --- Info Card ---
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// --- Info Row ---
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  valueStyle ??
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Address Section ---
class _AddressSection extends StatelessWidget {
  final String label;
  final String address;
  final IconData icon;
  final Color color;

  const _AddressSection({
    required this.label,
    required this.address,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Status Step ---
class _StatusStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _StatusStep({
    required this.label,
    required this.isDone,
    required this.isActive,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFF1565C0)
                    : isActive
                    ? const Color(0xFF1565C0).withValues(alpha: 0.2)
                    : Colors.grey[200],
                border: isActive
                    ? Border.all(color: const Color(0xFF1565C0), width: 2)
                    : null,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? const Color(0xFF1565C0) : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDone || isActive
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isDone || isActive ? Colors.black87 : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }
}
