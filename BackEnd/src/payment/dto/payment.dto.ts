import {
  IsString,
  IsNumber,
  IsEmail,
  IsOptional,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Nested customer details. Optional today, but ready for when the mobile
 * app moves away from the flat legacy fields.
 */
export class CustomerDetailsDto {
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  phone: string;
}

/**
 * Body for POST /payment/snap-token.
 * The customer app currently sends the legacy flat fields (customerName /
 * customerEmail / customerPhone). Both shapes are accepted to stay
 * backward-compatible — see the controller for the merge logic.
 */
export class CreateSnapTokenDto {
  @IsString()
  orderId: string;

  @IsNumber()
  amount: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => CustomerDetailsDto)
  customerDetails?: CustomerDetailsDto;

  // Legacy flat fields (kept optional so older clients still work).
  @IsOptional()
  @IsString()
  customerName?: string;

  @IsOptional()
  @IsEmail()
  customerEmail?: string;

  @IsOptional()
  @IsString()
  customerPhone?: string;
}

/**
 * Body for POST /payment/notification.
 * Midtrans sends a flat payload with these fields. We accept the keys
 * exactly as Midtrans posts them (snake_case) and let the service
 * normalize them.
 */
export class MidtransNotificationDto {
  @IsString()
  order_id: string;

  @IsString()
  transaction_id: string;

  @IsString()
  transaction_status: string;

  @IsString()
  status_code: string;

  @IsString()
  gross_amount: string;

  @IsOptional()
  @IsString()
  signature_key?: string;

  @IsOptional()
  @IsString()
  fraud_status?: string;

  @IsOptional()
  @IsString()
  payment_type?: string;

  @IsOptional()
  @IsString()
  transaction_time?: string;
}
