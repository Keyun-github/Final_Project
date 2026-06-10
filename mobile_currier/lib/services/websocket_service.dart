import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class Message {
  final int id;
  final int conversationId;
  final String senderType;
  final int senderId;
  final String message;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderType: json['senderType'] ?? 'driver',
      senderId: json['senderId'] ?? 0,
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class WebSocketService {
  static WebSocketService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  int? _driverId;

  final StreamController<Map<String, dynamic>> _locationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _routeUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();

  io.Socket? _chatSocket;
  bool _isChatConnecting = false;

  int? _pendingOrderId;
  String? _pendingUserType;
  int? _pendingUserId;

  Stream<Map<String, dynamic>> get locationUpdates => _locationUpdateController.stream;

  Stream<Map<String, dynamic>> get orderUpdates => _orderUpdateController.stream;

  Stream<Map<String, dynamic>> get routeUpdates => _routeUpdateController.stream;

  Stream<Message> get messageStream => _messageController.stream;

  bool get isConnected => _isConnected;

  bool get isChatConnected => _chatSocket?.connected ?? false;

  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  WebSocketService._();

  Future<bool> connect(int driverId) async {
    try {
      _driverId = driverId;
      final wsUrl = '${ApiService.baseUrl}/driver-location';
      debugPrint('[WebSocketService] Connecting to $wsUrl');

      _socket = io.io(wsUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': 999999,
      });

      _socket!.onConnect((_) {
        debugPrint('[WebSocketService] Connected: ${_socket!.id}');
        _isConnected = true;

        _socket!.emit('register_driver', {'driverId': driverId});
        debugPrint('[WebSocketService] Registered driver $driverId');

        _socket!.emit('driver_subscribe');
        debugPrint('[WebSocketService] Subscribed to order notifications');
      });

      _socket!.onDisconnect((_) {
        debugPrint('[WebSocketService] Disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        debugPrint('[WebSocketService] Connection error: $error');
        _isConnected = false;
      });

      _socket!.on('driver_location_changed', (data) {
        debugPrint('[WebSocketService] driver_location_changed: $data');
        if (data is Map<String, dynamic>) {
          _locationUpdateController.add(data);
        }
      });

      _socket!.on('new_order', (data) {
        debugPrint('[WebSocketService] new_order received: $data');
        if (data is Map<String, dynamic>) {
          _orderUpdateController.add(data);
        }
      });

      _socket!.on('route_update', (data) {
        debugPrint('[WebSocketService] route_update received: $data');
        if (data is Map<String, dynamic>) {
          _routeUpdateController.add(data);
        }
      });

      _socket!.connect();
      return true;
    } catch (e) {
      debugPrint('[WebSocketService] Connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<bool> sendLocationUpdate({
    required int driverId,
    required double lat,
    required double lng,
    int? orderId,
  }) async {
    if (!_isConnected || _socket == null) {
      debugPrint('[WebSocketService] Not connected, cannot send location');
      return false;
    }

    try {
      final data = {
        'driverId': driverId,
        'lat': lat,
        'lng': lng,
      };
      if (orderId != null) {
        (data as Map<String, dynamic>)['orderId'] = orderId;
      }

      _socket!.emitWithAck('driver_location_update', data, ack: (ackData) {
        debugPrint('[WebSocketService] Location update ack: $ackData');
      });
      debugPrint('[WebSocketService] Location sent: lat=$lat, lng=$lng, orderId=$orderId');
      return true;
    } catch (e) {
      debugPrint('[WebSocketService] Failed to send location: $e');
      return false;
    }
  }

  void disconnect() {
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _pendingOrderId = null;
    _pendingUserType = null;
    _pendingUserId = null;
    _chatSocket?.disconnect();
    _chatSocket?.dispose();
    _chatSocket = null;
    _isChatConnecting = false;
    _driverId = null;
    debugPrint('[WebSocketService] Disconnected');
  }

  void connectToChat() {
    if (_chatSocket != null && _chatSocket!.connected) {
      debugPrint('[WebSocketService] Chat already connected');
      _flushPendingChatJoin();
      return;
    }

    if (_isChatConnecting) {
      debugPrint('[WebSocketService] Chat connection in progress');
      return;
    }

    if (_chatSocket != null) {
      _chatSocket!.dispose();
      _chatSocket = null;
    }

    _isChatConnecting = true;

    final wsUrl = '${ApiService.baseUrl}/chat';
    debugPrint('[WebSocketService] Connecting to chat at $wsUrl');

    _chatSocket = io.io(wsUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 999999,
    });

    _chatSocket!.onConnect((_) {
      debugPrint('[WebSocketService] Chat connected: ${_chatSocket!.id}');
      _isChatConnecting = false;
      _flushPendingChatJoin();
    });

    _chatSocket!.onDisconnect((_) {
      debugPrint('[WebSocketService] Chat disconnected');
      _isChatConnecting = false;
    });

    _chatSocket!.on('new_message', (data) {
      debugPrint('[WebSocketService] new_message: $data');
      if (data is Map) {
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        _messageController.add(message);
      }
    });

    _chatSocket!.connect();
  }

  void _flushPendingChatJoin() {
    if (_pendingOrderId == null) return;
    if (_chatSocket == null || !_chatSocket!.connected) return;
    _emitChatJoin(_pendingOrderId!, _pendingUserType!, _pendingUserId!);
  }

  void _emitChatJoin(int orderId, String userType, int userId) {
    _chatSocket!.emit('join_order_chat', {
      'orderId': orderId,
      'userType': userType,
      'userId': userId,
    });
    debugPrint('[WebSocketService] Joined order_$orderId chat as $userType');
  }

  void joinOrderChat(int orderId, String userType, int userId) {
    _pendingOrderId = orderId;
    _pendingUserType = userType;
    _pendingUserId = userId;

    if (_chatSocket == null) {
      connectToChat();
      return;
    }

    if (_chatSocket!.connected) {
      _emitChatJoin(orderId, userType, userId);
    } else {
      debugPrint('[WebSocketService] Chat socket not connected yet, join queued for order $orderId');
    }
  }

  void leaveOrderChat(int orderId) {
    if (_chatSocket != null && _chatSocket!.connected) {
      _chatSocket!.emit('leave_order_chat', {'orderId': orderId});
      debugPrint('[WebSocketService] Left order_$orderId chat');
    }

    if (_pendingOrderId == orderId) {
      _pendingOrderId = null;
      _pendingUserType = null;
      _pendingUserId = null;
    }
  }

  void sendMessage(int conversationId, String senderType, int senderId, String message) {
    if (_chatSocket == null || !_chatSocket!.connected) {
      debugPrint('[WebSocketService] Chat socket not connected, cannot send message');
      return;
    }

    _chatSocket!.emitWithAck(
      'send_message',
      {
        'conversationId': conversationId,
        'senderType': senderType,
        'senderId': senderId,
        'message': message,
      },
      ack: (data) {
        debugPrint('[WebSocketService] Send message ack: $data');
      },
    );
    debugPrint('[WebSocketService] Sent message to conversation_$conversationId');
  }
}