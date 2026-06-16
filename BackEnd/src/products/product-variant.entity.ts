import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Product } from './product.entity.js';

@Entity('product_variants')
export class ProductVariant {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'productId' })
  productId: number;

  @Column({ name: 'unitName' })
  unitName: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price: number;

  @Column({ type: 'int', default: 0 })
  stock: number;

  @CreateDateColumn({ name: 'createdAt' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt: Date;

  @ManyToOne(() => Product, (p) => p.variants, { onDelete: 'CASCADE' })
  product: Product;
}
