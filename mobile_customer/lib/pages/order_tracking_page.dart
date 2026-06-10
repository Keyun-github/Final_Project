import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/nominatim_service.dart';
import '../services/socket_service.dart';
import 'chat/chat_room_page.dart';

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
  final NominatimService _nominatimService = NominatimService();
  final MapController _mapController = MapController();
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _routeUpdateSubscription;

  double? _driverLat;
  double? _driverLng;
  double? _customerLat;
  double? _customerLng;
  bool _isGeocoding = false;
  String? _routeToStore;
  String? _routeToDestination;
  List<LatLng> _decodedStoreRoute = [];
  List<LatLng> _decodedDestRoute = [];

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
    _initWebSocket();
  }

  void _initWebSocket() {
    SocketService.instance.connect();

    _driverLocationSubscription = SocketService.instance.driverLocationUpdates.listen((data) {
      if (mounted && data['driverId'] != null) {
        setState(() {
          _driverLat = (data['lat'] as num?)?.toDouble();
          _driverLng = (data['lng'] as num?)?.toDouble();
        });
        // Fallback: still fetch routes via REST in case the WebSocket route_update
        // event isn't being received (e.g. older backend). The WebSocket path
        // below updates polyline directly and is preferred.
        _fetchRoutes();
      }
    });

    // Preferred path: server pushes a fresh polyline with every location update,
    // so we don't need to make an extra REST call.
    _routeUpdateSubscription = SocketService.instance.routeUpdates.listen((data) {
      if (!mounted) return;
      if (widget.orderId != null && data['orderId'] != null && data['orderId'] != widget.orderId) {
        return; // Not for this order
      }
      debugPrint('[OrderTracking] route_update received: status=${data['status']}');
      setState(() {
        // Update driver position with the server-snapped coords if available.
        if (data['snappedDriverLat'] != null && data['snappedDriverLng'] != null) {
          _driverLat = (data['snappedDriverLat'] as num).toDouble();
          _driverLng = (data['snappedDriverLng'] as num).toDouble();
        } else if (data['driverLat'] != null && data['driverLng'] != null) {
          _driverLat = (data['driverLat'] as num).toDouble();
          _driverLng = (data['driverLng'] as num).toDouble();
        }

        // Update polylines from the broadcast.
        final newRouteToStore = data['routeToStore'] as String?;
        final newRouteToDest = data['routeToDestination'] as String?;
        if (newRouteToStore != null && newRouteToStore.isNotEmpty) {
          _routeToStore = newRouteToStore;
          _decodedStoreRoute = _decodePolyline(newRouteToStore);
        } else {
          _routeToStore = null;
          _decodedStoreRoute = [];
        }
        if (newRouteToDest != null && newRouteToDest.isNotEmpty) {
          _routeToDestination = newRouteToDest;
          _decodedDestRoute = _decodePolyline(newRouteToDest);
        } else {
          _routeToDestination = null;
          _decodedDestRoute = [];
        }
      });
    });

    if (widget.orderId != null) {
      SocketService.instance.subscribeToOrder(widget.orderId!);
    }
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
          _updateDriverLocation();
        });
        _geocodeCustomerAddress();
        _fetchRoutes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRoutes() async {
    if (widget.orderId == null) {
      return;
    }
    final routes = await ApiService.fetchOrderRoutes(widget.orderId!);
    if (mounted) {
      setState(() {
        _routeToStore = routes['routeToStore'];
        _routeToDestination = routes['routeToDestination'];
        if (_routeToStore != null && _routeToStore!.isNotEmpty) {
          _decodedStoreRoute = _decodePolyline(_routeToStore!);
        } else {
          _decodedStoreRoute = [];
        }
        if (_routeToDestination != null && _routeToDestination!.isNotEmpty) {
          _decodedDestRoute = _decodePolyline(_routeToDestination!);
        } else {
          _decodedDestRoute = [];
        }
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    var index = 0;
    var lat = 0;
    var lng = 0;
    while (index < encoded.length) {
      int b;
      var shift = 0;
      var result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _updateDriverLocation() {
    if (_orderData != null && _orderData!['driver'] != null) {
      final driver = _orderData!['driver'];
      if (driver['currentLat'] != null && driver['currentLng'] != null) {
        setState(() {
          _driverLat = double.tryParse(driver['currentLat'].toString());
          _driverLng = double.tryParse(driver['currentLng'].toString());
        });
      }
    }
  }

  Future<void> _geocodeCustomerAddress() async {
    if (_isGeocoding || _customerLat != null) return;
    if (widget.customerAddress.isEmpty) return;

    setState(() => _isGeocoding = true);

    final results = await _nominatimService.searchAddress(widget.customerAddress);
    if (mounted && results.isNotEmpty) {
      setState(() {
        _customerLat = results.first.lat;
        _customerLng = results.first.lon;
        _isGeocoding = false;
      });
    } else {
      setState(() => _isGeocoding = false);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadOrderData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _driverLocationSubscription?.cancel();
    _routeUpdateSubscription?.cancel();
    if (widget.orderId != null) {
      SocketService.instance.unsubscribeFromOrder(widget.orderId!);
    }
    SocketService.instance.disconnect();
    super.dispose();
  }

  LatLng? get _mapCenter {
    if (_driverLat != null && _driverLng != null) {
      return LatLng(_driverLat!, _driverLng!);
    }
    if (_customerLat != null && _customerLng != null) {
      return LatLng(_customerLat!, _customerLng!);
    }
    return const LatLng(-6.2088, 106.8456);
  }

  List<Marker> get _markers {
    final List<Marker> markers = [];

    if (_customerLat != null && _customerLng != null) {
      markers.add(
        Marker(
          point: LatLng(_customerLat!, _customerLng!),
          width: 50,
          height: 50,
          child: const Column(
            children: [
              Icon(
                Icons.location_on,
                color: Color(0xFFE53935),
                size: 40,
              ),
              Text(
                'Anda',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_driverLat != null && _driverLng != null) {
      markers.add(
        Marker(
          point: LatLng(_driverLat!, _driverLng!),
          width: 50,
          height: 50,
          child: const Column(
            children: [
              Icon(
                Icons.local_shipping,
                color: Color(0xFF1565C0),
                size: 40,
              ),
              Text(
                'Driver',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final List<Polyline> lines = [];
    final status = _orderData?['status'] as String?;

    if (status == 'pickingUp' && _decodedStoreRoute.isNotEmpty) {
      if (_driverLat != null && _driverLng != null) {
        final split = _splitRouteAtDriver(
          _decodedStoreRoute,
          LatLng(_driverLat!, _driverLng!),
        );
        if (split['traveled']!.isNotEmpty) {
          lines.add(Polyline(
            points: split['traveled']!,
            color: const Color(0xFF43A047),
            strokeWidth: 5,
          ));
        }
        if (split['remaining']!.isNotEmpty) {
          lines.add(Polyline(
            points: split['remaining']!,
            color: const Color(0xFF1565C0),
            strokeWidth: 5,
          ));
        }
      } else {
        // No driver position yet — show full route in single color.
        lines.add(Polyline(
          points: _decodedStoreRoute,
          color: const Color(0xFF1565C0),
          strokeWidth: 5,
        ));
      }
    } else if ((status == 'pickedUp' || status == 'delivering') &&
        _decodedDestRoute.isNotEmpty) {
      if (_driverLat != null && _driverLng != null) {
        final split = _splitRouteAtDriver(
          _decodedDestRoute,
          LatLng(_driverLat!, _driverLng!),
        );
        if (split['traveled']!.isNotEmpty) {
          lines.add(Polyline(
            points: split['traveled']!,
            color: const Color(0xFF43A047),
            strokeWidth: 5,
          ));
        }
        if (split['remaining']!.isNotEmpty) {
          lines.add(Polyline(
            points: split['remaining']!,
            color: const Color(0xFFE53935),
            strokeWidth: 5,
          ));
        }
      } else {
        lines.add(Polyline(
          points: _decodedDestRoute,
          color: const Color(0xFFE53935),
          strokeWidth: 5,
        ));
      }
    }

    return lines;
  }

  /// Splits [route] into the segment the driver has already traveled and the
  /// segment still ahead, based on which point on the route is closest to
  /// [driverPos].
  Map<String, List<LatLng>> _splitRouteAtDriver(
    List<LatLng> route,
    LatLng driverPos,
  ) {
    double minDist = double.infinity;
    int closestIdx = 0;
    for (int i = 0; i < route.length; i++) {
      final d = _distance(route[i], driverPos);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }

    final traveled = route.sublist(0, closestIdx + 1);
    final remaining = route.sublist(closestIdx);

    return {'traveled': traveled, 'remaining': remaining};
  }

  double _distance(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
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
        actions: [
          if (widget.orderId != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () async {
                final customerId = _orderData?['customerId'] as int?;
                final driverId = _orderData?['driver']?['id'];
                debugPrint('[Chat] orderData keys: ${_orderData?.keys.toList()}');
                debugPrint('[Chat] driver: ${_orderData?['driver']}');
                if (customerId == null) {
                  debugPrint('[Chat] customerId is null, cannot open chat');
                  return;
                }
                if (driverId == null) {
                  debugPrint('[Chat] driverId is null, cannot open chat');
                  return;
                }

                try {
                  final response = await ApiService.post('/chat/order/${widget.orderId}', {
                    'customerId': customerId,
                    'driverId': driverId,
                  });

                  debugPrint('[Chat] Response: $response');

                  if (mounted && response != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          conversationId: response['id'],
                          orderId: widget.orderId!,
                          customerId: customerId,
                          driverId: driverId,
                          userType: 'customer',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('[Chat] Error: $e');
                }
              },
            ),
        ],
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
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
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
                                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(0xFF6C63FF),
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
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _orderData!['driver']['name'] ?? 'Driver',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    if (_orderData!['driver']['phone'] != null &&
                                                        _orderData!['driver']['phone']
                                                            .toString()
                                                            .isNotEmpty)
                                                      Text(
                                                        '📱 ${_orderData!['driver']['phone']}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_orderData!['driver']['vehiclePlate'] != null &&
                                              _orderData!['driver']['vehiclePlate']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
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
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (_orderData!['driver']['vehicleBrand'] != null &&
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

                  // Map Card
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_orderData != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Status: ${_orderData!['status']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              FlutterMap(
                                key: ValueKey('map_${_decodedDestRoute.length}_${_decodedStoreRoute.length}'),
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _mapCenter ?? const LatLng(-6.2088, 106.8456),
                                  initialZoom: 14,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.kelun.app',
                                  ),
                                  MarkerLayer(markers: _markers),
                                  PolylineLayer(polylines: _buildPolylines()),
                                ],
                              ),
                              if (_isGeocoding)
                                const Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Memuat lokasi...'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_driverLat != null)
                                        Text(
                                          'Driver: ${_driverLat!.toStringAsFixed(4)}, ${_driverLng!.toStringAsFixed(4)}',
                                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                        )
                                      else
                                        const Text(
                                          'Driver: -',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      if (_customerLat != null)
                                        Text(
                                          'Anda: ${_customerLat!.toStringAsFixed(4)}, ${_customerLng!.toStringAsFixed(4)}',
                                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                        )
                                      else
                                        const Text(
                                          'Anda: -',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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