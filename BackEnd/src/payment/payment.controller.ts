import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  HttpCode,
  HttpStatus,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { PaymentService } from './payment.service.js';
import { OrdersService } from '../orders/orders.service.js';

class CreateSnapTokenDto {
  orderId: string;
  amount: number;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
}

@Controller('payment')
export class PaymentController {
  constructor(
    private readonly paymentService: PaymentService,
    @Inject(forwardRef(() => OrdersService))
    private readonly ordersService: OrdersService,
  ) {}

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

    // Persist the Midtrans transactionId on the order so we can verify
    // payment status when the customer returns to the app.
    const orderIdNum = parseInt(body.orderId, 10);
    if (!Number.isNaN(orderIdNum)) {
      try {
        await this.ordersService.updateTransactionId(
          orderIdNum,
          result.transactionId,
        );
      } catch (e) {
        console.error(
          '[PaymentController] Failed to save transactionId on order:',
          e instanceof Error ? e.message : String(e),
        );
      }
    }

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