<script lang="ts">
    import { onMount } from "svelte";
    import { fetchOrders } from "$lib/api";

    // Orders page — fetched from API
    let orders = $state<any[]>([]);
    let isLoading = $state(true);

    onMount(async () => {
        try {
            const data = await fetchOrders();
            orders = data.map((o: any) => ({
                id: `#ORD-${String(o.id).padStart(3, "0")}`,
                rawId: o.id,
                customer: o.customerName,
                date: new Date(o.createdAt).toISOString().split("T")[0],
                total: formatRupiah(Number(o.totalAmount)),
                status: mapStatus(o.status),
                items: (o.items || []).map((i: any) => ({
                    name: i.productName,
                    price: formatRupiah(Number(i.unitPrice)),
                    qty: i.quantity,
                })),
            }));
        } catch (e) {
            console.error("Failed to load orders:", e);
        } finally {
            isLoading = false;
        }
    });

    function formatRupiah(val: number): string {
        return "Rp " + val.toLocaleString("id-ID");
    }

    function mapStatus(status: string): string {
        switch (status) {
            case "pending":
                return "Pending";
            case "pickingUp":
            case "pickedUp":
            case "delivering":
                return "Processing";
            case "delivered":
                return "Completed";
            default:
                return status;
        }
    }

    let selectedOrder: any = $state(null);

    function ObjectKey<T>(obj: T) {
        return obj as any;
    }

    function statusColor(status: string): string {
        switch (status) {
            case "Completed":
                return "var(--color-success)";
            case "Processing":
                return "var(--color-info)";
            case "Pending":
                return "var(--color-warning)";
            default:
                return "var(--color-text-muted)";
        }
    }

    function openModal(order: any) {
        selectedOrder = order;
    }

    function closeModal() {
        selectedOrder = null;
    }

    function printPDF() {
        window.print();
    }
</script>

<div class="table-container header-action-bar hide-on-print">
    <table class="orders-table">
        <thead>
            <tr>
                <th>Order ID</th>
                <th>Customer</th>
                <th>Date</th>
                <th>Total</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            {#each orders as order}
                <tr onclick={() => openModal(order)} class="clickable-row">
                    <td class="order-id">{order.id}</td>
                    <td>{order.customer}</td>
                    <td class="order-date">{order.date}</td>
                    <td class="order-total">{order.total}</td>
                    <td>
                        <span
                            class="status-pill"
                            style="background: {statusColor(
                                order.status,
                            )}15; color: {statusColor(order.status)}"
                        >
                            {order.status}
                        </span>
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>
</div>

{#if selectedOrder}
    <div class="modal-overlay">
        <div class="modal-content print-area">
            <div class="modal-header hide-on-print">
                <h2>Order Details</h2>
                <button class="close-btn" onclick={closeModal}>&times;</button>
            </div>

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
                    <span class="label">Date</span>
                    <span class="value">{selectedOrder.date}</span>
                </div>
                <div class="info-group hide-on-print">
                    <span class="label">Status</span>
                    <span
                        class="value status-text"
                        style="color: {statusColor(selectedOrder.status)}"
                        >{selectedOrder.status}</span
                    >
                </div>
            </div>

            <div class="items-list">
                <h4>Order Items</h4>
                <table class="items-table">
                    <thead>
                        <tr>
                            <th>Item Name</th>
                            <th>Qty</th>
                            <th class="text-right">Price</th>
                        </tr>
                    </thead>
                    <tbody>
                        {#each selectedOrder.items || [] as item}
                            <tr>
                                <td>{item.name}</td>
                                <td>{item.qty}</td>
                                <td class="text-right">{item.price}</td>
                            </tr>
                        {/each}
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="2" class="total-label"
                                ><strong>Total</strong></td
                            >
                            <td class="total-value text-right"
                                ><strong>{selectedOrder.total}</strong></td
                            >
                        </tr>
                    </tfoot>
                </table>
            </div>

            <div class="modal-actions hide-on-print">
                <button class="btn btn-secondary" onclick={closeModal}
                    >Close</button
                >
                <button class="btn btn-primary" onclick={printPDF}>
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="16"
                        height="16"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        ><polyline points="6 9 6 2 18 2 18 9"></polyline><path
                            d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"
                        ></path><rect x="6" y="14" width="12" height="8"
                        ></rect></svg
                    >
                    Print as PDF
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

    .clickable-row {
        cursor: pointer;
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

    /* Modal Styles */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
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
        max-width: 500px;
        max-height: 90vh;
        overflow-y: auto;
        padding: 30px;
        animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    }

    @keyframes slideUp {
        from {
            opacity: 0;
            transform: translateY(20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
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

    /* Print Specific Styles */
    @media print {
        @page {
            margin: 0;
        }

        :global(.sidebar) {
            display: none !important;
        }

        :global(.topbar) {
            display: none !important;
        }

        :global(.main-content) {
            margin: 0 !important;
            padding: 0 !important;
            background: none !important;
            min-height: auto !important;
        }

        .table-container {
            display: none !important;
        }

        .hide-on-print {
            display: none !important;
        }

        .modal-overlay {
            position: static !important;
            background: none !important;
            padding: 0 !important;
            backdrop-filter: none !important;
            display: block !important;
        }

        .modal-content {
            position: static !important;
            box-shadow: none !important;
            border: none !important;
            padding: 2cm !important;
            max-width: 100% !important;
            max-height: none !important;
            width: 100% !important;
            overflow: visible !important;
            animation: none !important;
        }

        .receipt-header {
            border-bottom: 2px dashed #000;
        }

        .items-table th {
            color: #000;
            border-bottom: 1px solid #000;
        }

        .items-table td {
            color: #000;
            border-bottom: 1px dashed #333;
        }

        .items-table tfoot td {
            border-top: 2px solid #000;
        }
    }
</style>
