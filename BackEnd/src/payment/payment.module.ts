import { forwardRef, Module } from '@nestjs/common';
import { PaymentController } from './payment.controller.js';
import { PaymentService } from './payment.service.js';
import { OrdersModule } from '../orders/orders.module.js';

@Module({
  imports: [forwardRef(() => OrdersModule)],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}