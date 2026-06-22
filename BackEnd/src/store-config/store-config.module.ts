import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StoreConfig } from './store-config.entity.js';
import { StoreConfigService } from './store-config.service.js';
import { StoreConfigController } from './store-config.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([StoreConfig])],
  controllers: [StoreConfigController],
  providers: [StoreConfigService],
  exports: [StoreConfigService],
})
export class StoreConfigModule {}