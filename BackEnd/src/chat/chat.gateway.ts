import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service.js';
import { SenderType } from './entities/message.entity.js';

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly chatService: ChatService) {}

  handleConnection(client: Socket) {
    console.log(`[ChatWS] Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`[ChatWS] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_order_chat')
  async handleJoinOrderChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { orderId: number; userType: string; userId: number },
  ) {
    const roomName = `order_${data.orderId}_chat`;
    client.join(roomName);
    console.log(`[ChatWS] Client ${client.id} joined ${roomName} as ${data.userType}`);
    return { event: 'joined', room: roomName };
  }

  @SubscribeMessage('leave_order_chat')
  async handleLeaveOrderChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { orderId: number },
  ) {
    const roomName = `order_${data.orderId}_chat`;
    client.leave(roomName);
    console.log(`[ChatWS] Client ${client.id} left ${roomName}`);
    return { event: 'left', room: roomName };
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: number; senderType: string; senderId: number; message: string },
  ) {
    try {
      const senderType = data.senderType === 'customer' ? SenderType.CUSTOMER : SenderType.DRIVER;
      const savedMessage = await this.chatService.createMessage(
        data.conversationId,
        senderType,
        data.senderId,
        data.message,
      );

      await this.chatService.updateConversationTimestamp(data.conversationId);

      const conversation = await this.chatService.getConversationById(data.conversationId);
      if (conversation) {
        const roomName = `order_${conversation.orderId}_chat`;
        const messagePayload = {
          id: savedMessage.id,
          conversationId: savedMessage.conversationId,
          senderType: savedMessage.senderType,
          senderId: savedMessage.senderId,
          message: savedMessage.message,
          createdAt: savedMessage.createdAt,
        };
        this.server.to(roomName).emit('new_message', messagePayload);
        console.log(`[ChatWS] Broadcast new_message to ${roomName}`);
      }

      return { event: 'message_sent', success: true, messageId: savedMessage.id };
    } catch (error) {
      console.error('[ChatWS] Error sending message:', error);
      return { event: 'message_sent', success: false, error: error.message };
    }
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId: number },
  ) {
    try {
      await this.chatService.markMessageAsRead(data.messageId);
      return { event: 'marked_read', success: true };
    } catch (error) {
      console.error('[ChatWS] Error marking message as read:', error);
      return { event: 'marked_read', success: false, error: error.message };
    }
  }
}