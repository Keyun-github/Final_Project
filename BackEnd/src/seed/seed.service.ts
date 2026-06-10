import { Injectable, OnModuleInit } from '@nestjs/common';
import { ProductsService } from '../products/products.service.js';
import { DriversService } from '../drivers/drivers.service.js';

@Injectable()
export class SeedService implements OnModuleInit {
  constructor(
    private readonly productsService: ProductsService,
    private readonly driversService: DriversService,
  ) {}

  async onModuleInit() {
    // Products are no longer auto-seeded. Admin must add products manually
    // via the admin panel Stock page. Existing dummy data should be cleared
    // by running BackEnd/scripts/clear-dummy-products.sql before restart.
    // await this.productsService.seed();
    await this.driversService.seed();
  }
}
