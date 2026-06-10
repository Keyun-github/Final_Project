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
      senderType: json['senderType'] ?? 'customer',
      senderId: json['senderId'] ?? 0,
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ChatSocketService {
  static ChatSocketService? _instance;
  io.Socket? _socket;
  bool _isConnecting = false;

  int? _pendingOrderId;
  String? _pendingUserType;
  int? _pendingUserId;

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;

  bool get isConnected => _socket?.connected ?? false;

  static ChatSocketService get instance {
    _instance ??= ChatSocketService._();
    return _instance!;
  }

  ChatSocketService._();

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('[ChatSocket] Already connected');
      _flushPendingJoin();
      return;
    }

    if (_isConnecting) {
      debugPrint('[ChatSocket] Connection in progress');
      return;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _isConnecting = true;

    final wsUrl = '${ApiService.baseUrl}/chat';
    debugPrint('[ChatSocket] Connecting to $wsUrl');

    _socket = io.io(wsUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 999999,
    });

    _socket!.onConnect((_) {
      debugPrint('[ChatSocket] Connected: ${_socket!.id}');
      _isConnecting = false;
      _flushPendingJoin();
    });

    _socket!.onDisconnect((_) {
      debugPrint('[ChatSocket] Disconnected');
      _isConnecting = false;
    });

    _socket!.onConnectError((error) {
      debugPrint('[ChatSocket] Connection error: $error');
      _isConnecting = false;
    });

    _socket!.on('new_message', (data) {
      debugPrint('[ChatSocket] new_message: $data');
      if (data is Map) {
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        _messageController.add(message);
      }
    });

    _socket!.connect();
  }

  void _flushPendingJoin() {
    if (_pendingOrderId == null) return;
    if (_socket == null || !_socket!.connected) return;
    _emitJoin(_pendingOrderId!, _pendingUserType!, _pendingUserId!);
  }

  void _emitJoin(int orderId, String userType, int userId) {
    _socket!.emit('join_order_chat', {
      'orderId': orderId,
      'userType': userType,
      'userId': userId,
    });
    debugPrint('[ChatSocket] Joined order_$orderId chat as $userType');
  }

  void joinOrderChat(int orderId, String userType, int userId) {
    _pendingOrderId = orderId;
    _pendingUserType = userType;
    _pendingUserId = userId;

    if (_socket == null) {
      connect();
      return;
    }

    if (_socket!.connected) {
      _emitJoin(orderId, userType, userId);
    } else {
      debugPrint('[ChatSocket] Socket not connected yet, join queued for order $orderId');
    }
  }

  void leaveOrderChat(int orderId) {
    if (_socket == null) return;

    if (_socket!.connected) {
      _socket!.emit('leave_order_chat', {'orderId': orderId});
      debugPrint('[ChatSocket] Left order_$orderId chat');
    }

    if (_pendingOrderId == orderId) {
      _pendingOrderId = null;
      _pendingUserType = null;
      _pendingUserId = null;
    }
  }

  void sendMessage(int conversationId, String senderType, int senderId, String message) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[ChatSocket] Socket not connected, cannot send message');
      return;
    }

    _socket!.emitWithAck(
      'send_message',
      {
        'conversationId': conversationId,
        'senderType': senderType,
        'senderId': senderId,
        'message': message,
      },
      ack: (data) {
        debugPrint('[ChatSocket] Send message ack: $data');
      },
    );
    debugPrint('[ChatSocket] Sent message to conversation_$conversationId');
  }

  void disconnect() {
    _pendingOrderId = null;
    _pendingUserType = null;
    _pendingUserId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
    debugPrint('[ChatSocket] Disconnected');
  }
}