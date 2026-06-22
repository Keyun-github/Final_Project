import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { ProductsModule } from './products/products.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { DriversModule } from './drivers/drivers.module.js';
import { TimeSlotsModule } from './time-slots/time-slots.module.js';
import { CustomersModule } from './customers/customers.module.js';
import { PaymentModule } from './payment/payment.module.js';
import { SeedService } from './seed/seed.service.js';
import { DriverLocationModule } from './driver-location/driver-location.module.js';
import { ChatModule } from './chat/chat.module.js';
import { SupabaseModule } from './supabase/supabase.module.js';
import { UnitsModule } from './units/units.module.js';
import { StoreConfigModule } from './store-config/store-config.module.js';
import { Product } from './products/product.entity.js';
import { ProductVariant } from './products/product-variant.entity.js';
import { Order } from './orders/order.entity.js';
import { OrderItem } from './orders/order-item.entity.js';
import { Driver } from './drivers/driver.entity.js';
import { TimeSlot } from './time-slots/time-slot.entity.js';
import { Customer } from './customers/customer.entity.js';
import { Conversation } from './chat/entities/conversation.entity.js';
import { Message } from './chat/entities/message.entity.js';
import { Unit } from './units/units.entity.js';
import { StoreConfig } from './store-config/store-config.entity.js';

const dbHost = process.env.DB_HOST;
const dbPort = parseInt(process.env.DB_PORT || '5432', 10);
const dbUsername = process.env.DB_USERNAME || 'postgres';
const dbPassword = process.env.DB_PASSWORD;
const dbName = process.env.DB_NAME || 'kelun_db';

if (!dbHost) {
  throw new Error('DB_HOST environment variable is required');
}
if (!dbPassword) {
  throw new Error('DB_PASSWORD environment variable is required');
}

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: dbHost,
      port: dbPort,
      username: dbUsername,
      password: dbPassword,
      database: dbName,
      entities: [
        Product,
        ProductVariant,
        Order,
        OrderItem,
        Driver,
        TimeSlot,
        Customer,
        Conversation,
        Message,
        Unit,
        StoreConfig,
      ],
      synchronize: false,
      logging: process.env.NODE_ENV !== 'production',
    }),
    ProductsModule,
    OrdersModule,
    DriversModule,
    TimeSlotsModule,
    CustomersModule,
    PaymentModule,
    DriverLocationModule,
    ChatModule,
    SupabaseModule,
    UnitsModule,
    StoreConfigModule,
  ],
  controllers: [AppController],
  providers: [AppService, SeedService],
})
export class AppModule {}