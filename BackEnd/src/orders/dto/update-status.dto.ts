import { IsString, IsIn } from 'class-validator';
import { OrderStatus } from '../order.entity.js';

export class UpdateStatusDto {
  @IsString()
  @IsIn(Object.values(OrderStatus))
  status!: OrderStatus;}
