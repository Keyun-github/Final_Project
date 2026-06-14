import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Driver } from './driver.entity.js';
import { CreateDriverDto } from './dto/create-driver.dto.js';
import { haversineDistance } from '../utils/distance.util.js';

@Injectable()
export class DriversService {
  constructor(
    @InjectRepository(Driver)
    private readonly driverRepo: Repository<Driver>,
  ) {}

  async findAll(): Promise<Driver[]> {
    return this.driverRepo.find({ order: { id: 'ASC' } });
  }

  async findOne(id: number): Promise<Driver | null> {
    return this.driverRepo.findOne({ where: { id } });
  }

  async create(dto: CreateDriverDto): Promise<Driver> {
    const driver = this.driverRepo.create({
      username: dto.username,
      password: dto.password,
      name: dto.name,
      phone: dto.phone ?? '',
      isActive: dto.isActive ?? true,
    });
    return this.driverRepo.save(driver);
  }

  async update(
    id: number,
    data: Partial<CreateDriverDto>,
  ): Promise<Driver | null> {
    const driver = await this.driverRepo.findOne({ where: { id } });
    if (!driver) return null;

    if (data.username !== undefined) driver.username = data.username;
    if (data.password !== undefined) driver.password = data.password;
    if (data.name !== undefined) driver.name = data.name;
    if (data.phone !== undefined) driver.phone = data.phone;
    if (data.isActive !== undefined) driver.isActive = data.isActive;
    if (data.isAvailable !== undefined) driver.isAvailable = data.isAvailable;

    return this.driverRepo.save(driver);
  }

  async remove(id: number): Promise<boolean> {
    const result = await this.driverRepo.delete(id);
    return (result.affected ?? 0) > 0;
  }

  async login(username: string, password: string): Promise<Driver | null> {
    return this.driverRepo.findOne({
      where: { username, password, isActive: true },
    });
  }

  async updatePassword(
    id: number,
    currentPassword: string,
    newPassword: string,
  ): Promise<boolean> {
    const driver = await this.driverRepo.findOne({ where: { id } });
    if (!driver || driver.password !== currentPassword) {
      return false;
    }
    driver.password = newPassword;
    await this.driverRepo.save(driver);
    return true;
  }

  async updateVehicle(
    id: number,
    data: { vehicleBrand: string; vehiclePlate: string; vehicleColor: string },
  ): Promise<Driver | null> {
    const driver = await this.driverRepo.findOne({ where: { id } });
    if (!driver) return null;

    driver.vehicleBrand = data.vehicleBrand;
    driver.vehiclePlate = data.vehiclePlate;
    driver.vehicleColor = data.vehicleColor;
    driver.vehicleType = 'motorcycle';

    return this.driverRepo.save(driver);
  }

  async seed(): Promise<void> {
    const count = await this.driverRepo.count();
    if (count > 0) return;

    // Seed default demo drivers
    await this.create({
      username: 'driver1',
      password: 'driver1',
      name: 'Ahmad Kurniawan',
      phone: '081234567890',
    });
    await this.create({
      username: 'driver2',
      password: 'driver2',
      name: 'Bambang Suryadi',
      phone: '081298765432',
    });
  }

  async updateLocation(
    id: number,
    lat: number,
    lng: number,
  ): Promise<Driver | null> {
    const driver = await this.driverRepo.findOne({ where: { id } });
    if (!driver) return null;

    driver.currentLat = lat;
    driver.currentLng = lng;
    return this.driverRepo.save(driver);
  }

  async findAvailableDrivers(): Promise<Driver[]> {
    return this.driverRepo.find({
      where: { isActive: true, isAvailable: true },
      order: { id: 'ASC' },
    });
  }

  async findNearestAvailableDriver(
    storeLat: number,
    storeLng: number,
  ): Promise<Driver | null> {
    const availableDrivers = await this.findAvailableDrivers();

    if (availableDrivers.length === 0) {
      return null;
    }

    let nearestDriver: Driver | null = null;
    let shortestDistance: number = Infinity;

    for (const driver of availableDrivers) {
      if (driver.currentLat === null || driver.currentLng === null) {
        nearestDriver = driver;
        break;
      }

      const distance = haversineDistance(
        driver.currentLat,
        driver.currentLng,
        storeLat,
        storeLng,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestDriver = driver;
      }
    }

    return nearestDriver;
  }
}
