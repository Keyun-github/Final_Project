import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/nominatim_service.dart';
import '../services/websocket_service.dart';
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
  Timer? _locationTimer;
  Position? _currentPosition;
  bool _showMapView = false;
  StreamSubscription? _orderUpdateSubscription;
  Timer? _orderPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _initLocationTracking();

    _orderPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      debugPrint('[_HomePage] Polling refresh orders...');
      _loadOrders();
    });

    _orderUpdateSubscription = WebSocketService.instance.orderUpdates.listen((data) {
      debugPrint('[_HomePage] New order event received, refreshing orders...');
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _orderPollingTimer?.cancel();
    _orderUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[_initLocationTracking] Location services disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[_initLocationTracking] Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        '[_initLocationTracking] Location permission permanently denied',
      );
      return;
    }

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendLocationUpdate();
    });

    WebSocketService.instance.connect(widget.driverId);
    _sendLocationUpdate();
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = position;

      final wsSuccess = await WebSocketService.instance.sendLocationUpdate(
        driverId: widget.driverId,
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!wsSuccess) {
        await ApiService.updateDriverLocation(
          driverId: widget.driverId,
          lat: position.latitude,
          lng: position.longitude,
        );
      }

      debugPrint(
        '[HomePage] Location updated: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('[HomePage] Failed to get/send location: $e');
    }
  }

  Future<void> _loadOrders() async {
    debugPrint(
      '[HomePage] _loadOrders called for driverId: ${widget.driverId}',
    );
    try {
      final assignedData = await ApiService.fetchOrdersByDriver(
        widget.driverId,
      );
      debugPrint(
        '[HomePage] fetchOrdersByDriver returned ${assignedData.length} orders',
      );
      final pendingData = await ApiService.fetchPendingOrders();
      debugPrint(
        '[HomePage] fetchPendingOrders returned ${pendingData.length} orders',
      );
      if (mounted) {
        final allOrders = [
          ...assignedData.map((json) => OrderModel.fromJson(json)),
          ...pendingData.map((json) => OrderModel.fromJson(json)),
        ];
        debugPrint('[HomePage] Total orders to display: ${allOrders.length}');
        for (final order in allOrders) {
          debugPrint(
            '[HomePage] Order: ${order.id}, status: ${order.status}, apiId: ${order.apiId}',
          );
        }
        setState(() {
          orders = allOrders;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[HomePage] _loadOrders error: $e');
      debugPrint('[HomePage] Stack trace: $stack');
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
          ? _buildOrdersView()
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

  Widget _buildOrdersView() {
    return Stack(
      children: [
        _showMapView
            ? _MapViewTab(
                orders: orders
                    .where((o) => o.status != OrderStatus.delivered)
                    .toList(),
                onOrderTap: (order) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(
                        order: order,
                        onStatusUpdate: _updateOrderStatus,
                      ),
                    ),
                  );
                },
              )
            : _OrdersTab(
                driverName: widget.driverName,
                orders: orders,
                onStatusUpdate: _updateOrderStatus,
                onMapToggle: () => setState(() => _showMapView = true),
              ),
        // Floating map toggle button (only in list view)
        if (!_showMapView)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'map_toggle',
              backgroundColor: const Color(0xFF1565C0),
              onPressed: () => setState(() => _showMapView = true),
              child: const Icon(Icons.map, color: Colors.white),
            ),
          ),
        // Floating list toggle button (only in map view)
        if (_showMapView)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'list_toggle',
              backgroundColor: const Color(0xFF1565C0),
              onPressed: () => setState(() => _showMapView = false),
              child: const Icon(Icons.list, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final String driverName;
  final List<OrderModel> orders;
  final Function(String, OrderStatus) onStatusUpdate;
  final VoidCallback onMapToggle;

  const _OrdersTab({
    required this.driverName,
    required this.orders,
    required this.onStatusUpdate,
    required this.onMapToggle,
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
                  isCompleted: false,
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

// --- Map View Tab ---
class _MapViewTab extends StatefulWidget {
  final List<OrderModel> orders;
  final Function(OrderModel) onOrderTap;

  const _MapViewTab({required this.orders, required this.onOrderTap});

  @override
  State<_MapViewTab> createState() => _MapViewTabState();
}

class _MapViewTabState extends State<_MapViewTab> {
  final MapController _mapController = MapController();
  double? _driverLat;
  double? _driverLng;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initDriverLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDriverLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _driverLat = position.latitude;
          _driverLng = position.longitude;
        });
        _fitBounds();
      }
    } catch (e) {
      debugPrint('[_MapViewTab] Failed to get location: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (mounted) {
          setState(() {
            _driverLat = position.latitude;
            _driverLng = position.longitude;
          });
        }
      } catch (e) {
        debugPrint('[_MapViewTab] Location update failed: $e');
      }
    });
  }

  void _fitBounds() {
    final points = <LatLng>[];
    points.add(LatLng(NominatimService.STORE_LAT, NominatimService.STORE_LNG));
    for (final order in widget.orders) {
      if (order.deliveryLat != 0 && order.deliveryLng != 0) {
        points.add(LatLng(order.deliveryLat, order.deliveryLng));
      }
    }
    if (_driverLat != null && _driverLng != null) {
      points.add(LatLng(_driverLat!, _driverLng!));
    }
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
      );
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
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

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
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

  List<Marker> get _markers {
    final List<Marker> markers = [];

    markers.add(
      Marker(
        point: LatLng(NominatimService.STORE_LAT, NominatimService.STORE_LNG),
        width: 50,
        height: 60,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TOKO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.warehouse, color: Color(0xFF1565C0), size: 30),
          ],
        ),
      ),
    );

    for (final order in widget.orders) {
      if (order.deliveryLat != 0 && order.deliveryLng != 0) {
        final color = _statusColor(order.status);
        markers.add(
          Marker(
            point: LatLng(order.deliveryLat, order.deliveryLng),
            width: 50,
            height: 70,
            child: GestureDetector(
              onTap: () => widget.onOrderTap(order),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(_statusIcon(order.status), color: color, size: 28),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (_driverLat != null && _driverLng != null) {
      markers.add(
        Marker(
          point: LatLng(_driverLat!, _driverLng!),
          width: 50,
          height: 60,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SAYA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.local_shipping,
                color: Color(0xFF43A047),
                size: 30,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    NominatimService.STORE_LAT,
                    NominatimService.STORE_LNG,
                  ),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kelun.currier',
                  ),
                  MarkerLayer(markers: _markers),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
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
                        Icons.warehouse,
                        size: 16,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.orders.length} pesanan aktif',
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
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'fit_bounds',
                  backgroundColor: Colors.white,
                  onPressed: _fitBounds,
                  child: const Icon(Icons.fit_screen, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.orders.length,
              itemBuilder: (ctx, i) {
                final order = widget.orders[i];
                return GestureDetector(
                  onTap: () => widget.onOrderTap(order),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              order.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _statusIcon(order.status),
                            color: _statusColor(order.status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                order.deliveryAddress,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              order.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.statusLabel,
                            style: TextStyle(
                              color: _statusColor(order.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
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

  const _OrderCard({required this.order, required this.onTap, required this.isCompleted});

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
