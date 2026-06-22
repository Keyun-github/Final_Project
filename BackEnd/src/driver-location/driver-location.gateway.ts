import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { DriversService } from '../drivers/drivers.service.js';
import { OrdersService } from '../orders/orders.service.js';
import { StoreConfigService } from '../store-config/store-config.service.js';
import { getRouteWithORSAndFallback } from '../utils/openroute.util.js';

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  namespace: '/driver-location',
})
export class DriverLocationGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;
  constructor(
    private readonly driversService: DriversService,
    private readonly ordersService: OrdersService,
    private readonly storeConfigService: StoreConfigService,
  ) {}

  handleConnection(client: Socket) {
    console.log(`[WebSocket] Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`[WebSocket] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('register_driver')
  handleRegisterDriver(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { driverId: number },
  ) {
    client.join(`driver_${data.driverId}`);
    console.log(`[WebSocket] Driver ${data.driverId} registered for location updates`);
    return { event: 'registered', driverId: data.driverId };
  }

  @SubscribeMessage('driver_location_update')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { driverId: number; lat: number; lng: number; orderId?: number; status?: string; snappedLat?: number; snappedLng?: number },
  ) {
    try {
      await this.driversService.updateLocation(data.driverId, data.lat, data.lng);

      this.server.to('admin_room').emit('driver_location_changed', {
        driverId: data.driverId,
        lat: data.lat,
        lng: data.lng,
        timestamp: new Date().toISOString(),
      });

      if (data.orderId) {
        this.server.to(`order_${data.orderId}`).emit('driver_location_changed', {
          driverId: data.driverId,
          lat: data.lat,
          lng: data.lng,
          timestamp: new Date().toISOString(),
        });
        console.log(`[WebSocket] Broadcast to order_${data.orderId}: driver ${data.driverId} at ${data.lat}, ${data.lng}`);

        // Compute and emit a fresh route so customer/driver UIs can re-render the
        // polyline without an extra REST call.
        const order = await this.ordersService.findOne(data.orderId);
        if (order) {
          try {
            // Use client-provided snapped coords if available, else the driver's
            // current location we just persisted.
            const driverLat = data.snappedLat ?? data.lat;
            const driverLng = data.snappedLng ?? data.lng;
            const orderStatus = data.status || order.status;

            const source: [number, number] = [driverLng, driverLat];
            const storeConfig = await this.storeConfigService.getConfig();
            const storeLat = storeConfig.lat;
            const storeLng = storeConfig.lng;
            const destLat = order.deliveryLat ?? 0;
            const destLng = order.deliveryLng ?? 0;

            let routeToStore: string | null = null;
            let routeToDestination: string | null = null;
            if (orderStatus === 'pickingUp') {
              routeToStore = await getRouteWithORSAndFallback(source, [
                storeLng,
                storeLat,
              ]);
            } else if (destLat && destLng) {
              routeToDestination = await getRouteWithORSAndFallback(source, [
                destLng,
                destLat,
              ]);
            }

            this.server.to(`order_${data.orderId}`).emit('route_update', {
              orderId: data.orderId,
              status: orderStatus,
              driverLat: data.lat,
              driverLng: data.lng,
              snappedDriverLat: data.snappedLat ?? null,
              snappedDriverLng: data.snappedLng ?? null,
              routeToStore,
              routeToDestination,
              timestamp: new Date().toISOString(),
            });
            console.log(
              `[WebSocket] route_update emitted to order_${data.orderId} (status=${orderStatus})`,
            );
          } catch (routeErr) {
            console.error('[WebSocket] route calc failed in gateway:', routeErr);
          }
        }
      }

      return { success: true };
    } catch (error) {
      console.error('[WebSocket] handleLocationUpdate error:', error);
      return { success: false, error: error.message };
    }
  }

  @SubscribeMessage('admin_subscribe')
  handleAdminSubscribe(@ConnectedSocket() client: Socket) {
    client.join('admin_room');
    console.log('[WebSocket] Admin subscribed to driver location updates');
    return { event: 'subscribed', room: 'admin_room' };
  }

  @SubscribeMessage('admin_unsubscribe')
  handleAdminUnsubscribe(@ConnectedSocket() client: Socket) {
    client.leave('admin_room');
    console.log('[WebSocket] Admin unsubscribed from driver location updates');
    return { event: 'unsubscribed', room: 'admin_room' };
  }

  @SubscribeMessage('driver_subscribe')
  handleDriverSubscribe(@ConnectedSocket() client: Socket) {
    client.join('drivers_room');
    console.log('[WebSocket] Driver subscribed to order notifications');
    return { event: 'subscribed', room: 'drivers_room' };
  }

  @SubscribeMessage('driver_unsubscribe')
  handleDriverUnsubscribe(@ConnectedSocket() client: Socket) {
    client.leave('drivers_room');
    console.log('[WebSocket] Driver unsubscribed from order notifications');
    return { event: 'unsubscribed', room: 'drivers_room' };
  }

  @SubscribeMessage('subscribe_order')
  handleSubscribeOrder(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { orderId: number },
  ) {
    client.join(`order_${data.orderId}`);
    console.log(`[WebSocket] Client ${client.id} subscribed to order_${data.orderId}`);
    return { event: 'subscribed', room: `order_${data.orderId}` };
  }

  @SubscribeMessage('unsubscribe_order')
  handleUnsubscribeOrder(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { orderId: number },
  ) {
    client.leave(`order_${data.orderId}`);
    console.log(`[WebSocket] Client ${client.id} unsubscribed to order_${data.orderId}`);
    return { event: 'unsubscribed', room: `order_${data.orderId}` };
  }

  broadcastNewOrder(orderData: {
    orderId: number;
    customerName: string;
    totalAmount: number;
    itemCount: number;
    deliveryAddress: string;
  }) {
    this.server.to('drivers_room').emit('new_order', {
      ...orderData,
      timestamp: new Date().toISOString(),
    });
    console.log('[WebSocket] Broadcasting new order to drivers:', orderData.orderId);
  }

  broadcastDriverLocation(driverId: number, lat: number, lng: number) {
    this.server.to('admin_room').emit('driver_location_changed', {
      driverId,
      lat,
      lng,
      timestamp: new Date().toISOString(),
    });
  }
}
