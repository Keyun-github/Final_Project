import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { TimeSlot } from './time-slot.entity.js';
import { Order } from '../orders/order.entity.js';

export interface TimeSlotInfo {
  time: string;
  available: boolean;
  bookings: number;
  maxBookings: number;
  isActive: boolean;
}

export interface DashboardSlotInfo {
  slotId: number;
  time: string;
  orderCount: number;
  bookings: number;
  maxBookings: number;
  isActive: boolean;
}

@Injectable()
export class TimeSlotsService {
  constructor(
    @InjectRepository(TimeSlot)
    private readonly timeSlotRepo: Repository<TimeSlot>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
  ) {}

  // Generate all time slots for a given date
  private generateTimeSlots(): string[] {
    const slots: string[] = [];
    for (let hour = 8; hour < 16; hour++) {
      slots.push(`${hour.toString().padStart(2, '0')}:00`);
      slots.push(`${hour.toString().padStart(2, '0')}:30`);
    }
    slots.push('16:00');
    slots.push('16:30');
    return slots;
  }

  // Parse "HH:mm" into [hour, minute]
  private parseTime(time: string): { hour: number; minute: number } {
    const [hour, minute] = time.split(':').map((v) => parseInt(v, 10));
    return { hour, minute };
  }

  // Get the 30-min window [start, end) for a slot time
  private getSlotWindow(date: string, time: string): { start: Date; end: Date } {
    const { hour, minute } = this.parseTime(time);
    const start = new Date(date);
    start.setHours(hour, minute, 0, 0);
    const end = new Date(start);
    end.setMinutes(end.getMinutes() + 30);
    return { start, end };
  }

  // Get available time slots for a specific date
  async getAvailableSlots(date: string): Promise<TimeSlotInfo[]> {
    const allSlots = this.generateTimeSlots();
    const result: TimeSlotInfo[] = [];

    for (const time of allSlots) {
      let slot = await this.timeSlotRepo.findOne({
        where: { slotTime: time, slotDate: date },
      });

      if (!slot) {
        // Create slot if it doesn't exist
        slot = this.timeSlotRepo.create({
          slotTime: time,
          slotDate: date,
          bookings: 0,
          maxBookings: 3,
          isActive: true,
        });
        slot = await this.timeSlotRepo.save(slot);
      }

      result.push({
        time,
        available: slot.isActive && slot.bookings < slot.maxBookings,
        bookings: slot.bookings,
        maxBookings: slot.maxBookings,
        isActive: slot.isActive,
      });
    }

    return result;
  }

  // Book a time slot
  async bookSlot(date: string, time: string): Promise<boolean> {
    let slot = await this.timeSlotRepo.findOne({
      where: { slotTime: time, slotDate: date },
    });

    if (!slot) {
      // Create slot if it doesn't exist
      slot = this.timeSlotRepo.create({
        slotTime: time,
        slotDate: date,
        bookings: 0,
        maxBookings: 3,
        isActive: true,
      });
      slot = await this.timeSlotRepo.save(slot);
    }

    if (!slot.isActive) {
      return false; // Slot is disabled by admin
    }

    if (slot.bookings >= slot.maxBookings) {
      return false; // Slot is full
    }

    slot.bookings += 1;
    await this.timeSlotRepo.save(slot);
    return true;
  }

  // Reset daily slots (optional - call this daily to reset bookings)
  async resetDailySlots(date: string): Promise<void> {
    await this.timeSlotRepo.update({ slotDate: date }, { bookings: 0 });
  }

  // Get dashboard slot info: 18 slots + order count by createdAt within 30-min window
  async getDashboardSlots(date: string): Promise<DashboardSlotInfo[]> {
    const allSlots = this.generateTimeSlots();
    const result: DashboardSlotInfo[] = [];

    for (const time of allSlots) {
      // Ensure slot row exists
      let slot = await this.timeSlotRepo.findOne({
        where: { slotTime: time, slotDate: date },
      });

      if (!slot) {
        slot = this.timeSlotRepo.create({
          slotTime: time,
          slotDate: date,
          bookings: 0,
          maxBookings: 3,
          isActive: true,
        });
        slot = await this.timeSlotRepo.save(slot);
      }

      // Count orders whose createdAt falls in this 30-min window
      const { start, end } = this.getSlotWindow(date, time);
      const orderCount = await this.orderRepo.count({
        where: { createdAt: Between(start, end) },
      });

      result.push({
        slotId: slot.id,
        time,
        orderCount,
        bookings: slot.bookings,
        maxBookings: slot.maxBookings,
        isActive: slot.isActive,
      });
    }

    return result;
  }

  // Get orders whose createdAt falls in the 30-min window of the given slot
  async getOrdersBySlot(
    date: string,
    time: string,
  ): Promise<
    {
      id: number;
      customerName: string;
      customerPhone: string;
      status: string;
      totalAmount: number;
      createdAt: Date;
      driverName: string | null;
    }[]
  > {
    const { start, end } = this.getSlotWindow(date, time);
    const orders = await this.orderRepo.find({
      where: { createdAt: Between(start, end) },
      relations: ['driver'],
      order: { createdAt: 'ASC' },
    });

    return orders.map((o) => ({
      id: o.id,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      status: o.status,
      totalAmount: Number(o.totalAmount),
      createdAt: o.createdAt,
      driverName: o.driver?.name ?? null,
    }));
  }

  // Set slot active/inactive by id
  async setSlotActive(slotId: number, isActive: boolean): Promise<TimeSlot> {
    const slot = await this.timeSlotRepo.findOne({ where: { id: slotId } });
    if (!slot) {
      throw new NotFoundException(`TimeSlot with id ${slotId} not found`);
    }
    slot.isActive = isActive;
    return this.timeSlotRepo.save(slot);
  }
}
