import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  int? _currentOrderId;

  final StreamController<Map<String, dynamic>> _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _routeUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get driverLocationUpdates =>
      _driverLocationController.stream;

  Stream<Map<String, dynamic>> get routeUpdates => _routeUpdateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('[SocketService] Already connected');
      if (_currentOrderId != null) {
        subscribeToOrder(_currentOrderId!);
      }
      return;
    }

    // Prefer the same API URL the rest of the app uses; fall back to
    // localhost:3000 for local dev.
    final baseWs = _resolveBaseWs();
    final wsUrl = '$baseWs/driver-location';
    debugPrint('[SocketService] Connecting to $wsUrl');

    _socket = io.io(wsUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 999999,
    });

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected: ${_socket!.id}');
      if (_currentOrderId != null) {
        subscribeToOrder(_currentOrderId!);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('[SocketService] Connection error: $error');
    });

    _socket!.on('driver_location_changed', (data) {
      debugPrint('[SocketService] driver_location_changed: $data');
      if (data is Map<String, dynamic>) {
        _driverLocationController.add(data);
      }
    });

    _socket!.on('route_update', (data) {
      debugPrint('[SocketService] route_update: $data');
      if (data is Map<String, dynamic>) {
        _routeUpdateController.add(data);
      }
    });

    _socket!.connect();
  }

  /// Resolve the base URL for the WebSocket connection. In production the
  /// customer app will be configured via --dart-define=API_URL=..., but for
  /// dev convenience we fall back to localhost.
  String _resolveBaseWs() {
    const fromEnv = String.fromEnvironment('API_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      // Convert http(s):// → ws(s):// so socket_io_client accepts it.
      if (fromEnv.startsWith('https://')) {
        return fromEnv.replaceFirst('https://', 'wss://');
      }
      if (fromEnv.startsWith('http://')) {
        return fromEnv.replaceFirst('http://', 'ws://');
      }
      return fromEnv;
    }
    return 'https://api-kelun.ngelantour.cloud';
  }

  void subscribeToOrder(int orderId) {
    if (_socket == null) {
      debugPrint('[SocketService] Socket is null, cannot subscribe');
      return;
    }

    _currentOrderId = orderId;
    _socket!.emit('subscribe_order', {'orderId': orderId});
    debugPrint('[SocketService] Subscribed to order_$orderId');
  }

  void unsubscribeFromOrder(int orderId) {
    if (_socket == null) return;

    _socket!.emit('unsubscribe_order', {'orderId': orderId});
    debugPrint('[SocketService] Unsubscribed from order_$orderId');
    _currentOrderId = null;
  }

  void disconnect() {
    _currentOrderId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('[SocketService] Disconnected');
  }
}
