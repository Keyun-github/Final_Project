import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TimeSlot } from './time-slot.entity.js';
import { TimeSlotsService } from './time-slots.service.js';
import { TimeSlotsController } from './time-slots.controller.js';
import { Order } from '../orders/order.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([TimeSlot, Order])],
  controllers: [TimeSlotsController],
  providers: [TimeSlotsService],
  exports: [TimeSlotsService],
})
export class TimeSlotsModule {}
