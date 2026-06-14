import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Driver } from './driver.entity.js';
import { DriversService } from './drivers.service.js';
import { DriversController } from './drivers.controller.js';
import { DriverLocationModule } from '../driver-location/driver-location.module.js';

@Module({
  imports: [TypeOrmModule.forFeature([Driver]), DriverLocationModule],
  controllers: [DriversController],
  providers: [DriversService],
  exports: [DriversService, DriverLocationModule],
})
export class DriversModule {}
