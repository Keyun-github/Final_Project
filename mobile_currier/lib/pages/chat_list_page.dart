import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat/chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  final int driverId;

  const ChatListPage({super.key, required this.driverId});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/chat/driver/${widget.driverId}/conversations');
      setState(() {
        _conversations = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final lastMessage = conv['messages']?.isNotEmpty == true
                        ? conv['messages'].last
                        : null;
                    final orderId = conv['orderId'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6C63FF),
                        child: Text(
                          'Order#$orderId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text('Order #$orderId'),
                      subtitle: Text(
                        lastMessage != null
                            ? '${lastMessage['senderType']}: ${lastMessage['message']}'
                            : 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(conv['updatedAt']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(
                              conversationId: conv['id'],
                              orderId: orderId,
                              customerId: conv['customerId'],
                              driverId: widget.driverId,
                              userType: 'driver',
                            ),
                          ),
                        ).then((_) => _loadConversations());
                      },
                    );
                  },
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