import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conversation } from './entities/conversation.entity.js';
import { Message, SenderType } from './entities/message.entity.js';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Conversation)
    private readonly conversationRepo: Repository<Conversation>,
    @InjectRepository(Message)
    private readonly messageRepo: Repository<Message>,
  ) {}

  async getOrCreateConversation(orderId: number, customerId: number, driverId: number): Promise<Conversation> {
    let conversation = await this.conversationRepo.findOne({
      where: { orderId },
      relations: ['messages'],
    });

    if (!conversation) {
      conversation = this.conversationRepo.create({
        orderId,
        customerId,
        driverId,
      });
      conversation = await this.conversationRepo.save(conversation);
    }

    return conversation;
  }

  async getConversationByOrderId(orderId: number): Promise<Conversation | null> {
    return this.conversationRepo.findOne({
      where: { orderId },
      relations: ['messages'],
    });
  }

  async getConversationById(conversationId: number): Promise<Conversation | null> {
    return this.conversationRepo.findOne({
      where: { id: conversationId },
      relations: ['messages'],
    });
  }

  async getMessages(conversationId: number): Promise<Message[]> {
    return this.messageRepo.find({
      where: { conversationId },
      order: { createdAt: 'ASC' },
    });
  }

  async createMessage(
    conversationId: number,
    senderType: SenderType,
    senderId: number,
    messageText: string,
  ): Promise<Message> {
    const message = this.messageRepo.create({
      conversationId,
      senderType,
      senderId,
      message: messageText,
      isRead: false,
    });
    return this.messageRepo.save(message);
  }

  async markMessageAsRead(messageId: number): Promise<Message | null> {
    const message = await this.messageRepo.findOne({ where: { id: messageId } });
    if (message) {
      message.isRead = true;
      return this.messageRepo.save(message);
    }
    return null;
  }

  async markAllMessagesAsRead(conversationId: number, readerType: SenderType): Promise<void> {
    await this.messageRepo
      .createQueryBuilder()
      .update(Message)
      .set({ isRead: true })
      .where('conversation_id = :conversationId', { conversationId })
      .andWhere('sender_type != :readerType', { readerType })
      .execute();
  }

  async getConversationsByCustomer(customerId: number): Promise<Conversation[]> {
    return this.conversationRepo.find({
      where: { customerId },
      relations: ['messages'],
      order: { updatedAt: 'DESC' },
    });
  }

  async getConversationsByDriver(driverId: number): Promise<Conversation[]> {
    return this.conversationRepo.find({
      where: { driverId },
      relations: ['messages'],
      order: { updatedAt: 'DESC' },
    });
  }

  async updateConversationTimestamp(conversationId: number): Promise<void> {
    await this.conversationRepo.update(conversationId, {
      updatedAt: new Date(),
    });
  }

  async hideConversation(conversationId: number): Promise<void> {
    await this.conversationRepo.delete(conversationId);
  }
}