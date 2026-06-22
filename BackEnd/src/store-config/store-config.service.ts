import {
  Injectable,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StoreConfig } from './store-config.entity.js';

/**
 * Default values used when the singleton row has not been seeded yet
 * (matches the values that were previously hard-coded across the
 * codebase, so the system behaves identically on first boot).
 */
const DEFAULT_ADDRESS = 'Jl. Kedung Rukem IV / 55';
const DEFAULT_LAT = -7.2628478;
const DEFAULT_LNG = 112.7336368;

@Injectable()
export class StoreConfigService {
  private readonly logger = new Logger(StoreConfigService.name);

  constructor(
    @InjectRepository(StoreConfig)
    private readonly repo: Repository<StoreConfig>,
  ) {}

  /**
   * Returns the singleton store config. If the row does not exist
   * yet (first boot, fresh DB) it is created on the fly with the
   * legacy defaults so downstream code never sees null.
   */
  async getConfig(): Promise<StoreConfig> {
    let config = await this.repo.findOne({ where: { id: 1 } });
    if (!config) {
      this.logger.warn(
        'store_config row missing — inserting legacy defaults',
      );
      config = await this.repo.save(
        this.repo.create({
          id: 1,
          address: DEFAULT_ADDRESS,
          lat: DEFAULT_LAT,
          lng: DEFAULT_LNG,
          updatedBy: 'system',
        }),
      );
    }
    return config;
  }

  async updateConfig(
    address: string,
    lat: number,
    lng: number,
    updatedBy?: string,
  ): Promise<StoreConfig> {
    const cleanAddress = (address ?? '').trim();
    if (!cleanAddress) {
      throw new BadRequestException('Alamat tidak boleh kosong');
    }
    if (cleanAddress.length > 500) {
      throw new BadRequestException(
        'Alamat maksimal 500 karakter',
      );
    }
    if (
      typeof lat !== 'number' ||
      typeof lng !== 'number' ||
      Number.isNaN(lat) ||
      Number.isNaN(lng)
    ) {
      throw new BadRequestException('Latitude/longitude harus angka');
    }
    if (lat < -90 || lat > 90) {
      throw new BadRequestException(
        'Latitude harus di antara -90 dan 90',
      );
    }
    if (lng < -180 || lng > 180) {
      throw new BadRequestException(
        'Longitude harus di antara -180 dan 180',
      );
    }

    // Ensure the row exists (upsert).
    const existing = await this.repo.findOne({ where: { id: 1 } });
    if (existing) {
      existing.address = cleanAddress;
      existing.lat = lat;
      existing.lng = lng;
      if (updatedBy) existing.updatedBy = updatedBy;
      await this.repo.save(existing);
    } else {
      await this.repo.save(
        this.repo.create({
          id: 1,
          address: cleanAddress,
          lat,
          lng,
          updatedBy: updatedBy ?? null,
        }),
      );
    }

    this.logger.log(
      `Store config updated: "${cleanAddress}" (${lat}, ${lng}) by ${updatedBy ?? 'unknown'}`,
    );
    return this.getConfig();
  }
}