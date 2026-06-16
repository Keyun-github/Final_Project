import { Injectable, Inject, forwardRef, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Order, OrderStatus } from './order.entity.js';
import { OrderItem } from './order-item.entity.js';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { Product } from '../products/product.entity.js';
import { ProductVariant } from '../products/product-variant.entity.js';
import { DriversService } from '../drivers/drivers.service.js';
import { DriverLocationGateway } from '../driver-location/driver-location.gateway.js';
import { PaymentService } from '../payment/payment.service.js';
import { getRouteWithORSAndFallback, RouteResult } from '../utils/openroute.util.js';
import { geocodeAddress } from '../utils/nominatim.util.js';
import { snapToRoadOSRM } from '../utils/osrm.util.js';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly itemRepo: Repository<OrderItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(ProductVariant)
    private readonly variantRepo: Repository<ProductVariant>,
    private readonly driversService: DriversService,
    @Inject(forwardRef(() => DriverLocationGateway))
    private readonly locationGateway: DriverLocationGateway,
    private readonly paymentService: PaymentService,
  ) {}

  async findAll(): Promise<Order[]> {
    return this.orderRepo.find({ 
      relations: ['driver'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: number): Promise<Order | null> {
    return this.orderRepo.findOne({
      where: { id },
      relations: ['items', 'driver'],
      cache: false,
    });
  }

  /**
   * Save the Midtrans transactionId on the order right after a Snap token is
   * created. Used by PaymentController to link the order to the Midtrans
   * transaction for later status verification.
   */
  async updateTransactionId(
    orderId: number,
    transactionId: string,
  ): Promise<void> {
    await this.orderRepo.update(orderId, { transactionId });
  }

  async create(dto: CreateOrderDto): Promise<Order> {
    // Check if this is a Midtrans payment
    const isMidtrans = dto.paymentMethod === 'Midtrans' || dto.paymentMethod === 'midtrans';

    // If Midtrans, create order with PENDING_PAYMENT status (stock not deducted yet)
    // If COD or other, create order with PENDING status (stock deducted immediately)
    const initialStatus = isMidtrans ? OrderStatus.PENDING_PAYMENT : OrderStatus.PENDING;

    // 1. Validate stock for each item (only for non-Midtrans payments)
    if (!isMidtrans) {
      for (const item of dto.items) {
        const product = await this.productRepo.findOne({
          where: { name: item.productName },
          relations: ['variants'],
        });

        if (!product) {
          throw new Error(`Produk "${item.productName}" tidak ditemukan`);
        }

        const requestedQty = item.quantity ?? 1;
        const variant = this.findVariantForItem(product, item);

        // Prefer the per-variant stock when a unit is specified. Fall back to
        // the legacy products.stock for products without variants.
        const available = variant ? variant.stock : product.stock;
        if (available < requestedQty) {
          const label = variant
            ? `${item.productName} (${variant.unitName})`
            : item.productName;
          throw new Error(
            `Stok tidak cukup untuk "${label}". Tersedia: ${available}, diminta: ${requestedQty}`,
          );
        }
      }
    }

    // 2. Create the order
    const order = this.orderRepo.create({
      customerId: dto.customerId ?? null,
      customerName: dto.customerName,
      customerPhone: dto.customerPhone ?? '',
      pickupAddress:
        dto.pickupAddress ?? 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
      deliveryAddress: dto.deliveryAddress ?? '',
      totalAmount: dto.totalAmount,
      paymentMethod: dto.paymentMethod ?? '',
      status: initialStatus,
      items: dto.items.map((i) => {
        const quantity = i.quantity ?? 1;
        const subtotal = i.unitPrice * quantity;
        return this.itemRepo.create({
          productName: i.productName,
          unitName: i.unitName ?? '',
          unitPrice: i.unitPrice,
          quantity,
          subtotal,
        });
      }),
    });

    const savedOrder = await this.orderRepo.save(order);

    // For non-Midtrans payments (COD), decrease stock and auto-dispatch immediately
    if (!isMidtrans) {
      // Store coordinates (default: Jakarta warehouse)
      const storeLat = -6.1389;
      const storeLng = 106.6297;

      // 3. Decrease stock for each product (per-variant when available)
      for (const item of dto.items) {
        const product = await this.productRepo.findOne({
          where: { name: item.productName },
          relations: ['variants'],
        });

        if (product) {
          const quantity = item.quantity ?? 1;
          const variant = this.findVariantForItem(product, item);
          if (variant) {
            variant.stock = Math.max(0, (variant.stock ?? 0) - quantity);
            // Keep products.stock in sync so legacy views/queries stay correct.
            product.stock = Math.max(0, (product.stock ?? 0) - quantity);
            await this.variantRepo.save(variant);
          } else {
            product.stock = Math.max(0, (product.stock ?? 0) - quantity);
          }
          product.sold = (product.sold ?? 0) + quantity;
          await this.productRepo.save(product);
        }
      }

      // 4. Auto-dispatch: find nearest available driver
      const nearestDriver = await this.driversService.findNearestAvailableDriver(storeLat, storeLng);
      if (nearestDriver) {
        savedOrder.driverId = nearestDriver.id;
        savedOrder.driver = nearestDriver;
        await this.driversService.update(nearestDriver.id, { isAvailable: false });
        await this.driversService.updateLocation(nearestDriver.id, nearestDriver.currentLat!, nearestDriver.currentLng!);
        await this.orderRepo.save(savedOrder);
      }
    }

    // Broadcast new order to all drivers via WebSocket
    if (savedOrder.status === OrderStatus.PENDING && !savedOrder.driverId) {
      this.locationGateway.broadcastNewOrder({
        orderId: savedOrder.id,
        customerName: savedOrder.customerName,
        totalAmount: Number(savedOrder.totalAmount),
        itemCount: savedOrder.items?.length || dto.items.length,
        deliveryAddress: savedOrder.deliveryAddress,
      });
    }

    return savedOrder;
  }

  async findByCustomer(customerId: number): Promise<Order[]> {
    return this.orderRepo.find({
      where: { customerId },
      relations: ['items', 'driver'],
      order: { createdAt: 'DESC' },
      cache: false,
    });
  }

  async findByDriver(driverId: number): Promise<Order[]> {
    return this.orderRepo.find({
      where: { driverId: driverId },
      relations: ['items', 'driver'],
      order: { createdAt: 'DESC' },
    });
  }

  async findUnassigned(): Promise<Order[]> {
    return this.orderRepo.find({
      where: { driverId: IsNull() },
      relations: ['items', 'driver'],
      order: { createdAt: 'DESC' },
    });
  }

  async findPending(): Promise<Order[]> {
    return this.orderRepo.find({
      where: { status: OrderStatus.PENDING, driverId: IsNull() },
      relations: ['items', 'driver'],
      order: { createdAt: 'DESC' },
    });
  }

  async updateStatus(id: number, status: OrderStatus): Promise<Order | null> {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: ['driver'],
    });
    if (!order) return null;
    order.status = status;
    await this.orderRepo.save(order);
    if ((status === OrderStatus.DELIVERED || status === OrderStatus.CANCELLED) && order.driverId) {
      await this.driversService.update(order.driverId, { isAvailable: true });
    }
    return order;
  }

  async confirmPayment(orderId: number): Promise<Order | null> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['items', 'driver'],
    });

    if (!order) {
      console.log('[confirmPayment] Order not found:', orderId);
      return null;
    }

    if (order.status !== OrderStatus.PENDING_PAYMENT) {
      console.log('[confirmPayment] Order is not in pending_payment status:', orderId, order.status);
      return order;
    }

    // Validate the transaction with Midtrans before confirming the order. This
    // stops the user from being able to "confirm" the payment by simply tapping
    // a button in the app when they actually cancelled / never paid in the
    // Midtrans sandbox (or production) page.
    const txId = (order as any).transactionId as string | undefined;
    if (!txId) {
      throw new BadRequestException(
        'Order ini tidak memiliki transactionId Midtrans',
      );
    }

    let midtransStatus: string | null = null;
    try {
      const result = await this.paymentService.checkTransactionStatus(txId);
      midtransStatus = result?.status ?? null;
    } catch (e) {
      console.error(
        '[confirmPayment] Failed to query Midtrans status:',
        e instanceof Error ? e.message : String(e),
      );
      throw new BadRequestException(
        'Tidak dapat memverifikasi status pembayaran ke Midtrans. Coba lagi.',
      );
    }

    console.log(
      `[confirmPayment] Midtrans status for tx=${txId} is "${midtransStatus}"`,
    );

    if (midtransStatus !== 'paid') {
      const pretty = midtransStatus ?? 'unknown';
      throw new BadRequestException(
        `Pembayaran belum selesai (status Midtrans: ${pretty}). Selesaikan pembayaran di Midtrans terlebih dahulu.`,
      );
    }

    // Update status to PENDING
    order.status = OrderStatus.PENDING;
    await this.orderRepo.save(order);

    // Get store coordinates (Surabaya)
    const storeLat = -7.2628478;
    const storeLng = 112.7336368;

    // Deduct stock for each item (per-variant when available)
    for (const item of order.items) {
      const product = await this.productRepo.findOne({
        where: { name: item.productName },
        relations: ['variants'],
      });

      if (product) {
        const variant = this.findVariantForItem(product, item);
        if (variant) {
          variant.stock = Math.max(0, (variant.stock ?? 0) - item.quantity);
          product.stock = Math.max(0, (product.stock ?? 0) - item.quantity);
          await this.variantRepo.save(variant);
        } else {
          product.stock = Math.max(0, (product.stock ?? 0) - item.quantity);
        }
        product.sold = (product.sold ?? 0) + item.quantity;
        await this.productRepo.save(product);
      }
    }

    // Auto-dispatch: find nearest available driver
    const nearestDriver = await this.driversService.findNearestAvailableDriver(storeLat, storeLng);
    if (nearestDriver) {
      order.driverId = nearestDriver.id;
      order.driver = nearestDriver;
      await this.driversService.update(nearestDriver.id, { isAvailable: false });
      await this.driversService.updateLocation(nearestDriver.id, nearestDriver.currentLat!, nearestDriver.currentLng!);
      await this.orderRepo.save(order);
    }

    console.log('[confirmPayment] Payment confirmed for order:', orderId);
    return order;
  }

  async assignDriver(id: number, driverId: number): Promise<Order | null> {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) return null;
    order.driverId = driverId;
    return this.orderRepo.save(order);
  }

  async acceptOrder(id: number, driverId: number): Promise<Order | null> {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) return null;
    if (order.status !== OrderStatus.PENDING) return null;
    order.driverId = driverId;
    order.status = OrderStatus.PICKING_UP;
    await this.orderRepo.save(order);
    await this.driversService.update(driverId, { isAvailable: false });
    return this.orderRepo.findOne({
      where: { id },
      relations: ['items', 'driver'],
    });
  }

  /**
   * Match an order item to a product variant by `unitName`. If the order item
   * has no unitName (legacy data) or no variant matches, return null — the
   * caller should then fall back to the legacy `products.stock` field.
   */
  private findVariantForItem(
    product: Product,
    item: { unitName?: string; productName: string },
  ): ProductVariant | null {
    if (!product.variants || product.variants.length === 0) return null;
    if (!item.unitName) return null;
    const wanted = item.unitName.toLowerCase().trim();
    return (
      product.variants.find(
        (v) => v.unitName.toLowerCase().trim() === wanted,
      ) ?? null
    );
  }

  async getStats(): Promise<{
    totalOrders: number;
    totalOrdersToday: number;
    totalOrdersThisMonth: number;
    revenueToday: number;
    ordersPerHour: number[];
    ordersPerDay: number[];
  }> {
    const now = new Date();
    const todayStart = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const allOrders = await this.orderRepo.find();

    const ordersToday = allOrders.filter(
      (o) => new Date(o.createdAt) >= todayStart,
    );

    const ordersThisMonth = allOrders.filter(
      (o) => new Date(o.createdAt) >= monthStart,
    );

    const revenueToday = ordersToday.reduce(
      (sum, o) => sum + Number(o.totalAmount),
      0,
    );

    // Orders per hour today (0-23)
    const ordersPerHour = Array.from(
      { length: 24 },
      (_, h) =>
        ordersToday.filter((o) => new Date(o.createdAt).getHours() === h)
          .length,
    );

    // Orders per day this month
    const daysInMonth = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
    ).getDate();
    const ordersPerDay = Array.from(
      { length: daysInMonth },
      (_, d) =>
        ordersThisMonth.filter((o) => new Date(o.createdAt).getDate() === d + 1)
          .length,
    );

    return {
      totalOrders: allOrders.length,
      totalOrdersToday: ordersToday.length,
      totalOrdersThisMonth: ordersThisMonth.length,
      revenueToday,
      ordersPerHour,
      ordersPerDay,
    };
  }

  async updateDeliveryPhoto(id: number, photoPath: string): Promise<Order | null> {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) return null;
    order.deliveryPhoto = photoPath;
    await this.orderRepo.save(order);
    return order;
  }

  async updateDeliveryCoords(
    id: number,
    lat: number,
    lng: number,
    status?: string,
    snappedLat?: number,
    snappedLng?: number,
  ): Promise<{
    routes: RouteResult;
    snappedDriverLat?: number;
    snappedDriverLng?: number;
  } | null> {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: ['driver'],
    });

    if (!order) {
      console.log('[updateDeliveryCoords] Order not found');
      return null;
    }

    order.deliveryLat = lat;
    order.deliveryLng = lng;
    await this.orderRepo.save(order);
    console.log('[updateDeliveryCoords] Saved deliveryLat/Lng:', { lat, lng });

    if (!order.driver) {
      console.log('[updateDeliveryCoords] No driver assigned yet, returning saved coords without routes');
      return { routes: { routeToStore: null, routeToDestination: null } };
    }

    // Determine driver's snapped position:
    //   1. If client sent snappedLat/snappedLng, use those (most accurate, client-side snap).
    //   2. Otherwise, snap server-side using OSRM Match API.
    //   3. If that also fails, fall back to driver's raw GPS.
    let driverLat: number;
    let driverLng: number;
    let finalSnappedLat: number | undefined;
    let finalSnappedLng: number | undefined;

    if (snappedLat != null && snappedLng != null) {
      driverLat = snappedLat;
      driverLng = snappedLng;
      finalSnappedLat = snappedLat;
      finalSnappedLng = snappedLng;
      console.log('[updateDeliveryCoords] Using client-provided snapped coords');
    } else {
      const rawLat = order.driver.currentLat;
      const rawLng = order.driver.currentLng;
      if (!rawLat || !rawLng) {
        console.log('[updateDeliveryCoords] Driver location null:', { rawLat, rawLng });
        return { routes: { routeToStore: null, routeToDestination: null } };
      }

      console.log('[updateDeliveryCoords] Snapping driver position server-side...');
      const snapped = await snapToRoadOSRM(rawLat, rawLng);
      if (snapped) {
        driverLat = snapped.lat;
        driverLng = snapped.lng;
        finalSnappedLat = snapped.lat;
        finalSnappedLng = snapped.lng;
        // Persist snapped position on the driver so future requests are accurate
        await this.driversService.updateLocation(
          order.driver.id,
          snapped.lat,
          snapped.lng,
        );
        console.log('[updateDeliveryCoords] Server-side snap success:', {
          from: { lat: rawLat, lng: rawLng },
          to: { lat: snapped.lat, lng: snapped.lng },
        });
      } else {
        driverLat = rawLat;
        driverLng = rawLng;
        console.log('[updateDeliveryCoords] Snap failed, using raw GPS');
      }
    }

    const source: [number, number] = [driverLng, driverLat];
    const storeLat = -7.2628478;
    const storeLng = 112.7336368;

    let routeToStore: string | null = null;
    let routeToDestination: string | null = null;

    const orderStatus = status || order.status;

    console.log('[updateDeliveryCoords] Calculating routes. Status:', orderStatus, {
      driver: { lat: driverLat, lng: driverLng, snapped: finalSnappedLat != null },
      delivery: { lat, lng },
    });

    if (orderStatus === 'pickingUp') {
      console.log('[updateDeliveryCoords] Status is pickingUp - calculating route to store');
      routeToStore = await getRouteWithORSAndFallback(source, [storeLng, storeLat]);
      console.log('[updateDeliveryCoords] routeToStore:', routeToStore ? `received (${routeToStore.length} chars)` : 'null');
    } else {
      console.log('[updateDeliveryCoords] Status is delivering - calculating route to destination');
      routeToDestination = await getRouteWithORSAndFallback(source, [lng, lat]);
      console.log('[updateDeliveryCoords] routeToDestination:', routeToDestination ? `received (${routeToDestination.length} chars)` : 'null');
    }

    return {
      routes: {
        routeToStore,
        routeToDestination,
      },
      snappedDriverLat: finalSnappedLat,
      snappedDriverLng: finalSnappedLng,
    };
  }

  async getOrderRoutes(orderId: number): Promise<RouteResult> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['driver'],
    });

    if (!order || !order.driver) {
      console.log('[getOrderRoutes] Order or driver not found');
      return { routeToStore: null, routeToDestination: null };
    }

    const driverLat = order.driver.currentLat;
    const driverLng = order.driver.currentLng;

    if (!driverLat || !driverLng) {
      console.log('[getOrderRoutes] Driver location null:', { driverLat, driverLng });
      return { routeToStore: null, routeToDestination: null };
    }

    const storeLat = -7.2628478;
    const storeLng = 112.7336368;

    console.log('[getOrderRoutes] Calculating route:', {
      orderId,
      status: order.status,
      driver: { lat: driverLat, lng: driverLng },
      store: { lat: storeLat, lng: storeLng },
      delivery: { lat: order.deliveryLat, lng: order.deliveryLng },
    });

    const source: [number, number] = [driverLng, driverLat];

    if (order.status === OrderStatus.PICKING_UP || order.status === OrderStatus.PICKED_UP) {
      const routeToStore = await getRouteWithORSAndFallback(
        source,
        [storeLng, storeLat],
      );
      console.log('[getOrderRoutes] routeToStore:', routeToStore ? `received (${routeToStore.length} chars)` : 'null');
      return { routeToStore, routeToDestination: null };
    } else {
      // ✅ Use typed entity field, no more (order as any) cast
      let deliveryLat = order.deliveryLat;
      let deliveryLng = order.deliveryLng;

      if (!deliveryLat || !deliveryLng || deliveryLat === 0 || deliveryLng === 0) {
        console.log('[getOrderRoutes] Delivery coordinates missing or zero, geocoding address:', order.deliveryAddress);
        const geocoded = await geocodeAddress(order.deliveryAddress);
        if (geocoded) {
          deliveryLat = geocoded.lat;
          deliveryLng = geocoded.lng;
          // ✅ Save geocoded coordinates for future requests
          order.deliveryLat = deliveryLat;
          order.deliveryLng = deliveryLng;
          await this.orderRepo.save(order);
          console.log('[getOrderRoutes] Geocoded and saved delivery coords:', { lat: deliveryLat, lng: deliveryLng });
        } else {
          console.log('[getOrderRoutes] Geocoding failed, returning null routes');
          return { routeToStore: null, routeToDestination: null };
        }
      }

      const routeToDestination = await getRouteWithORSAndFallback(
        source,
        [deliveryLng, deliveryLat],
      );
      console.log('[getOrderRoutes] routeToDestination:', routeToDestination ? `received (${routeToDestination.length} chars)` : 'null');
      return { routeToStore: null, routeToDestination };
    }
  }

  async calculateRouteFromPosition(orderId: number, driverLat: number, driverLng: number): Promise<RouteResult> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['driver'],
    });

    if (!order) {
      console.log('[calculateRouteFromPosition] Order not found:', orderId);
      return { routeToStore: null, routeToDestination: null };
    }

    const storeLat = -7.2628478;
    const storeLng = 112.7336368;
    const source: [number, number] = [driverLng, driverLat];

    console.log('[calculateRouteFromPosition] Calculating route for order:', orderId, {
      status: order.status,
      driver: { lat: driverLat, lng: driverLng },
      store: { lat: storeLat, lng: storeLng },
    });

    if (order.status === OrderStatus.PICKING_UP || order.status === OrderStatus.PICKED_UP) {
      const routeToStore = await getRouteWithORSAndFallback(source, [storeLng, storeLat]);
      console.log('[calculateRouteFromPosition] routeToStore:', routeToStore ? `received (${routeToStore.length} chars)` : 'null');
      return { routeToStore, routeToDestination: null };
    } else {
      let deliveryLat = order.deliveryLat;
      let deliveryLng = order.deliveryLng;

      if (!deliveryLat || !deliveryLng || deliveryLat === 0 || deliveryLng === 0) {
        console.log('[calculateRouteFromPosition] Delivery coords missing, geocoding:', order.deliveryAddress);
        const geocoded = await geocodeAddress(order.deliveryAddress);
        if (geocoded) {
          deliveryLat = geocoded.lat;
          deliveryLng = geocoded.lng;
          order.deliveryLat = deliveryLat;
          order.deliveryLng = deliveryLng;
          await this.orderRepo.save(order);
        } else {
          console.log('[calculateRouteFromPosition] Geocoding failed');
          return { routeToStore: null, routeToDestination: null };
        }
      }

      const routeToDestination = await getRouteWithORSAndFallback(source, [deliveryLng, deliveryLat]);
      console.log('[calculateRouteFromPosition] routeToDestination:', routeToDestination ? `received (${routeToDestination.length} chars)` : 'null');
      return { routeToStore: null, routeToDestination };
    }
  }
}
