import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as midtransClient from 'midtrans-client';

@Injectable()
export class PaymentService {
  private snap: midtransClient.Snap;
  private core: midtransClient.CoreApi;

  constructor(private configService: ConfigService) {
    const isProduction = this.configService.get('MIDTRANS_IS_PRODUCTION') === 'true';

    const midtransConfig = {
      isProduction,
      serverKey: this.configService.get('MIDTRANS_SERVER_KEY'),
      clientKey: this.configService.get('MIDTRANS_CLIENT_KEY'),
    };

    this.snap = new midtransClient.Snap(midtransConfig);
    this.core = new midtransClient.CoreApi(midtransConfig);
  }

  async createSnapToken(orderId: string, amount: number, customerDetails: {
    name: string;
    email: string;
    phone: string;
  }): Promise<{ token: string; redirectUrl: string; transactionId: string }> {
    const orderIdStr = `ORDER-${orderId}-${Date.now()}`;

    console.log('[PaymentService] Input params:', {
      orderId,
      amount,
      typeOfAmount: typeof amount,
      customerDetails,
    });

    // Midtrans requires gross_amount as a positive integer
    const grossAmount = Number(amount);

    console.log('[PaymentService] Converted grossAmount:', grossAmount);

    const parameter = {
      transaction_details: {
        order_id: orderIdStr,
        gross_amount: grossAmount,
      },
      customer_details: {
        customer_name: customerDetails.name,
        customer_email: customerDetails.email,
        customer_phone: customerDetails.phone,
      },
    };

    console.log('[PaymentService] Final parameter:', JSON.stringify(parameter));

    const token = await this.snap.createTransactionToken(parameter);
    const redirectUrl = await this.snap.createTransactionRedirectUrl(parameter);

    return {
      token,
      redirectUrl,
      transactionId: orderIdStr,
    };
  }

  async handleNotification(payload: {
    order_id: string;
    transaction_id: string;
    transaction_status: string;
    status_code: string;
    gross_amount: string;
    signature_key?: string;
  }): Promise<{
    orderId: string;
    status: string;
    transactionId: string;
    amount: number;
  }> {
    const serverKey = this.configService.get('MIDTRANS_SERVER_KEY') || '';

    const status = this.mapTransactionStatus(payload.transaction_status);

    return {
      orderId: payload.order_id,
      status,
      transactionId: payload.transaction_id,
      amount: parseFloat(payload.gross_amount),
    };
  }

  async checkTransactionStatus(orderId: string): Promise<{
    status: string;
    transactionId: string;
    grossAmount: number;
  } | null> {
    try {
      const status = await this.core.transaction.status(orderId);
      return {
        status: this.mapTransactionStatus(status.transaction_status),
        transactionId: status.transaction_id,
        grossAmount: parseFloat(status.gross_amount),
      };
    } catch (error) {
      console.error('[PaymentService] Error checking transaction status:', error);
      return null;
    }
  }

  private mapTransactionStatus(status: string): string {
    const statusMap: Record<string, string> = {
      'capture': 'paid',
      'settlement': 'paid',
      'pending': 'pending',
      'deny': 'failed',
      'cancel': 'failed',
      'expire': 'failed',
      'refund': 'refunded',
      'partial_refund': 'refunded',
      'challenge': 'challenge',
    };

    return statusMap[status] || status;
  }
}