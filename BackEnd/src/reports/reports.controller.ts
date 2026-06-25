import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { ReportsService } from './reports.service.js';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('driver/:driverId')
  async getDriverReport(
    @Param('driverId', ParseIntPipe) driverId: number,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.reportsService.getDriverReport(driverId, startDate, endDate);
  }

  @Get('drivers')
  async getAllDriversReport(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.reportsService.getAllDriversReport(startDate, endDate);
  }
}