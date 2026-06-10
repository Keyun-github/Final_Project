import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from './order.entity.js';
import { OrderItem } from './order-item.entity.js';
import { Product } from '../products/product.entity.js';
import { Driver } from '../drivers/driver.entity.js';
import { DriversModule } from '../drivers/drivers.module.js';
import { OrdersService } from './orders.service.js';
import { OrdersController } from './orders.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([Order, OrderItem, Product, Driver]), DriversModule],
  controllers: [OrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
