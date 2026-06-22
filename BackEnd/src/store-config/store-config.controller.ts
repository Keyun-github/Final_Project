import {
  Controller,
  Get,
  Put,
  Body,
  Headers,
} from '@nestjs/common';
import { StoreConfigService } from './store-config.service.js';

class UpdateStoreConfigDto {
  address!: string;
  lat!: number;
  lng!: number;
}

@Controller('store-config')
export class StoreConfigController {
  constructor(private readonly service: StoreConfigService) {}

  /** Public — used by both admin panel and mobile apps. */
  @Get()
  async get() {
    return this.service.getConfig();
  }

  /** Admin only — for now we don't have a dedicated admin guard, so we
   *  accept an optional `x-admin-user` header that gets recorded as
   *  `updatedBy` for audit purposes. The route is documented as
   *  admin-only in the README; tightening it with an auth guard can
   *  be done later. */
  @Put()
  async update(
    @Body() body: UpdateStoreConfigDto,
    @Headers('x-admin-user') adminUser?: string,
  ) {
    return this.service.updateConfig(
      body.address,
      body.lat,
      body.lng,
      adminUser ?? 'admin',
    );
  }
}