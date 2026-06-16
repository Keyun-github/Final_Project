import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('units')
export class Unit {
  @PrimaryGeneratedColumn()
  id!: number;


  @Column({ unique: true, length: 50 })
  name!: string;


  @Column({ name: 'is_default', default: false })
  isDefault!: boolean;


  @Column({ name: 'is_active', default: true })
  isActive!: boolean;


  @CreateDateColumn({ name: 'createdAt' })
  createdAt!: Date;

}
