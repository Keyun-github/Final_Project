import {
  Controller,
  Get,
  Put,
  Post,
  Body,
  Headers,
} from '@nestjs/common';
import { StoreConfigService } from './store-config.service.js';

/**
 * PUT body for the "address-only" flow — the backend geocodes it
 * automatically via Nominatim. Admin doesn't need to know lat/lng.
 */
class ResolveAddressDto {
  address!: string;
}

/**
 * PUT body for the "explicit coordinates" flow — used when the admin
 * picked a location on the map and wants to override the geocoded
 * result, or when the address returned by reverse-geocoding is not
 * what they wanted.
 */
class UpdateCoordsDto {
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

  /**
   * Admin: address-only update. Backend geocodes via Nominatim.
   * Use this when the admin types an address and trusts the lookup.
   */
  @Put()
  async resolve(
    @Body() body: ResolveAddressDto,
    @Headers('x-admin-user') adminUser?: string,
  ) {
    return this.service.resolveAndUpdate(
      body.address,
      adminUser ?? 'admin',
    );
  }

  /**
   * Admin: explicit coordinates update. Use this when the admin
   * picked a location on the map and wants to override the geocoded
   * result, or fine-tune the address.
   */
  @Post('coords')
  async updateFromCoords(
    @Body() body: UpdateCoordsDto,
    @Headers('x-admin-user') adminUser?: string,
  ) {
    return this.service.updateFromCoords(
      body.address,
      body.lat,
      body.lng,
      adminUser ?? 'admin',
    );
  }

  /**
   * Admin: preview the geocoding result without persisting anything.
   * Useful for showing the resulting lat/lng + a nicer display name
   * in the UI before the user commits.
   */
  @Post('geocode')
  async geocode(@Body() body: ResolveAddressDto) {
    const result = await this.service.geocodeAddress(body.address);
    if (!result) {
      return { found: false };
    }
    return {
      found: true,
      lat: result.lat,
      lng: result.lng,
      displayName: result.displayName,
    };
  }

  /**
   * Admin: reverse-geocode lat/lng → display name (for the map picker
   * flow).
   */
  @Post('reverse-geocode')
  async reverseGeocode(@Body() body: { lat: number; lng: number }) {
    const displayName = await this.service.reverseGeocode(
      body.lat,
      body.lng,
    );
    if (!displayName) return { displayName: null };
    return { displayName };
  }
}