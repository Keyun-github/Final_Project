import { Module, forwardRef } from '@nestjs/common';
import { DriverLocationGateway } from './driver-location.gateway.js';
import { DriversModule } from '../drivers/drivers.module.js';
import { OrdersModule } from '../orders/orders.module.js';
import { StoreConfigModule } from '../store-config/store-config.module.js';

@Module({
  imports: [
    forwardRef(() => DriversModule),
    forwardRef(() => OrdersModule),
    StoreConfigModule,
  ],
  providers: [DriverLocationGateway],
  exports: [DriverLocationGateway],
})
export class DriverLocationModule {}
