import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  int? _currentOrderId;

  final StreamController<Map<String, dynamic>> _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get driverLocationUpdates => _driverLocationController.stream;

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

    final wsUrl = 'http://localhost:3000/driver-location';
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

    _socket!.connect();
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