import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Order } from '../orders/order.entity.js';

@Entity('customers')
export class Customer {
  @PrimaryGeneratedColumn()
  id!: number;


  @Column()
  name!: string;


  @Column({ nullable: true, default: '' })
  username!: string;


  @Column({ unique: true })
  phone!: string;


  @Column()
  password!: string;


  @Column({ default: '' })
  address!: string;


  @CreateDateColumn({ name: 'createdAt' })
  createdAt!: Date;


  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt!: Date;


  @OneToMany(() => Order, (order) => order.customer)
  orders!: Order[];

}
