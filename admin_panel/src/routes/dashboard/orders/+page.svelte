<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { fetchOrders } from "$lib/api";

    let orders = $state<any[]>([]);
    let isLoading = $state(true);
    let selectedOrder: any = $state(null);
    let showDetailModal = $state(false);
    let showPhotoModal = $state(false);
    let photoUrl = $state('');
    let pollInterval: any = $state(null);

    onMount(async () => {
        await loadOrders();
        // Start polling every 30 seconds for real-time updates
        pollInterval = setInterval(() => {
            loadOrders();
        }, 30000);
    });

    onDestroy(() => {
        if (pollInterval) {
            clearInterval(pollInterval);
        }
    });

    async function loadOrders() {
        try {
            isLoading = true;
            const data = await fetchOrders();
            // Debug: log first order to check deliveryPhoto field
            console.log('API Response - First order:', data[0]);
            console.log('deliveryPhoto field:', data[0]?.deliveryPhoto);
            orders = data.map((o: any) => ({
                id: `#ORD-${String(o.id).padStart(3, "0")}`,
                rawId: o.id,
                customer: o.customerName,
                phone: o.customerPhone || "-",
                address: o.deliveryAddress || "-",
                date: new Date(o.createdAt).toLocaleDateString("id-ID", {
                    year: "numeric",
                    month: "short",
                    day: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                }),
                total: formatRupiah(Number(o.totalAmount)),
                status: mapStatus(o.status),
                rawStatus: o.status,
                paymentMethod: o.paymentMethod || "COD",
                deliveryPhoto: o.deliveryPhoto || null,
                items: (o.items || []).map((i: any) => ({
                    name: i.productName,
                    unitName: i.unitName || "",
                    price: formatRupiah(Number(i.unitPrice)),
                    qty: i.quantity,
                    subtotal: formatRupiah(Number(i.unitPrice) * Number(i.quantity)),
                })),
            }));
        } catch (e) {
            console.error("Failed to load orders:", e);
        } finally {
            isLoading = false;
        }
    }

    function formatRupiah(val: number): string {
        return "Rp " + val.toLocaleString("id-ID");
    }

    function mapStatus(status: string): string {
        switch (status) {
            case "pending": return "Pending";
            case "pickingUp":
            case "pickedUp":
            case "delivering": return "Processing";
            case "delivered": return "Completed";
            case "cancelled": return "Cancelled";
            default: return status;
        }
    }

    function statusColor(status: string): string {
        switch (status) {
            case "Completed": return "var(--color-success)";
            case "Processing": return "var(--color-info)";
            case "Pending": return "var(--color-warning)";
            case "Cancelled": return "var(--color-danger)";
            default: return "var(--color-text-muted)";
        }
    }

    function openDetail(order: any) {
        selectedOrder = order;
        showDetailModal = true;
    }

    function closeDetail() {
        showDetailModal = false;
        selectedOrder = null;
    }

    function openPhoto(order: any) {
        console.log('Order deliveryPhoto:', order.deliveryPhoto);
        console.log('Order rawStatus:', order.rawStatus);
        if (order.deliveryPhoto) {
            if (order.deliveryPhoto.startsWith('http')) {
                photoUrl = order.deliveryPhoto;
            } else if (order.deliveryPhoto.includes('uploads')) {
                photoUrl = 'http://localhost:3000/' + order.deliveryPhoto;
            } else if (order.deliveryPhoto.includes('/') || order.deliveryPhoto.includes('\\')) {
                // Handle absolute paths like /uploads/filename.jpg or C:\path\to\file
                if (order.deliveryPhoto.startsWith('/')) {
                    photoUrl = 'http://localhost:3000' + order.deliveryPhoto;
                } else {
                    photoUrl = 'http://localhost:3000/uploads/' + order.deliveryPhoto.split(/[/\\]/).pop();
                }
            } else {
                // Just a filename, add uploads prefix
                photoUrl = 'http://localhost:3000/uploads/' + order.deliveryPhoto;
            }
            console.log('Final photoUrl:', photoUrl);
            if (photoUrl) {
                showPhotoModal = true;
            } else {
                alert('Photo URL is empty');
            }
        } else {
            alert('No delivery photo available for this order');
        }
    }

    function closePhoto() {
        showPhotoModal = false;
        photoUrl = '';
    }

    function printOrder() {
        const printContent = document.getElementById("print-area");
        if (!printContent || !selectedOrder) return;

        const printWindow = window.open("", "_blank");
        if (!printWindow) return;

        printWindow.document.write(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Order ${selectedOrder.id} - Receipt</title>
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body { font-family: Arial, sans-serif; padding: 40px; }
                    .receipt-header { text-align: center; margin-bottom: 30px; border-bottom: 2px dashed #333; padding-bottom: 20px; }
                    .receipt-header h3 { font-size: 24px; margin-bottom: 8px; letter-spacing: 2px; }
                    .receipt-header p { color: #666; font-family: monospace; font-size: 16px; }
                    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 30px; }
                    .info-item { display: flex; flex-direction: column; gap: 4px; }
                    .info-item label { font-size: 12px; color: #888; text-transform: uppercase; }
                    .info-item span { font-weight: 600; }
                    .info-item.full-width { grid-column: 1 / -1; }
                    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
                    th { text-align: left; padding: 10px 8px; border-bottom: 2px solid #333; font-size: 12px; text-transform: uppercase; }
                    td { padding: 10px 8px; border-bottom: 1px solid #ddd; }
                    .text-right { text-align: right; }
                    .total-row td { border-top: 2px solid #333; font-weight: bold; font-size: 18px; padding-top: 16px; }
                    .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 2px dashed #333; color: #666; font-size: 12px; }
                </style>
            </head>
            <body>
                <div class="receipt-header">
                    <h3>RECEIPT</h3>
                    <p><strong>${selectedOrder.id}</strong></p>
                </div>
                <div class="info-grid">
                    <div class="info-item">
                        <label>Customer</label>
                        <span>${selectedOrder.customer}</span>
                    </div>
                    <div class="info-item">
                        <label>Phone</label>
                        <span>${selectedOrder.phone}</span>
                    </div>
                    <div class="info-item">
                        <label>Date</label>
                        <span>${selectedOrder.date}</span>
                    </div>
                    <div class="info-item">
                        <label>Payment</label>
                        <span>${selectedOrder.paymentMethod}</span>
                    </div>
                    <div class="info-item full-width">
                        <label>Address</label>
                        <span>${selectedOrder.address}</span>
                    </div>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Item Name</th>
                            <th>Unit</th>
                            <th>Qty</th>
                            <th class="text-right">Price</th>
                            <th class="text-right">Subtotal</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${selectedOrder.items.map((item: any) => `
                            <tr>
                                <td>${item.name}</td>
                                <td>${item.unitName || "-"}</td>
                                <td>${item.qty}</td>
                                <td class="text-right">${item.price}</td>
                                <td class="text-right">${item.subtotal}</td>
                            </tr>
                        `).join("")}
                    </tbody>
                    <tfoot>
                        <tr class="total-row">
                            <td colspan="4"><strong>Total</strong></td>
                            <td class="text-right"><strong>${selectedOrder.total}</strong></td>
                        </tr>
                    </tfoot>
                </table>
                <div class="footer">
                    <p>Thank you for your order!</p>
                    <p>Printed on: ${new Date().toLocaleDateString("id-ID", { year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit" })}</p>
                </div>
            </body>
            </html>
        `);
        printWindow.document.close();
        printWindow.print();
    }
</script>

<!-- Action Bar -->
<div class="action-bar">
    <button class="btn-refresh" onclick={loadOrders} title="Refresh Orders">
        <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
        >
            <path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/>
            <path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/>
        </svg>
        Refresh
    </button>
</div>

<!-- Orders Table -->
<div class="table-container">
    {#if isLoading}
        <div class="loading-state">
            <div class="spinner"></div>
            <p>Loading orders...</p>
        </div>
    {:else}
        <table class="orders-table">
            <thead>
                <tr>
                    <th>Order ID</th>
                    <th>Customer</th>
                    <th>Date</th>
                    <th>Total</th>
                    <th>Status</th>
                    <th class="col-action">Action</th>
                </tr>
            </thead>
            <tbody>
                {#each orders as order}
                    <tr class="clickable-row">
                        <td class="order-id">{order.id}</td>
                        <td>{order.customer}</td>
                        <td class="order-date">{order.date}</td>
                        <td class="order-total">{order.total}</td>
                        <td>
                            <span
                                class="status-pill"
                                style="background: {statusColor(order.status)}15; color: {statusColor(order.status)}"
                            >
                                {order.status}
                            </span>
                        </td>
                        <td class="col-action" style="display: flex; justify-content: center; gap: 4px;">
                            <button
                                class="btn-icon"
                                onclick={() => openDetail(order)}
                                title="View Details"
                            >
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                    <circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                            {#if order.rawStatus === 'delivered'}
                                <button
                                    class="btn-icon"
                                    style="color: var(--color-success)"
                                    onclick={() => openPhoto(order)}
                                    title="View Delivery Photo"
                                >
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                                        <circle cx="8.5" cy="8.5" r="1.5"/>
                                        <polyline points="21 15 16 10 5 21"/>
                                    </svg>
                                </button>
                            {/if}
                        </td>
                    </tr>
                {/each}
                {#if orders.length === 0}
                    <tr>
                        <td colspan="6" class="empty-state">No orders found. Orders will appear here when customers make purchases.</td>
                    </tr>
                {/if}
            </tbody>
        </table>
    {/if}
</div>

<!-- Order Detail Modal -->
{#if showDetailModal && selectedOrder}
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="modal-overlay" onclick={closeDetail}>
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div class="modal-content" onclick={(e) => e.stopPropagation()}>
            <div class="modal-header">
                <h2>Order Details</h2>
                <button class="close-btn" onclick={closeDetail}>&times;</button>
            </div>

            <div id="print-area">
                <div class="receipt-header">
                    <h3>RECEIPT</h3>
                    <p><strong>{selectedOrder.id}</strong></p>
                </div>

                <div class="order-info-grid">
                    <div class="info-group">
                        <span class="label">Customer</span>
                        <span class="value">{selectedOrder.customer}</span>
                    </div>
                    <div class="info-group">
                        <span class="label">Phone</span>
                        <span class="value">{selectedOrder.phone}</span>
                    </div>
                    <div class="info-group">
                        <span class="label">Date</span>
                        <span class="value">{selectedOrder.date}</span>
                    </div>
                    <div class="info-group">
                        <span class="label">Payment</span>
                        <span class="value">{selectedOrder.paymentMethod}</span>
                    </div>
                    <div class="info-group full-width">
                        <span class="label">Address</span>
                        <span class="value">{selectedOrder.address}</span>
                    </div>
                    <div class="info-group">
                        <span class="label">Status</span>
                        <span class="value status-text" style="color: {statusColor(selectedOrder.status)}">
                            {selectedOrder.status}
                        </span>
                    </div>
                </div>

                {#if selectedOrder.rawStatus === 'delivered' && selectedOrder.deliveryPhoto}
                    <div class="delivery-photo-section">
                        <h4>Bukti Pengantaran</h4>
                        <div class="photo-container">
                            {#if selectedOrder.deliveryPhoto.startsWith('http')}
                                <img src={selectedOrder.deliveryPhoto} alt="Delivery Photo" class="delivery-photo" />
                            {:else if selectedOrder.deliveryPhoto.includes('uploads')}
                                <img src={'http://localhost:3000/' + selectedOrder.deliveryPhoto} alt="Delivery Photo" class="delivery-photo" />
                            {:else}
                                <div class="photo-placeholder">
                                    <span>Photo: {selectedOrder.deliveryPhoto}</span>
                                </div>
                            {/if}
                        </div>
                    </div>
                {/if}

                <div class="items-list">
                    <h4>Order Items</h4>
                    <table class="items-table">
                        <thead>
                            <tr>
                                <th>Item Name</th>
                                <th>Unit</th>
                                <th>Qty</th>
                                <th class="text-right">Price</th>
                                <th class="text-right">Subtotal</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each selectedOrder.items || [] as item}
                                <tr>
                                    <td>{item.name}</td>
                                    <td>{item.unitName || "-"}</td>
                                    <td>{item.qty}</td>
                                    <td class="text-right">{item.price}</td>
                                    <td class="text-right">{item.subtotal}</td>
                                </tr>
                            {/each}
                        </tbody>
                        <tfoot>
                            <tr class="total-row">
                                <td colspan="4"><strong>Total</strong></td>
                                <td class="text-right"><strong>{selectedOrder.total}</strong></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>

            <div class="modal-actions">
                <button class="btn btn-secondary" onclick={closeDetail}>
                    Close
                </button>
                <button class="btn btn-primary" onclick={printOrder}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="6 9 6 2 18 2 18 9"/>
                        <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
                        <rect x="6" y="14" width="12" height="8"/>
                    </svg>
                    Print as PDF
                </button>
            </div>
        </div>
    </div>
{/if}

<!-- Photo Modal -->
{#if showPhotoModal && photoUrl}
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="modal-overlay" onclick={closePhoto}>
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div class="modal-content photo-modal" onclick={(e) => e.stopPropagation()}>
            <div class="modal-header">
                <h2>Bukti Pengantaran</h2>
                <button class="close-btn" onclick={closePhoto}>&times;</button>
            </div>
            <div class="photo-view">
                <img src={photoUrl} alt="Delivery Photo" />
            </div>
            <div class="modal-actions">
                <button class="btn btn-secondary" onclick={closePhoto}>
                    Close
                </button>
            </div>
        </div>
    </div>
{/if}

<style>
    .table-container {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
    }

    .loading-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 60px 20px;
        color: var(--color-text-muted);
    }

    .spinner {
        width: 32px;
        height: 32px;
        border: 3px solid var(--color-border);
        border-top-color: var(--color-primary);
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
        margin-bottom: 12px;
    }

    @keyframes spin {
        to { transform: rotate(360deg); }
    }

    .orders-table {
        width: 100%;
        border-collapse: collapse;
    }

    .orders-table thead {
        background: rgba(108, 99, 255, 0.05);
    }

    .orders-table th {
        padding: 14px 20px;
        font-size: 0.75rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        text-align: left;
        border-bottom: 1px solid var(--color-border);
    }

    .orders-table td {
        padding: 16px 20px;
        font-size: 0.9rem;
        border-bottom: 1px solid var(--color-border);
        color: var(--color-text);
    }

    .orders-table tr:last-child td {
        border-bottom: none;
    }

    .orders-table tbody tr {
        transition: background var(--transition-fast);
    }

    .orders-table tbody tr:hover {
        background: rgba(108, 99, 255, 0.03);
    }

    .order-id {
        font-weight: 600;
        color: var(--color-primary) !important;
    }

    .order-date {
        color: var(--color-text-muted) !important;
        font-size: 0.85rem !important;
    }

    .order-total {
        font-weight: 600;
    }

    .status-pill {
        display: inline-block;
        padding: 4px 14px;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .col-action {
        width: 110px;
        text-align: center !important;
    }

    .btn-icon {
        background: transparent;
        color: var(--color-text-faint);
        padding: 6px;
        border-radius: var(--radius-sm);
        transition: all var(--transition-fast);
        cursor: pointer;
        border: none;
    }

    .btn-icon:hover {
        background: rgba(108, 99, 255, 0.1);
        color: var(--color-primary);
    }

    /* Action Bar */
    .action-bar {
        display: flex;
        justify-content: flex-end;
        align-items: center;
        margin-bottom: 16px;
        gap: 12px;
    }

    .btn-refresh {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 10px 18px;
        background: white;
        color: var(--color-text);
        font-size: 0.85rem;
        font-weight: 600;
        border-radius: var(--radius-md);
        border: 1px solid var(--color-border);
        transition: all var(--transition-fast);
        cursor: pointer;
    }

    .btn-refresh:hover {
        background: var(--color-primary);
        border-color: var(--color-primary);
        color: white;
    }

    .empty-state {
        text-align: center;
        padding: 48px 20px !important;
        color: var(--color-text-faint) !important;
    }

    /* Modal Styles */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        backdrop-filter: blur(4px);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
        padding: 20px;
    }

    .modal-content {
        background: var(--color-bg-card);
        border-radius: var(--radius-lg);
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        width: 100%;
        max-width: 550px;
        max-height: 90vh;
        overflow-y: auto;
        padding: 30px;
        animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    }

    @keyframes slideUp {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 24px;
        border-bottom: 1px solid var(--color-border);
        padding-bottom: 16px;
    }

    .modal-header h2 {
        margin: 0;
        font-size: 1.25rem;
        color: var(--color-text);
    }

    .close-btn {
        background: none;
        border: none;
        font-size: 1.5rem;
        color: var(--color-text-muted);
        cursor: pointer;
        padding: 0;
        line-height: 1;
        transition: color var(--transition-fast);
    }

    .close-btn:hover {
        color: var(--color-text);
    }

    .receipt-header {
        text-align: center;
        margin-bottom: 24px;
        border-bottom: 2px dashed var(--color-border);
        padding-bottom: 24px;
    }

    .receipt-header h3 {
        margin: 0 0 8px 0;
        letter-spacing: 2px;
        color: var(--color-text);
    }

    .receipt-header p {
        margin: 0;
        color: var(--color-text-muted);
        font-family: monospace;
        font-size: 1.1rem;
    }

    .order-info-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 16px;
        margin-bottom: 24px;
    }

    .info-group {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .info-group.full-width {
        grid-column: 1 / -1;
    }

    .info-group .label {
        font-size: 0.75rem;
        text-transform: uppercase;
        color: var(--color-text-muted);
        letter-spacing: 0.05em;
    }

    .info-group .value {
        font-weight: 500;
        color: var(--color-text);
    }

    .status-text {
        font-weight: 700;
    }

    .items-list h4 {
        margin: 0 0 12px 0;
        font-size: 1rem;
        color: var(--color-text);
    }

    .items-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 24px;
    }

    .items-table th {
        text-align: left;
        padding: 12px 8px;
        border-bottom: 1px solid var(--color-border);
        color: var(--color-text-muted);
        font-size: 0.8rem;
        text-transform: uppercase;
    }

    .items-table td {
        padding: 12px 8px;
        border-bottom: 1px dashed var(--color-border);
        color: var(--color-text);
        font-size: 0.9rem;
    }

    .items-table tfoot td {
        border-bottom: none;
        padding-top: 16px;
        border-top: 2px solid var(--color-border);
        font-size: 1rem;
    }

    .text-right {
        text-align: right !important;
    }

    .modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        margin-top: 32px;
        padding-top: 20px;
        border-top: 1px solid var(--color-border);
    }

    .btn {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 20px;
        border-radius: var(--radius-md);
        font-weight: 500;
        cursor: pointer;
        transition: all var(--transition-fast);
        font-size: 0.9rem;
        border: none;
    }

    .btn-secondary {
        background: transparent;
        color: var(--color-text);
        border: 1px solid var(--color-border);
    }

    .btn-secondary:hover {
        background: rgba(0, 0, 0, 0.05);
    }

    .btn-primary {
        background: var(--color-primary);
        color: white;
    }

    .btn-primary:hover {
        background: var(--color-primary-hover);
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
    }

    .delivery-photo-section {
        margin-top: 20px;
        padding-top: 20px;
        border-top: 1px solid var(--color-border);
    }

    .delivery-photo-section h4 {
        margin: 0 0 12px 0;
        font-size: 1rem;
        color: var(--color-text);
    }

    .photo-container {
        border-radius: var(--radius-md);
        overflow: hidden;
        border: 1px solid var(--color-border);
    }

    .delivery-photo {
        width: 100%;
        max-height: 300px;
        object-fit: cover;
        display: block;
    }

    .photo-placeholder {
        padding: 20px;
        text-align: center;
        background: var(--color-bg-card);
        color: var(--color-text-muted);
    }

    .btn-photo {
        margin-left: 4px;
    }

    .photo-modal {
        max-width: 600px;
    }

    .photo-modal .photo-view {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 300px;
        background: #f5f5f5;
        border-radius: var(--radius-md);
        overflow: hidden;
    }

    .photo-modal .photo-view img {
        max-width: 100%;
        max-height: 500px;
        object-fit: contain;
    }
</style>
