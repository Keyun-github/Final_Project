import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Body,
  HttpException,
  HttpStatus,
  ParseIntPipe,
} from '@nestjs/common';
import { TimeSlotsService } from './time-slots.service.js';

@Controller('time-slots')
export class TimeSlotsController {
  constructor(private readonly timeSlotsService: TimeSlotsService) {}

  @Get()
  async getAvailableSlots(@Query('date') date: string) {
    if (!date) {
      throw new HttpException(
        'Date is required (format: YYYY-MM-DD)',
        HttpStatus.BAD_REQUEST,
      );
    }
    return this.timeSlotsService.getAvailableSlots(date);
  }

  @Get('dashboard')
  async getDashboardSlots(@Query('date') date: string) {
    if (!date) {
      throw new HttpException(
        'Date is required (format: YYYY-MM-DD)',
        HttpStatus.BAD_REQUEST,
      );
    }
    return this.timeSlotsService.getDashboardSlots(date);
  }

  @Get('slot-orders')
  async getOrdersBySlot(
    @Query('date') date: string,
    @Query('time') time: string,
  ) {
    if (!date || !time) {
      throw new HttpException(
        'Date and time are required (date=YYYY-MM-DD, time=HH:mm)',
        HttpStatus.BAD_REQUEST,
      );
    }
    return this.timeSlotsService.getOrdersBySlot(date, time);
  }

  @Post('book')
  async bookSlot(@Body() body: { date: string; time: string }) {
    if (!body.date || !body.time) {
      throw new HttpException(
        'Date and time are required',
        HttpStatus.BAD_REQUEST,
      );
    }

    const success = await this.timeSlotsService.bookSlot(body.date, body.time);
    if (!success) {
      throw new HttpException(
        'Time slot is full or disabled',
        HttpStatus.CONFLICT,
      );
    }

    return { success: true, message: 'Time slot booked successfully' };
  }

  @Patch(':id/active')
  async setActive(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { isActive: boolean },
  ) {
    if (typeof body.isActive !== 'boolean') {
      throw new HttpException(
        'isActive (boolean) is required',
        HttpStatus.BAD_REQUEST,
      );
    }
    const slot = await this.timeSlotsService.setSlotActive(id, body.isActive);
    return {
      success: true,
      message: body.isActive
        ? 'Time slot activated'
        : 'Time slot disabled',
      slot,
    };
  }
}
