import {
  Controller,
  Get,
  Put,
  Post,
  Param,
  Body,
  ParseIntPipe,
  NotFoundException,
} from '@nestjs/common';
import { ChatService } from './chat.service.js';
import { SenderType } from './entities/message.entity.js';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('order/:orderId')
  async getOrCreateConversation(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Body() body: { customerId: number; driverId: number },
  ) {
    const conversation = await this.chatService.getOrCreateConversation(
      orderId,
      body.customerId,
      body.driverId,
    );
    return conversation;
  }

  @Get('conversation/:id')
  async getConversation(@Param('id', ParseIntPipe) id: number) {
    const conversation = await this.chatService.getConversationById(id);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }
    return conversation;
  }

  @Get('conversation/:id/messages')
  async getMessages(@Param('id', ParseIntPipe) id: number) {
    const messages = await this.chatService.getMessages(id);
    return messages;
  }

  @Put('message/:id/read')
  async markMessageAsRead(@Param('id', ParseIntPipe) id: number) {
    const message = await this.chatService.markMessageAsRead(id);
    if (!message) {
      throw new NotFoundException('Message not found');
    }
    return message;
  }

  @Get('customer/:customerId/conversations')
  async getCustomerConversations(@Param('customerId', ParseIntPipe) customerId: number) {
    const conversations = await this.chatService.getConversationsByCustomer(customerId);
    return conversations;
  }

  @Get('driver/:driverId/conversations')
  async getDriverConversations(@Param('driverId', ParseIntPipe) driverId: number) {
    const conversations = await this.chatService.getConversationsByDriver(driverId);
    return conversations;
  }
}