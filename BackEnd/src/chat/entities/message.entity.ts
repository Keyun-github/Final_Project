import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Conversation } from './conversation.entity.js';

export enum SenderType {
  CUSTOMER = 'customer',
  DRIVER = 'driver',
}

@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn()
  id!: number;


  @Column({ name: 'conversation_id' })
  conversationId!: number;


  @Column({ name: 'sender_type', type: 'varchar', length: 20 })
  senderType!: SenderType;


  @Column({ name: 'sender_id' })
  senderId!: number;


  @Column({ type: 'text' })
  message!: string;


  @Column({ name: 'is_read', default: false })
  isRead!: boolean;


  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;


  @ManyToOne(() => Conversation, (conversation) => conversation.messages)
  @JoinColumn({ name: 'conversation_id' })
  conversation!: Conversation;

}