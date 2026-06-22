import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ProductsSocketService {
  static final ProductsSocketService instance = ProductsSocketService._();
  ProductsSocketService._();

  io.Socket? _socket;
  final _productCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _productUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _productDeletedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get productCreatedUpdates => _productCreatedController.stream;
  Stream<Map<String, dynamic>> get productUpdatedUpdates => _productUpdatedController.stream;
  Stream<Map<String, dynamic>> get productDeletedUpdates => _productDeletedController.stream;

  void connect() {
    if (_socket != null && _socket!.connected) {
      return;
    }

    // Resolve base URL from --dart-define=API_URL=...; default to the
    // production Dokploy backend. socket_io_client expects an http(s) URL
    // and will upgrade to WebSocket automatically.
    const envBase = String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://api-kelun.ngelantour.cloud',
    );
    const wsUrl = '$envBase/products';

    _socket = io.io(wsUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 999999,
    });

    _socket!.onConnect((_) {
      debugPrint('[ProductsSocketService] Connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[ProductsSocketService] Disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('[ProductsSocketService] Connection error: $error');
    });

    _socket!.on('product_created', (data) {
      debugPrint('[ProductsSocketService] product_created: $data');
      if (data is Map<String, dynamic>) {
        _productCreatedController.add(data);
      }
    });

    _socket!.on('product_updated', (data) {
      debugPrint('[ProductsSocketService] product_updated: $data');
      if (data is Map<String, dynamic>) {
        _productUpdatedController.add(data);
      }
    });

    _socket!.on('product_deleted', (data) {
      debugPrint('[ProductsSocketService] product_deleted: $data');
      if (data is Map<String, dynamic>) {
        _productDeletedController.add(data);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _productCreatedController.close();
    _productUpdatedController.close();
    _productDeletedController.close();
  }
}
