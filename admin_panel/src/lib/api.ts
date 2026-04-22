const BASE_URL = 'http://localhost:3000';

async function request(path: string, options?: RequestInit) {
    const res = await fetch(`${BASE_URL}${path}`, {
        headers: { 'Content-Type': 'application/json', ...options?.headers },
        ...options,
    });
    if (!res.ok) {
        const err = await res.json().catch(() => ({ message: res.statusText }));
        throw new Error(err.message || res.statusText);
    }
    return res.json();
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
}): Promise<any> {
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

// ----- Employees (Drivers) -----
export interface Employee {
    id: number;
    username: string;
    name: string;
    phone: string;
    isActive: boolean;
}

export async function fetchEmployees(): Promise<Employee[]> {
    return request('/drivers');
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
