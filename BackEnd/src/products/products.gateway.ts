import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  namespace: '/products',
})
export class ProductsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`[ProductsWS] Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`[ProductsWS] Client disconnected: ${client.id}`);
  }

  broadcastProductCreated(product: any) {
    console.log('[ProductsWS] Broadcasting product_created:', product.id);
    this.server.emit('product_created', {
      product,
      timestamp: new Date().toISOString(),
    });
  }

  broadcastProductUpdated(product: any) {
    console.log('[ProductsWS] Broadcasting product_updated:', product.id);
    this.server.emit('product_updated', {
      product,
      timestamp: new Date().toISOString(),
    });
  }

  broadcastProductDeleted(productId: number) {
    console.log('[ProductsWS] Broadcasting product_deleted:', productId);
    this.server.emit('product_deleted', {
      productId,
      timestamp: new Date().toISOString(),
    });
  }
}
