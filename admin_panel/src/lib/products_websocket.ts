import { io, Socket } from 'socket.io-client';

export interface ProductEvent {
    product?: any;
    productId?: number;
    timestamp: string;
}

let socket: Socket | null = null;
let productCreatedHandler: ((data: ProductEvent) => void) | null = null;
let productUpdatedHandler: ((data: ProductEvent) => void) | null = null;
let productDeletedHandler: ((data: ProductEvent) => void) | null = null;

export function initProductsWebSocket(): void {
    if (socket?.connected) {
        return;
    }

    const wsUrl = 'http://localhost:3000/products';
    console.log('[ProductsWS] Connecting to', wsUrl);

    socket = io(wsUrl, {
        transports: ['websocket', 'polling'],
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionAttempts: Infinity,
    });

    socket.on('connect', () => {
        console.log('[ProductsWS] Connected:', socket?.id);
    });

    socket.on('disconnect', () => {
        console.log('[ProductsWS] Disconnected');
    });

    socket.on('connect_error', (error) => {
        console.error('[ProductsWS] Connection error:', error);
    });

    socket.on('product_created', (data: ProductEvent) => {
        console.log('[ProductsWS] Product created:', data);
        if (productCreatedHandler) {
            productCreatedHandler(data);
        }
    });

    socket.on('product_updated', (data: ProductEvent) => {
        console.log('[ProductsWS] Product updated:', data);
        if (productUpdatedHandler) {
            productUpdatedHandler(data);
        }
    });

    socket.on('product_deleted', (data: ProductEvent) => {
        console.log('[ProductsWS] Product deleted:', data);
        if (productDeletedHandler) {
            productDeletedHandler(data);
        }
    });
}

export function onProductCreated(handler: (data: ProductEvent) => void): void {
    productCreatedHandler = handler;
}

export function onProductUpdated(handler: (data: ProductEvent) => void): void {
    productUpdatedHandler = handler;
}

export function onProductDeleted(handler: (data: ProductEvent) => void): void {
    productDeletedHandler = handler;
}

export function disconnectProductsWebSocket(): void {
    if (socket) {
        socket.disconnect();
        socket = null;
    }
}
