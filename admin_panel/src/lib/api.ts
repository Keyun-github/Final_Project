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
}) {
    return request('/products', {
        method: 'POST',
        body: JSON.stringify(data),
    });
}

export async function deleteProduct(id: number) {
    return request(`/products/${id}`, { method: 'DELETE' });
}

// ----- Orders -----
export async function fetchOrders() {
    return request('/orders');
}

export async function fetchOrderStats() {
    return request('/orders/stats');
}
