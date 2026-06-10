import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/chat_socket_service.dart';

class ChatRoomPage extends StatefulWidget {
  final int conversationId;
  final int orderId;
  final int customerId;
  final int driverId;
  final String userType;

  const ChatRoomPage({
    super.key,
    required this.conversationId,
    required this.orderId,
    required this.customerId,
    required this.driverId,
    required this.userType,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatSocketService _chatSocket = ChatSocketService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  void _setupSocket() {
    _chatSocket.connect();
    _chatSocket.joinOrderChat(widget.orderId, widget.userType, widget.customerId);

    _messageSubscription = _chatSocket.messageStream.listen((message) {
      if (message.conversationId == widget.conversationId) {
        setState(() {
          _messages.removeWhere((m) =>
              m['_pending'] == true &&
              m['message'] == message.message &&
              m['senderType'] == message.senderType);
          _messages.add({
            'id': message.id,
            'conversationId': message.conversationId,
            'senderType': message.senderType,
            'senderId': message.senderId,
            'message': message.message,
            'createdAt': message.createdAt.toIso8601String(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    debugPrint('[ChatRoom] Loading messages for conversation ${widget.conversationId}');
    try {
      final api = ApiService();
      final response = await api.get('/chat/conversation/${widget.conversationId}/messages');
      debugPrint('[ChatRoom] API response: $response');
      setState(() {
        _messages = response.map<Map<String, dynamic>>((m) => {
              'id': m['id'],
              'conversationId': m['conversationId'],
              'senderType': m['senderType'],
              'senderId': m['senderId'],
              'message': m['message'],
              'createdAt': m['createdAt'],
            }).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e, stack) {
      debugPrint('[ChatRoom] Error loading messages: $e');
      debugPrint('[ChatRoom] Stack: $stack');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!_chatSocket.isConnected) {
      debugPrint('[ChatRoom] Socket not connected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak terhubung ke server, coba lagi...')),
      );
      return;
    }

    final senderId = widget.userType == 'customer' ? widget.customerId : widget.driverId;
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _messages.add({
        'id': tempId,
        'conversationId': widget.conversationId,
        'senderType': widget.userType,
        'senderId': senderId,
        'message': text,
        'createdAt': DateTime.now().toIso8601String(),
        '_pending': true,
      });
    });
    _messageController.clear();
    _scrollToBottom();

    _chatSocket.sendMessage(
      widget.conversationId,
      widget.userType,
      senderId,
      text,
    );

    debugPrint('[ChatRoom] Sent optimistic message, waiting for server confirmation');
  }

  @override
  void dispose() {
    _chatSocket.leaveOrderChat(widget.orderId);
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Order #${widget.orderId}'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          Icon(
            _chatSocket.isConnected ? Icons.wifi : Icons.wifi_off,
            color: _chatSocket.isConnected ? Colors.white : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderType'] == widget.userType;
                          final isPending = msg['_pending'] == true;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF6C63FF) : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['message'] ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(msg['createdAt']),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                      if (isPending) ...[
                                        const SizedBox(width: 4),
                                        const SizedBox(
                                          width: 8,
                                          height: 8,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}