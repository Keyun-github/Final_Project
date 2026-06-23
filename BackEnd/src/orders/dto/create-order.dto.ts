import {
  IsString,
  IsNumber,
  IsOptional,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateOrderItemDto {
  @IsString()
  productName!: string;
  @IsOptional()
  @IsString()
  unitName?: string;

  @IsNumber()
  unitPrice!: number;
  @IsOptional()
  @IsNumber()
  quantity?: number;
}

export class CreateOrderDto {
  @IsOptional()
  @IsNumber()
  customerId?: number;

  @IsString()
  customerName!: string;
  @IsOptional()
  @IsString()
  customerPhone?: string;

  @IsOptional()
  @IsString()
  pickupAddress?: string;

  @IsOptional()
  @IsString()
  deliveryAddress?: string;

  @IsNumber()
  totalAmount!: number;
  @IsOptional()
  @IsString()
  paymentMethod?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items!: CreateOrderItemDto[];

  @IsOptional()
  @IsString()
  deliveryDate?: string;

  @IsOptional()
  @IsString()
  deliveryTime?: string;}
