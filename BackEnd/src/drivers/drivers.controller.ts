import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  NotFoundException,
  UnauthorizedException,
  ParseIntPipe,
} from '@nestjs/common';
import { DriversService } from './drivers.service.js';
import { CreateDriverDto, LoginDriverDto } from './dto/create-driver.dto.js';

@Controller('drivers')
export class DriversController {
  constructor(private readonly driversService: DriversService) {}

  @Get()
  findAll() {
    return this.driversService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const driver = await this.driversService.findOne(id);
    if (!driver) throw new NotFoundException('Driver not found');
    return driver;
  }

  @Post()
  create(@Body() dto: CreateDriverDto) {
    return this.driversService.create(dto);
  }

  @Put(':id')
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Record<string, any>,
  ) {
    const driver = await this.driversService.update(id, body);
    if (!driver) throw new NotFoundException('Driver not found');
    return driver;
  }

  @Delete(':id')
  async remove(@Param('id', ParseIntPipe) id: number) {
    const deleted = await this.driversService.remove(id);
    if (!deleted) throw new NotFoundException('Driver not found');
    return { message: 'Driver deleted' };
  }

  @Post('login')
  async login(@Body() dto: LoginDriverDto) {
    const driver = await this.driversService.login(dto.username, dto.password);
    if (!driver) {
      throw new UnauthorizedException('Username atau password salah');
    }
    return { id: driver.id, name: driver.name, username: driver.username };
  }

  @Put(':id/password')
  async updatePassword(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { currentPassword: string; newPassword: string },
  ) {
    const success = await this.driversService.updatePassword(
      id,
      body.currentPassword,
      body.newPassword,
    );
    if (!success) {
      throw new UnauthorizedException('Password saat ini salah');
    }
    return { message: 'Password berhasil diubah' };
  }

  @Put(':id/vehicle')
  async updateVehicle(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { vehicleBrand: string; vehiclePlate: string; vehicleColor: string },
  ) {
    const driver = await this.driversService.updateVehicle(id, body);
    if (!driver) throw new NotFoundException('Driver not found');
    return driver;
  }

  @Put(':id/location')
  async updateLocation(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { lat: number; lng: number },
  ) {
    const driver = await this.driversService.updateLocation(id, body.lat, body.lng);
    if (!driver) throw new NotFoundException('Driver not found');
    return { message: 'Location updated', lat: body.lat, lng: body.lng };
  }

  @Get('available')
  findAvailable() {
    return this.driversService.findAvailableDrivers();
  }
}
