import { io, Socket } from 'socket.io-client';

export interface DriverLocationUpdate {
    driverId: number;
    lat: number;
    lng: number;
    timestamp: string;
}

let socket: Socket | null = null;
let locationUpdateHandler: ((data: DriverLocationUpdate) => void) | null = null;

export function initWebSocket(): void {
    if (socket?.connected) {
        return;
    }

    const wsUrl = 'http://localhost:3000/driver-location';
    console.log('[WebSocket] Connecting to', wsUrl);

    socket = io(wsUrl, {
        transports: ['websocket', 'polling'],
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionAttempts: Infinity,
    });

    socket.on('connect', () => {
        console.log('[WebSocket] Connected:', socket?.id);
        socket?.emit('admin_subscribe');
    });

    socket.on('disconnect', () => {
        console.log('[WebSocket] Disconnected');
    });

    socket.on('connect_error', (error) => {
        console.error('[WebSocket] Connection error:', error);
    });

    socket.on('driver_location_changed', (data: DriverLocationUpdate) => {
        console.log('[WebSocket] Driver location changed:', data);
        if (locationUpdateHandler) {
            locationUpdateHandler(data);
        }
    });
}

export function setLocationUpdateHandler(handler: (data: DriverLocationUpdate) => void): void {
    locationUpdateHandler = handler;
}

export function disconnectWebSocket(): void {
    if (socket) {
        socket.emit('admin_unsubscribe');
        socket.disconnect();
        socket = null;
    }
}