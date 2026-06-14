import { Module, forwardRef } from '@nestjs/common';
import { DriverLocationGateway } from './driver-location.gateway.js';
import { DriversModule } from '../drivers/drivers.module.js';
import { OrdersModule } from '../orders/orders.module.js';

@Module({
  imports: [forwardRef(() => DriversModule), forwardRef(() => OrdersModule)],
  providers: [DriverLocationGateway],
  exports: [DriverLocationGateway],
})
export class DriverLocationModule {}
