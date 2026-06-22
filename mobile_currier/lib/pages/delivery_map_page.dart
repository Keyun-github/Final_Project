import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';
import '../services/nominatim_service.dart';
import '../services/api_service.dart';
import '../services/store_config_cache.dart';
import '../services/websocket_service.dart';
import '../utils/snap_to_road.dart';
import 'chat/chat_room_page.dart';

class DeliveryMapPage extends StatefulWidget {
  final OrderModel order;

  const DeliveryMapPage({super.key, required this.order});

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  final MapController _mapController = MapController();
  final NominatimService _nominatimService = NominatimService();

  double? _driverLat;
  double? _driverLng;
  double? _snappedDriverLat;
  double? _snappedDriverLng;
  double? _pickupLat;
  double? _pickupLng;
  double? _deliveryLat;
  double? _deliveryLng;

  bool _isLoadingLocation = true;
  bool _isCalculatingRoute = false;
  int _estimatedMinutes = 25;
  Timer? _locationTimer;
  String? _routeToStore;
  String? _routeToDestination;
  List<LatLng> _decodedStoreRoute = [];
  List<LatLng> _decodedDestRoute = [];
  StreamSubscription? _routeUpdateSubscription;
  String _storeAddress = NominatimService.STORE_ADDRESS;

  static const LatLng STORE_LOCATION = LatLng(
    NominatimService.STORE_LAT,
    NominatimService.STORE_LNG,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _startLocationUpdates();
    _listenForRouteUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _routeUpdateSubscription?.cancel();
    super.dispose();
  }

  void _listenForRouteUpdates() {
    _routeUpdateSubscription = WebSocketService.instance.routeUpdates.listen((data) {
      if (data['orderId'] == widget.order.apiId) {
        debugPrint('[DeliveryMapPage] Received route_update via WebSocket');
        setState(() {
          final newRouteToStore = data['routeToStore'] as String?;
          final newRouteToDest = data['routeToDestination'] as String?;

          if (newRouteToStore != null && newRouteToStore.isNotEmpty) {
            _routeToStore = newRouteToStore;
            _decodedStoreRoute = _decodePolyline(newRouteToStore);
          }
          if (newRouteToDest != null && newRouteToDest.isNotEmpty) {
            _routeToDestination = newRouteToDest;
            _decodedDestRoute = _decodePolyline(newRouteToDest);
          }
        });
      }
    });
  }

