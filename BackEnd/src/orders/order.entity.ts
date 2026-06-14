import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
} from 'typeorm';
import { OrderItem } from './order-item.entity.js';
import { Driver } from '../drivers/driver.entity.js';
import { Customer } from '../customers/customer.entity.js';

export enum OrderStatus {
  PENDING = 'pending',
  PENDING_PAYMENT = 'pending_payment',
  PICKING_UP = 'pickingUp',
  PICKED_UP = 'pickedUp',
  DELIVERING = 'delivering',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'customerId', nullable: true })
  customerId: number | null;

  @ManyToOne(() => Customer, { nullable: true })
  customer: Customer;

  @Column({ name: 'customerName' })
  customerName: string;

  @Column({ name: 'customerPhone', default: '' })
  customerPhone: string;

  @Column({
    name: 'pickupAddress',
    default: 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
  })
  pickupAddress: string;

  @Column({ name: 'deliveryAddress', default: '' })
  deliveryAddress: string;

  @Column({
    name: 'totalAmount',
    type: 'decimal',
    precision: 12,
    scale: 2,
    default: 0,
  })
  totalAmount: number;

  @Column({ type: 'varchar', default: OrderStatus.PENDING })
  status: OrderStatus;

  @Column({ name: 'paymentMethod', default: 'COD' })
  paymentMethod: string;

  @Column({ name: 'driverId', nullable: true })
  driverId: number | null;

  @Column({ name: 'deliveryPhoto', nullable: true, type: 'varchar' })
  deliveryPhoto: string | null;

  @Column({ name: 'deliveryLat', nullable: true, type: 'float', default: 0 })
  deliveryLat: number | null;

  @Column({ name: 'deliveryLng', nullable: true, type: 'float', default: 0 })
  deliveryLng: number | null;

  @ManyToOne(() => Driver, { nullable: true })
  driver: Driver;

  @CreateDateColumn({ name: 'createdAt' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt: Date;

  @OneToMany(() => OrderItem, (item) => item.order, {
    cascade: true,
    eager: true,
  })
  items: OrderItem[];
}
