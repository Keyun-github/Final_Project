import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  HttpCode,
  HttpStatus,
  NotFoundException,
} from '@nestjs/common';
import { PaymentService } from './payment.service.js';

class CreateSnapTokenDto {
  orderId: string;
  amount: number;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
}

@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('snap-token')
  @HttpCode(HttpStatus.OK)
  async createSnapToken(@Body() body: any) {
    console.log('[PaymentController] Received body:', JSON.stringify(body));
    const result = await this.paymentService.createSnapToken(
      body.orderId,
      body.amount,
      {
        name: body.customerName,
        email: body.customerEmail,
        phone: body.customerPhone,
      },
    );
    return result;
  }

  @Post('notification')
  @HttpCode(HttpStatus.OK)
  async handleNotification(@Body() payload: any) {
    console.log('[PaymentController] Received Midtrans notification:', payload);
    const result = await this.paymentService.handleNotification(payload);
    return { status: 'ok', result };
  }

  @Get('status/:orderId')
  async checkStatus(@Param('orderId') orderId: string) {
    const result = await this.paymentService.checkTransactionStatus(orderId);
    if (!result) {
      throw new NotFoundException('Transaction not found');
    }
    return result;
  }
}