  Future<void> _initializeLocations() async {
    debugPrint('[DeliveryMapPage] _initializeLocations called');
    debugPrint(
      '[DeliveryMapPage] order status: ${widget.order.status}, deliveryAddress: ${widget.order.deliveryAddress}',
    );

    // Set pickup location (store) — fetched from backend, with legacy
    // hard-coded values as the fallback if the API is unreachable.
    final store = await StoreConfigCache.instance.get();
    _pickupLat = (store['lat'] as num?)?.toDouble() ?? NominatimService.STORE_LAT;
    _pickupLng = (store['lng'] as num?)?.toDouble() ?? NominatimService.STORE_LNG;
    _storeAddress = (store['address'] as String?) ?? NominatimService.STORE_ADDRESS;
    debugPrint('[DeliveryMapPage] Store location: $_pickupLat, $_pickupLng');
    debugPrint('[DeliveryMapPage] Store address: $_storeAddress');

    // Use delivery coordinates from order (backend geocodes them)
    // Sentinel value 0.0 means "not geocoded"
    if (widget.order.deliveryLat != 0.0 && widget.order.deliveryLng != 0.0) {
      debugPrint(
        '[DeliveryMapPage] Using backend geocoded coordinates: ${widget.order.deliveryLat}, ${widget.order.deliveryLng}',
      );
      _deliveryLat = widget.order.deliveryLat;
      _deliveryLng = widget.order.deliveryLng;

      // Fetch routes with existing coordinates
      if (widget.order.apiId != null) {
        debugPrint(
          '[DeliveryMapPage] Fetching routes for orderId: ${widget.order.apiId}',
        );
        final routes = await ApiService.fetchOrderRoutes(widget.order.apiId!);
        debugPrint(
          '[DeliveryMapPage] Routes fetched - routeToStore: ${routes['routeToStore'] != null}, routeToDestination: ${routes['routeToDestination'] != null}',
        );
        if (mounted) {
          setState(() {
            _routeToStore = routes['routeToStore'];
            _routeToDestination = routes['routeToDestination'];
            if (_routeToStore != null) {
              _decodedStoreRoute = _decodePolyline(_routeToStore!);
              debugPrint(
                '[DeliveryMapPage] Decoded store route: ${_decodedStoreRoute.length} points',
              );
              debugPrint(
                '[DeliveryMapPage] First decoded point: lat=${_decodedStoreRoute.first.latitude}, lng=${_decodedStoreRoute.first.longitude}',
              );
              debugPrint(
                '[DeliveryMapPage] Expected range: lat ~-7.26, lng ~112.73',
              );
            }
            if (_routeToDestination != null) {
              _decodedDestRoute = _decodePolyline(_routeToDestination!);
              debugPrint(
                '[DeliveryMapPage] Decoded destination route: ${_decodedDestRoute.length} points',
              );
              debugPrint(
                '[DeliveryMapPage] First decoded dest point: lat=${_decodedDestRoute.first.latitude}, lng=${_decodedDestRoute.first.longitude}',
              );
            }
          });
        }
      }
    } else {
      debugPrint(
        '[DeliveryMapPage] No valid coordinates from backend (sentinel 0.0), geocoding locally...',
      );
      final deliveryPlace = await _nominatimService.geocodeAddress(
        widget.order.deliveryAddress,
      );
      debugPrint(
        '[DeliveryMapPage] Geocode result: lat=$deliveryPlace?.lat, lon=$deliveryPlace?.lon',
      );

      if (mounted && deliveryPlace != null) {
        _deliveryLat = deliveryPlace.lat;
        _deliveryLng = deliveryPlace.lon;

        // Update backend with geocoded coordinates AND recalculate routes
        if (widget.order.apiId != null) {
          debugPrint(
            '[DeliveryMapPage] Updating backend with geocoded coordinates...',
          );
          final updateResult = await ApiService.updateDeliveryCoords(
            widget.order.apiId!,
            _deliveryLat!,
            _deliveryLng!,
            widget.order.status.apiValue,
          );

          if (updateResult != null && mounted) {
            debugPrint(
              '[DeliveryMapPage] Backend updated with coordinates and routes',
            );
            final routes = updateResult['routes'] as Map<String, dynamic>?;
            if (routes != null) {
              setState(() {
                _routeToStore = routes['routeToStore'] as String?;
                _routeToDestination = routes['routeToDestination'] as String?;
                if (_routeToStore != null) {
                  _decodedStoreRoute = _decodePolyline(_routeToStore!);
                  debugPrint(
                    '[DeliveryMapPage] Decoded store route: ${_decodedStoreRoute.length} points',
                  );
                }
                if (_routeToDestination != null) {
                  _decodedDestRoute = _decodePolyline(_routeToDestination!);
                  debugPrint(
                    '[DeliveryMapPage] Decoded destination route: ${_decodedDestRoute.length} points',
                  );
                }
              });
            }
          }
        }
      }
    }

    // Get current driver location
    await _updateDriverLocation();

    setState(() => _isLoadingLocation = false);

    // Center map between driver and destination
    _centerMap();
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      // Google polyline zigzag decoding for latitude
      final dlat = (result & 1) == 1 ? -(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      // Google polyline zigzag decoding for longitude
      final dlng = (result & 1) == 1 ? -(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 100000.0, lng / 100000.0));
    }

