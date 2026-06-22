import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Order } from './order.entity.js';
import { Product } from '../products/product.entity.js';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn()
  id!: number;


  @Column({ name: 'orderId' })
  orderId!: number;


  @Column({ name: 'productId', nullable: true })
  productId!: number | null;


  @Column({ name: 'productName' })
  productName!: string;


  @Column({ default: 1 })
  quantity!: number;


  @Column({ name: 'unitPrice', type: 'decimal', precision: 12, scale: 2 })
  unitPrice!: number;


  @Column({ name: 'unitName', default: '' })
  unitName!: string;


  @Column({ type: 'decimal', precision: 12, scale: 2 })
  subtotal!: number;


  @CreateDateColumn({ name: 'createdAt' })
  createdAt!: Date;


  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt!: Date;


  @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
  order!: Order;


  @ManyToOne(() => Product, { nullable: true })
  product!: Product;

}
