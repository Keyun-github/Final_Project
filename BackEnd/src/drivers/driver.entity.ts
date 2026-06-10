import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('drivers')
export class Driver {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  username: string;

  @Column()
  password: string;

  @Column()
  name: string;

  @Column({ default: '' })
  phone: string;

  @Column({ name: 'isActive', default: true })
  isActive: boolean;

  @Column({ name: 'vehicleType', default: 'motorcycle' })
  vehicleType: string;

  @Column({ name: 'vehicleBrand', default: '' })
  vehicleBrand: string;

  @Column({ name: 'vehiclePlate', default: '' })
  vehiclePlate: string;

  @Column({ name: 'vehicleColor', default: '' })
  vehicleColor: string;

  @Column({ name: 'currentLat', type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLat: number | null;

  @Column({ name: 'currentLng', type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLng: number | null;

  @Column({ name: 'isAvailable', default: true })
  isAvailable: boolean;

  @CreateDateColumn({ name: 'createdAt' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt: Date;
}
