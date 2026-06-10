import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatController } from './chat.controller.js';
import { ChatService } from './chat.service.js';
import { ChatGateway } from './chat.gateway.js';
import { Conversation } from './entities/conversation.entity.js';
import { Message } from './entities/message.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Conversation, Message])],
  controllers: [ChatController],
  providers: [ChatService, ChatGateway],
  exports: [ChatService],
})
export class ChatModule {}