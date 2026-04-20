import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'order_detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String driverName;
  final int driverId;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.driverName,
    required this.driverId,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<OrderModel> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final assignedData = await ApiService.fetchOrdersByDriver(
        widget.driverId,
      );
      final pendingData = await ApiService.fetchPendingOrders();
      if (mounted) {
        final allOrders = [
          ...assignedData.map((json) => OrderModel.fromJson(json)),
          ...pendingData.map((json) => OrderModel.fromJson(json)),
        ];
        setState(() {
          orders = allOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          orders = [];
          _isLoading = false;
        });
      }
    }
  }

  void _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    // Find the order to get apiId
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) {
      debugPrint('[_updateOrderStatus] Order not found: $orderId');
      return;
    }

    final old = orders[idx];

    debugPrint('[_updateOrderStatus] ========== START ==========');
    debugPrint('[_updateOrderStatus] Order local ID: $orderId');
    debugPrint('[_updateOrderStatus] Order API ID: ${old.apiId}');
    debugPrint('[_updateOrderStatus] Current status: ${old.status}');
    debugPrint('[_updateOrderStatus] New status: $newStatus');
    debugPrint('[_updateOrderStatus] API value: ${newStatus.apiValue}');

    // Then update via API first to check if it works
    if (old.apiId != null) {
      try {
        // Use acceptOrder when transitioning from pending to pickingUp (driver accepts the order)
        if (old.status == OrderStatus.pending &&
            newStatus == OrderStatus.pickingUp) {
          await ApiService.acceptOrder(old.apiId!, widget.driverId);
          debugPrint('[_updateOrderStatus] acceptOrder successful');
        } else {
          debugPrint('[_updateOrderStatus] Calling updateOrderStatus...');
          final result = await ApiService.updateOrderStatus(
            old.apiId!,
            newStatus.apiValue,
          );
          debugPrint('[_updateOrderStatus] updateOrderStatus result: $result');
        }

        // Only update local state after API succeeds
        if (mounted) {
          setState(() {
            orders[idx] = OrderModel(
              id: old.id,
              apiId: old.apiId,
              customerName: old.customerName,
              customerPhone: old.customerPhone,
              pickupAddress: old.pickupAddress,
              deliveryAddress: old.deliveryAddress,
              itemDescription: old.itemDescription,
              itemCount: old.itemCount,
              totalAmount: old.totalAmount,
              status: newStatus,
              createdAt: old.createdAt,
              pickupLat: old.pickupLat,
              pickupLng: old.pickupLng,
              deliveryLat: old.deliveryLat,
              deliveryLng: old.deliveryLng,
              deliveryPhoto: old.deliveryPhoto,
            );
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == OrderStatus.delivered
                    ? 'Pesanan berhasil dikunci! 📦'
                    : 'Status pesanan diperbarui',
              ),
              backgroundColor: const Color(0xFF66BB6A),
              duration: const Duration(seconds: 2),
            ),
          );

          // Refresh the orders list to ensure UI reflects latest status
          _loadOrders();
        }
      } catch (e) {
        debugPrint('[_updateOrderStatus] FAILED: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui status: $e'),
              backgroundColor: const Color(0xFFE53935),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // No apiId - update locally only
      setState(() {
        orders[idx] = OrderModel(
          id: old.id,
          apiId: old.apiId,
          customerName: old.customerName,
          customerPhone: old.customerPhone,
          pickupAddress: old.pickupAddress,
          deliveryAddress: old.deliveryAddress,
          itemDescription: old.itemDescription,
          itemCount: old.itemCount,
          totalAmount: old.totalAmount,
          status: newStatus,
          createdAt: old.createdAt,
          pickupLat: old.pickupLat,
          pickupLng: old.pickupLng,
          deliveryLat: old.deliveryLat,
          deliveryLng: old.deliveryLng,
          deliveryPhoto: old.deliveryPhoto,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _OrdersTab(
              driverName: widget.driverName,
              orders: orders,
              onStatusUpdate: _updateOrderStatus,
            )
          : ProfilePage(
              driverName: widget.driverName,
              driverId: widget.driverId,
              totalDelivered: orders
                  .where((o) => o.status == OrderStatus.delivered)
                  .length,
              totalOrders: orders.length,
              completedOrders: orders
                  .where((o) => o.status == OrderStatus.delivered)
                  .toList(),
              onLogout: widget.onLogout,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 65,
        indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Color(0xFF1565C0)),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1565C0)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final String driverName;
  final List<OrderModel> orders;
  final Function(String, OrderStatus) onStatusUpdate;

  const _OrdersTab({
    required this.driverName,
    required this.orders,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final activeOrders = orders
        .where((o) => o.status != OrderStatus.delivered)
        .toList();
    final pendingCount = orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final inProgressCount = orders
        .where(
          (o) =>
              o.status == OrderStatus.pickingUp ||
              o.status == OrderStatus.pickedUp ||
              o.status == OrderStatus.delivering,
        )
        .length;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 170,
          pinned: true,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              driverName.isNotEmpty ? driverName[0] : 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, $driverName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Siap mengantar hari ini?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E676),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Status summary cards
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.hourglass_empty,
                            label: 'Menunggu',
                            value: '$pendingCount',
                            color: const Color(0xFFFFA726),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.local_shipping,
                            label: 'Aktif',
                            value: '$inProgressCount',
                            color: const Color(0xFF42A5F5),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.check_circle,
                            label: 'Selesai',
                            value:
                                '${orders.where((o) => o.status == OrderStatus.delivered).length}',
                            color: const Color(0xFF66BB6A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Active Orders
        if (activeOrders.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Pesanan Aktif (${activeOrders.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _OrderCard(
                  order: activeOrders[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(
                          order: activeOrders[i],
                          onStatusUpdate: onStatusUpdate,
                        ),
                      ),
                    );
                  },
                ),
                childCount: activeOrders.length,
              ),
            ),
          ),
        ],

        // Empty state
        if (orders.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }
}

// --- Stat Chip Widget ---
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Order Card Widget ---
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final bool isCompleted;

  const _OrderCard({
    required this.order,
    required this.onTap,
    this.isCompleted = false,
  });

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

  IconData _statusIcon() {
    switch (order.status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.pickingUp:
        return Icons.directions_walk;
      case OrderStatus.pickedUp:
        return Icons.inventory_2;
      case OrderStatus.delivering:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.grey[200]! : Colors.grey[100]!,
          ),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_statusIcon(), color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Delivery info
            _AddressRow(
              icon: Icons.store,
              color: const Color(0xFF1565C0),
              text: order.pickupAddress,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            _AddressRow(
              icon: Icons.location_on,
              color: const Color(0xFFE53935),
              text: order.deliveryAddress,
              maxLines: 1,
            ),
            const SizedBox(height: 12),

            // Items and amount
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.itemCount} item',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                Text(
                  order.formattedAmount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final int maxLines;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.text,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
