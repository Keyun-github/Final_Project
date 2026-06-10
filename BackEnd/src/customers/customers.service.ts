import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Customer } from './customer.entity.js';
import {
  CreateCustomerDto,
  LoginCustomerDto,
} from './dto/create-customer.dto.js';

@Injectable()
export class CustomersService {
  constructor(
    @InjectRepository(Customer)
    private readonly customerRepo: Repository<Customer>,
  ) {}

  async register(dto: CreateCustomerDto): Promise<Customer> {
    // Check if phone already exists
    const existingPhone = await this.customerRepo.findOne({
      where: { phone: dto.phone },
    });
    if (existingPhone) {
      throw new ConflictException('Nomor telepon sudah terdaftar');
    }

    // Check if username already exists
    const existingUsername = await this.customerRepo.findOne({
      where: { username: dto.username },
    });
    if (existingUsername) {
      throw new ConflictException('Username sudah digunakan');
    }

    const customer = this.customerRepo.create({
      name: dto.name,
      username: dto.username,
      phone: dto.phone,
      password: dto.password,
      address: dto.address || '',
    });

    return this.customerRepo.save(customer);
  }

  async login(dto: LoginCustomerDto): Promise<Customer> {
    const customer = await this.customerRepo.findOne({
      where: [
        { phone: dto.usernameOrPhone },
        { username: dto.usernameOrPhone },
      ],
    });

    if (!customer || customer.password !== dto.password) {
      throw new UnauthorizedException('Username/nomor telepon atau password salah');
    }

    return customer;
  }

  async findById(id: number): Promise<Customer | null> {
    return this.customerRepo.findOne({ where: { id } });
  }

  async updateAddress(id: number, address: string): Promise<Customer | null> {
    const customer = await this.customerRepo.findOne({ where: { id } });
    if (!customer) return null;

    customer.address = address;
    return this.customerRepo.save(customer);
  }

  async getOrders(customerId: number): Promise<Customer | null> {
    return this.customerRepo.findOne({
      where: { id: customerId },
      relations: ['orders', 'orders.items'],
    });
  }
}
