import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ProductVariant } from './product-variant.entity.js';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn()
  id!: number;


  @Column()
  name!: string;


  @Column({ type: 'text', default: '' })
  description!: string;


  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price!: number;


  @Column({ name: 'imageUrl', default: '' })
  imageUrl!: string;


  @Column({ default: '' })
  category!: string;


  @Column({ type: 'decimal', precision: 3, scale: 1, default: 0 })
  rating!: number;


  @Column({ default: 0 })
  sold!: number;


  @Column({ default: '' })
  seller!: string;


  @Column({ name: 'sellerCity', default: '' })
  sellerCity!: string;


  @Column({ default: 0 })
  stock!: number;


  @Column({ name: 'leadTime', type: 'int', default: 3 })
  leadTime!: number;


  @Column({ name: 'safetyStock', type: 'int', default: 5 })
  safetyStock!: number;


  @Column({ default: 'Piece' })
  unit!: string;


  @CreateDateColumn({ name: 'createdAt' })
  createdAt!: Date;


  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt!: Date;


  @OneToMany(() => ProductVariant, (v) => v.product, {
    cascade: true,
    eager: true,
  })
  variants!: ProductVariant[];}
