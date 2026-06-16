// VITE_API_URL is baked into the bundle at build time. Default to the Dokploy
// backend so `npm run dev` and `vite preview` still work out of the box.
const BASE_URL =
    (import.meta.env.VITE_API_URL as string | undefined)?.replace(/\/+$/, '') ||
    'https://api-kelun.ngelantour.cloud';

async function request(path: string, options?: RequestInit) {
    try {
        const res = await fetch(`${BASE_URL}${path}`, {
            headers: { 'Content-Type': 'application/json', ...options?.headers },
            ...options,
        });
        if (!res.ok) {
            const err = await res.json().catch(() => ({ message: res.statusText }));
            throw new Error(err.message || res.statusText);
        }
        return res.json();
    } catch (e) {
        if ((e as Error).name === 'AbortError') {
            return null;
        }
        throw e;
    }
}

// ----- Products -----
export async function fetchProducts() {
    return request('/products');
}

export async function createProduct(data: {
    name: string;
    price: number;
    stock: number;
    unit: string;
    description?: string;
    imageUrl?: string;
    category?: string;
    image?: File | null;
}): Promise<{ action: 'created' | 'updated'; product: any }> {
    if (data.image) {
        const formData = new FormData();
        formData.append('name', data.name);
        formData.append('price', String(data.price));
        formData.append('stock', String(data.stock));
        formData.append('unit', data.unit);
        if (data.description) formData.append('description', data.description);
        if (data.category) formData.append('category', data.category);
        formData.append('image', data.image);

        const res = await fetch(`${BASE_URL}/products`, {
            method: 'POST',
            body: formData,
        });
        if (!res.ok) {
            const err = await res.json().catch(() => ({ message: res.statusText }));
            throw new Error(err.message || res.statusText);
        }
        return res.json();
    }

    return request('/products', {
        method: 'POST',
        body: JSON.stringify({
            name: data.name,
            price: data.price,
            stock: data.stock,
            unit: data.unit,
            description: data.description,
            imageUrl: data.imageUrl,
            category: data.category,
        }),
    });
}

export async function deleteProduct(id: number) {
    return request(`/products/${id}`, { method: 'DELETE' });
}

export async function fetchLowStockProducts() {
    return request('/products/low-stock');
}

export async function fetchProductROP(id: number) {
    return request(`/products/${id}/rop`);
}

export async function updateProductROPConfig(
    id: number,
    data: { leadTime?: number; safetyStock?: number },
) {
    return request(`/products/${id}/rop-config`, {
        method: 'PATCH',
        body: JSON.stringify(data),
    });
}

// ----- Orders -----
export async function fetchOrders() {
    return request('/orders');
}

export async function fetchOrderStats() {
    return request('/orders/stats');
}

export async function fetchOrderRoutes(orderId: number, signal?: AbortSignal): Promise<{
    routeToStore: string | null;
    routeToDestination: string | null;
}> {
    return request(`/orders/${orderId}/routes`, { signal } as RequestInit);
}

// ----- Employees (Drivers) -----
export interface Employee {
    id: number;
    username: string;
    name: string;
    phone: string;
    isActive: boolean;
    isAvailable?: boolean;
    currentLat?: number | null;
    currentLng?: number | null;
    vehicleType?: string;
    vehicleBrand?: string;
    vehiclePlate?: string;
    vehicleColor?: string;
    activeOrderId?: number | null;
}

export async function fetchEmployees(): Promise<Employee[]> {
    return request('/drivers');
}

export async function fetchAvailableDrivers(signal?: AbortSignal): Promise<Employee[]> {
    return request('/drivers', { signal } as RequestInit);
}

export async function createEmployee(data: {
    username: string;
    password: string;
    name: string;
    phone?: string;
}): Promise<Employee> {
    return request('/drivers', {
        method: 'POST',
        body: JSON.stringify(data),
    });
}

export async function deleteEmployee(id: number) {
    return request(`/drivers/${id}`, { method: 'DELETE' });
}

export async function toggleEmployeeActive(id: number, isActive: boolean) {
    return request(`/drivers/${id}`, {
        method: 'PUT',
        body: JSON.stringify({ isActive }),
    });
}

// ----- Time Slots (Admin) -----
export interface DashboardSlot {
    slotId: number;
    time: string;
    orderCount: number;
    bookings: number;
    maxBookings: number;
    isActive: boolean;
}

export interface SlotOrder {
    id: number;
    customerName: string;
    customerPhone: string;
    status: string;
    totalAmount: number;
    createdAt: string;
    driverName: string | null;
}

export async function fetchDashboardTimeSlots(
    date: string,
): Promise<DashboardSlot[]> {
    return request(`/time-slots/dashboard?date=${date}`);
}

export async function fetchOrdersBySlot(
    date: string,
    time: string,
): Promise<SlotOrder[]> {
    return request(
        `/time-slots/slot-orders?date=${date}&time=${encodeURIComponent(time)}`,
    );
}

export async function setTimeSlotActive(
    id: number,
    isActive: boolean,
): Promise<{ success: boolean; message: string; slot: DashboardSlot }> {
    return request(`/time-slots/${id}/active`, {
        method: 'PATCH',
        body: JSON.stringify({ isActive }),
    });
}

// ----- Units -----
export interface UnitItem {
    id: number;
    name: string;
    isDefault: boolean;
    isActive: boolean;
    createdAt: string;
}

export async function fetchUnits(): Promise<UnitItem[]> {
    return request('/units');
}

export async function createUnit(name: string): Promise<UnitItem> {
    return request('/units', {
        method: 'POST',
        body: JSON.stringify({ name }),
    });
}

export async function deleteUnit(id: number): Promise<{ message: string; unit: UnitItem }> {
    return request(`/units/${id}`, { method: 'DELETE' });
}