    return points;
  }

  Future<void> _updateDriverLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      debugPrint(
        '[DeliveryMapPage] Location update: ${position.latitude}, ${position.longitude}',
      );

      // Snap to road for accurate routing
      final actualPosition = LatLng(position.latitude, position.longitude);
      final snappedPosition = await SnapToRoadService.snapToRoad(actualPosition);

      if (mounted) {
        setState(() {
          _driverLat = position.latitude;
          _driverLng = position.longitude;
          if (snappedPosition != null) {
            _snappedDriverLat = snappedPosition.latitude;
            _snappedDriverLng = snappedPosition.longitude;
            debugPrint(
              '[DeliveryMapPage] Snapped to road: $_snappedDriverLat, $_snappedDriverLng',
            );
          } else {
            _snappedDriverLat = position.latitude;
            _snappedDriverLng = position.longitude;
          }
        });
        _calculateETA();

        // Send location with orderId via WebSocket for real-time route updates.
        // IMPORTANT: prefer the snapped-to-road position so the customer sees the
        // driver marker on the road, not off-road. Fall back to raw GPS only if
        // snap-to-road failed.
        if (widget.order.apiId != null) {
          final latToSend = _snappedDriverLat ?? position.latitude;
          final lngToSend = _snappedDriverLng ?? position.longitude;
          WebSocketService.instance.sendLocationUpdate(
            driverId: widget.order.driverId ?? 0,
            lat: latToSend,
            lng: lngToSend,
            orderId: widget.order.apiId,
          );
          debugPrint(
            '[DeliveryMapPage] Sent location to backend: ${latToSend.toStringAsFixed(6)}, ${lngToSend.toStringAsFixed(6)} (snapped=${_snappedDriverLat != null})',
          );
        }

        debugPrint(
          '[DeliveryMapPage] setState called, polylines will rebuild with new driver location',
        );
      }
    } catch (e) {
      debugPrint('[DeliveryMapPage] Error getting driver location: $e');
    }
  }

  void _recalculateRouteIfNeeded() async {
    if (widget.order.apiId == null) return;
    if (widget.order.status != OrderStatus.pickingUp &&
        widget.order.status != OrderStatus.delivering &&
        widget.order.status != OrderStatus.pickedUp) {
      return;
    }
    if (_snappedDriverLat == null || _snappedDriverLng == null) return;

    if (!mounted) return;
    setState(() => _isCalculatingRoute = true);

    // For pickingUp status, we calculate route to store
    // For delivering/pickedUp status, we calculate route to destination
    final lat = widget.order.status == OrderStatus.pickingUp
        ? _pickupLat ?? STORE_LOCATION.latitude
        : (_deliveryLat ?? 0);
    final lng = widget.order.status == OrderStatus.pickingUp
        ? _pickupLng ?? STORE_LOCATION.longitude
        : (_deliveryLng ?? 0);

    if (lat == 0 || lng == 0) return;

    debugPrint('[DeliveryMapPage] Recalculating route with snapped driver position: $_snappedDriverLat, $_snappedDriverLng');

    final updateResult = await ApiService.updateDeliveryCoords(
      widget.order.apiId!,
      lat,
      lng,
      widget.order.status.apiValue,
      snappedLat: _snappedDriverLat,
      snappedLng: _snappedDriverLng,
    );

    if (updateResult != null && mounted) {
      final routes = updateResult['routes'] as Map<String, dynamic>?;
      if (routes != null) {
        setState(() {
          final newRouteToStore = routes['routeToStore'] as String?;
          final newRouteToDest = routes['routeToDestination'] as String?;

          // Backend may have snap-to-road'd our driver position. Adopt that
          // snapped position so the polyline and customer-side marker stay
          // consistent with what the server computed.
          final serverSnappedLat = updateResult['snappedDriverLat'] as num?;
          final serverSnappedLng = updateResult['snappedDriverLng'] as num?;
          if (serverSnappedLat != null && serverSnappedLng != null) {
            _snappedDriverLat = serverSnappedLat.toDouble();
            _snappedDriverLng = serverSnappedLng.toDouble();
            debugPrint(
              '[DeliveryMapPage] Using server-snapped position: $_snappedDriverLat, $_snappedDriverLng',
            );
          }

          if (newRouteToStore != null && newRouteToStore.isNotEmpty) {
            _routeToStore = newRouteToStore;
            _decodedStoreRoute = _decodePolyline(newRouteToStore);
            debugPrint('[DeliveryMapPage] Recalculated store route: ${_decodedStoreRoute.length} points');
          }
          if (newRouteToDest != null && newRouteToDest.isNotEmpty) {
            _routeToDestination = newRouteToDest;
            _decodedDestRoute = _decodePolyline(newRouteToDest);
            debugPrint('[DeliveryMapPage] Recalculated dest route: ${_decodedDestRoute.length} points');
          }
        });
      }
    }
    if (mounted) {
      setState(() => _isCalculatingRoute = false);
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateDriverLocation();
    });
  }

  void _centerMap() {
    if (_driverLat != null && _driverLng != null) {
      // Fit both driver and destination
      final points = <LatLng>[];
      points.add(LatLng(_driverLat!, _driverLng!));

      if (widget.order.status == OrderStatus.pickingUp && _pickupLat != null) {
        points.add(LatLng(_pickupLat!, _pickupLng!));
      } else if (_deliveryLat != null) {
        points.add(LatLng(_deliveryLat!, _deliveryLng!));
      }

      if (points.length >= 2) {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      }
    }
  }

  void _calculateETA() {
    if (_driverLat == null || _driverLng == null) return;

    final LatLng destination;
    if (widget.order.status == OrderStatus.pickingUp) {
      destination = LatLng(
        _pickupLat ?? STORE_LOCATION.latitude,
        _pickupLng ?? STORE_LOCATION.longitude,
      );
    } else {
      destination = LatLng(_deliveryLat ?? 0, _deliveryLng ?? 0);
    }

    final distance = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(_driverLat!, _driverLng!),
      destination,
    );

    // Assume average speed of 30 km/h in city
    final minutes = ((distance / 30) * 60).round();
    setState(() {
      _estimatedMinutes = minutes.clamp(1, 60);
    });
  }

  List<Marker> get _markers {
    final List<Marker> markers = [];

    // Store/pickup marker (blue)
    if (_pickupLat != null && _pickupLng != null) {
      markers.add(
        Marker(
          point: LatLng(_pickupLat!, _pickupLng!),
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
    }

    // Delivery marker (red)
    if (_deliveryLat != null && _deliveryLng != null) {
      markers.add(
        Marker(
          point: LatLng(_deliveryLat!, _deliveryLng!),
          width: 50,
          height: 60,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TUJUAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.location_on, color: Color(0xFFE53935), size: 30),
            ],
          ),
        ),
      );
    }

    // Driver marker (green)
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

  List<Polyline> get _polylines {
    debugPrint(
      '[DeliveryMapPage] _polylines called: status=${widget.order.status}, driverLat=$_driverLat, driverLng=$_driverLng',
    );
    final List<Polyline> lines = [];

    // Safety check: if coordinates are 0.0, treat as invalid
    if (_pickupLat == 0.0 || _pickupLng == 0.0) {
      _pickupLat = null;
      _pickupLng = null;
    }
    if (_deliveryLat == 0.0 || _deliveryLng == 0.0) {
      _deliveryLat = null;
      _deliveryLng = null;
    }

    if (widget.order.status == OrderStatus.pickingUp) {
      debugPrint(
        '[DeliveryMapPage] Status is pickingUp, decodedStoreRoute length: ${_decodedStoreRoute.length}',
      );
      // Only draw the polyline if we have a proper route (not a straight-line fallback).
      // When route is empty, the OSRM call probably failed — leave lines empty so the map
      // just shows markers. A "Loading..." chip is already shown in the UI.
      if (_decodedStoreRoute.isNotEmpty &&
          _driverLat != null &&
          _driverLng != null) {
        final split = _splitRouteAtDriver(
          _decodedStoreRoute,
          LatLng(_driverLat!, _driverLng!),
        );
        if (split['traveled']!.isNotEmpty) {
          lines.add(
            Polyline(
              points: split['traveled']!,
              color: const Color(0xFF43A047),
              strokeWidth: 5,
            ),
          );
        }
        if (split['remaining']!.isNotEmpty) {
          lines.add(
            Polyline(
              points: split['remaining']!,
              color: const Color(0xFF1565C0),
              strokeWidth: 5,
            ),
          );
        }
      }
      // NOTE: No fallback straight line. Without a real route, we just show the
      // driver marker + pickup/store marker and the "Calculating route..." chip.
    } else {
      debugPrint(
        '[DeliveryMapPage] Status is NOT pickingUp (pickedUp/delivering), decodedDestRoute length: ${_decodedDestRoute.length}',
      );
      if (_decodedDestRoute.isNotEmpty &&
          _driverLat != null &&
          _driverLng != null) {
        final split = _splitRouteAtDriver(
          _decodedDestRoute,
          LatLng(_driverLat!, _driverLng!),
        );
        if (split['traveled']!.isNotEmpty) {
          lines.add(
            Polyline(
              points: split['traveled']!,
              color: const Color(0xFF43A047),
              strokeWidth: 5,
            ),
          );
        }
        if (split['remaining']!.isNotEmpty) {
          lines.add(
            Polyline(
              points: split['remaining']!,
              color: const Color(0xFFE53935),
              strokeWidth: 5,
            ),
          );
        }
      }
      // NOTE: No fallback straight line. Same rationale as above.
    }

    debugPrint(
      '[DeliveryMapPage] _polylines returning ${lines.length} polylines',
    );
    return lines;
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMap,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: STORE_LOCATION,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.kelun.currier',
                    ),
                    MarkerLayer(markers: _markers),
                    if (_polylines.isNotEmpty)
                      PolylineLayer(polylines: _polylines),
                  ],
                ),

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

                // Loading indicator
                if (_isLoadingLocation)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: CircularProgressIndicator(),
                  ),

                // Calculating route indicator
                if (_isCalculatingRoute && !_isLoadingLocation)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1565C0),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Menghitung rute…',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Store info chip
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warehouse,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _storeAddress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                            isPickingUp ? Icons.warehouse : Icons.location_on,
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
                                    ? 'Lokasi Pickup (Toko)'
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
                                    ? _storeAddress
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
                              widget.order.customerName.isNotEmpty
                                  ? widget.order.customerName[0]
                                  : 'C',
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
                              onPressed: () async {
                                final orderApiId = widget.order.apiId;
                                if (orderApiId == null) return;

                                final driverId = widget.order.driverId ?? 1;
                                final customerId = widget.order.customerId ?? 1;
                                final response = await ApiService.post(
                                  '/chat/order/$orderApiId',
                                  {'customerId': customerId, 'driverId': driverId},
                                );
                                if (response != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomPage(
                                        conversationId: response['id'],
                                        orderId: orderApiId,
                                        customerId: customerId,
                                        driverId: driverId,
                                        userType: 'driver',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Order items summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF1565C0),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.order.itemDescription,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.order.itemCount} item',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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
