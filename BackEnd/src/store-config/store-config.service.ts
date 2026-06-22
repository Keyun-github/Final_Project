import {
  Injectable,
  Logger,
  BadRequestException,
  ServiceUnavailableException,
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

  /**
   * Geocode a free-form address into (lat, lng) using Nominatim
   * (OpenStreetMap). Returns null when nothing is found. Used by the
   * admin panel so the operator doesn't have to look up coordinates by
   * hand.
   */
  async geocodeAddress(
    address: string,
  ): Promise<{ lat: number; lng: number; displayName: string } | null> {
    const cleanAddress = (address ?? '').trim();
    if (!cleanAddress) return null;

    const url =
      `https://nominatim.openstreetmap.org/search?format=json&limit=1` +
      `&countrycodes=id&q=${encodeURIComponent(cleanAddress)}`;

    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'KelunApp/1.0 (admin-store-config)',
          'Accept-Language': 'id',
        },
      });
      if (!response.ok) {
        this.logger.warn(
          `Nominatim search returned ${response.status} for "${cleanAddress}"`,
        );
        return null;
      }
      const results = (await response.json()) as Array<{
        lat: string;
        lon: string;
        display_name: string;
      }>;
      if (!results.length) return null;
      const top = results[0];
      return {
        lat: parseFloat(top.lat),
        lng: parseFloat(top.lon),
        displayName: top.display_name,
      };
    } catch (e) {
      this.logger.error(
        `Nominatim search failed: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
      return null;
    }
  }

  /**
   * Reverse-geocode (lat, lng) into a display address using Nominatim.
   * Used when the admin clicks / drags the map marker to confirm the
   * location.
   */
  async reverseGeocode(
    lat: number,
    lng: number,
  ): Promise<string | null> {
    if (
      typeof lat !== 'number' ||
      typeof lng !== 'number' ||
      Number.isNaN(lat) ||
      Number.isNaN(lng)
    ) {
      return null;
    }
    const url =
      `https://nominatim.openstreetmap.org/reverse?format=json&zoom=18` +
      `&lat=${lat}&lon=${lng}`;

    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'KelunApp/1.0 (admin-store-config)',
          'Accept-Language': 'id',
        },
      });
      if (!response.ok) return null;
      const data = (await response.json()) as { display_name?: string };
      return data.display_name ?? null;
    } catch (e) {
      this.logger.error(
        `Nominatim reverse failed: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
      return null;
    }
  }

  /**
   * Convenience method for the admin panel: take a free-form address,
   * geocode it, and persist the result. Throws when the address cannot
   * be resolved.
   */
  async resolveAndUpdate(
    address: string,
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

    const coords = await this.geocodeAddress(cleanAddress);
    if (!coords) {
      throw new BadRequestException(
        `Tidak bisa menemukan koordinat untuk "${cleanAddress}". Coba alamat lebih spesifik (mis. tambahkan kelurahan, kecamatan, kota).`,
      );
    }

    const updated = await this.updateConfig(
      cleanAddress,
      coords.lat,
      coords.lng,
      updatedBy,
    );

    this.logger.log(
      `Store config geocoded & updated: "${cleanAddress}" → (${coords.lat}, ${coords.lng}) by ${updatedBy ?? 'unknown'}`,
    );
    return updated;
  }

  /**
   * Update config when the admin provided explicit lat/lng (e.g. by
   * clicking the map). We still ask Nominatim for a nicer display
   * address when possible, but we always keep the address the admin
   * typed — the admin knows best.
   */
  async updateFromCoords(
    address: string,
    lat: number,
    lng: number,
    updatedBy?: string,
  ): Promise<StoreConfig> {
    return this.updateConfig(address, lat, lng, updatedBy);
  }
}