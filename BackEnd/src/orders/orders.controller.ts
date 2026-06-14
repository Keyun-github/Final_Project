import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  NotFoundException,
  BadRequestException,
  ParseIntPipe,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { OrdersService } from './orders.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { UpdateStatusDto } from './dto/update-status.dto.js';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get('stats')
  getStats() {
    return this.ordersService.getStats();
  }

  @Get()
  findAll() {
    return this.ordersService.findAll();
  }

  @Get('customer/:customerId')
  async findByCustomer(@Param('customerId', ParseIntPipe) customerId: number) {
    return this.ordersService.findByCustomer(customerId);
  }

  @Get('driver/:driverId')
  async findByDriver(@Param('driverId', ParseIntPipe) driverId: number) {
    return this.ordersService.findByDriver(driverId);
  }

  @Get('unassigned')
  async findUnassigned() {
    return this.ordersService.findUnassigned();
  }

  @Get('pending')
  async findPending() {
    return this.ordersService.findPending();
  }

  @Get(':id/routes')
  async getOrderRoutes(@Param('id', ParseIntPipe) id: number) {
    const routes = await this.ordersService.getOrderRoutes(id);
    return routes;
  }

  @Patch(':id/delivery-coords')
  async updateDeliveryCoords(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { lat: number; lng: number; status?: string; snappedLat?: number; snappedLng?: number },
  ) {
    const result = await this.ordersService.updateDeliveryCoords(
      id,
      body.lat,
      body.lng,
      body.status,
      body.snappedLat,
      body.snappedLng,
    );
    if (!result) throw new NotFoundException('Order not found');
    return result;
  }

  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const order = await this.ordersService.findOne(id);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  @Post()
  async create(@Body() dto: CreateOrderDto) {
    try {
      return await this.ordersService.create(dto);
    } catch (error) {
      throw new BadRequestException({
        message: error.message,
        statusCode: 400,
      });
    }
  }

  @Patch(':id/status')
  async updateStatus(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateStatusDto,
  ) {
    const order = await this.ordersService.updateStatus(id, dto.status);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  @Patch(':id/confirm-payment')
  async confirmPayment(@Param('id', ParseIntPipe) id: number) {
    const order = await this.ordersService.confirmPayment(id);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  @Patch(':id/assign')
  async assignDriver(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { driverId: number },
  ) {
    const order = await this.ordersService.assignDriver(id, body.driverId);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  @Patch(':id/accept')
  async acceptOrder(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { driverId: number },
  ) {
    const order = await this.ordersService.acceptOrder(id, body.driverId);
    if (!order) throw new NotFoundException('Order not found or already accepted');
    return order;
  }

  @Post(':id/photo')
  @UseInterceptors(
    FileInterceptor('photo', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, cb) => {
          const random = Date.now() + Math.random() * 1000;
          cb(null, `${random}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  async uploadPhoto(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
  ) {
    // Save only the filename, not the full path
    const filename = file.filename;
    const order = await this.ordersService.updateDeliveryPhoto(id, filename);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  // New endpoint for Supabase URL
  @Patch(':id/photo-url')
  async uploadPhotoUrl(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { photoUrl: string },
  ) {
    const order = await this.ordersService.updateDeliveryPhoto(id, body.photoUrl);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }
}
