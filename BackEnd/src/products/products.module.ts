import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from './product.entity.js';
import { ProductVariant } from './product-variant.entity.js';
import { ProductsService } from './products.service.js';
import { ProductsController } from './products.controller.js';
import { ProductsGateway } from './products.gateway.js';
import { Order } from '../orders/order.entity.js';
import { OrderItem } from '../orders/order-item.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Product, ProductVariant, Order, OrderItem])],
  controllers: [ProductsController],
  providers: [ProductsService, ProductsGateway],
  exports: [ProductsService],
})
export class ProductsModule {}
