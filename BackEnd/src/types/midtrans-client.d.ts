/**
 * Minimal type declarations for the `midtrans-client` package, which does not
 * ship its own .d.ts file. The declarations below cover only the surface that
 * `BackEnd/src/payment/payment.service.ts` actually uses.
 */
declare module 'midtrans-client' {
  export class Snap {
    constructor(config: {
      isProduction: boolean;
      serverKey: string | undefined;
      clientKey: string | undefined;
    });
    createTransactionToken(parameter: Record<string, unknown>): Promise<string>;
    createTransactionRedirectUrl(
      parameter: Record<string, unknown>,
    ): Promise<string>;
  }

  export class CoreApi {
    constructor(config: {
      isProduction: boolean;
      serverKey: string | undefined;
      clientKey: string | undefined;
    });
    transaction: {
      status(transactionId: string): Promise<{
        transaction_id: string;
        transaction_status: string;
        gross_amount: string;
      }>;
    };
  }
}
