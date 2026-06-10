import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  NotFoundException,
  ParseIntPipe,
} from '@nestjs/common';
import { CustomersService } from './customers.service.js';
import {
  CreateCustomerDto,
  LoginCustomerDto,
} from './dto/create-customer.dto.js';

@Controller('customers')
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Post('register')
  async register(@Body() dto: CreateCustomerDto) {
    const customer = await this.customersService.register(dto);
    return {
      id: customer.id,
      name: customer.name,
      username: customer.username,
      phone: customer.phone,
      address: customer.address,
    };
  }

  @Post('login')
  async login(@Body() dto: LoginCustomerDto) {
    const customer = await this.customersService.login(dto);
    return {
      id: customer.id,
      name: customer.name,
      username: customer.username,
      phone: customer.phone,
      address: customer.address,
    };
  }

  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const customer = await this.customersService.findById(id);
    if (!customer) throw new NotFoundException('Customer not found');
    return {
      id: customer.id,
      name: customer.name,
      username: customer.username,
      phone: customer.phone,
      address: customer.address,
    };
  }

  @Get(':id/orders')
  async getOrders(@Param('id', ParseIntPipe) id: number) {
    const customer = await this.customersService.getOrders(id);
    if (!customer) throw new NotFoundException('Customer not found');
    return customer.orders || [];
  }

  @Put(':id/address')
  async updateAddress(
    @Param('id', ParseIntPipe) id: number,
    @Body('address') address: string,
  ) {
    const customer = await this.customersService.updateAddress(id, address);
    if (!customer) throw new NotFoundException('Customer not found');
    return { success: true };
  }
}
