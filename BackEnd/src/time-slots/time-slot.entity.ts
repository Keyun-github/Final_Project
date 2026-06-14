import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('time_slots')
export class TimeSlot {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'slotTime', length: 10 })
  slotTime: string;

  @Column({ name: 'slotDate', length: 20 })
  slotDate: string;

  @Column({ default: 0 })
  bookings: number;

  @Column({ default: 3 })
  maxBookings: number;

  @Column({ name: 'isActive', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'createdAt' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updatedAt' })
  updatedAt: Date;
}
