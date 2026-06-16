import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Message } from './message.entity.js';

@Entity('conversations')
export class Conversation {
  @PrimaryGeneratedColumn()
  id!: number;


  @Column({ name: 'order_id', unique: true })
  orderId!: number;


  @Column({ name: 'customer_id' })
  customerId!: number;


  @Column({ name: 'driver_id' })
  driverId!: number;


  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;


  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;


  @OneToMany(() => Message, (message) => message.conversation)
  messages!: Message[];

}