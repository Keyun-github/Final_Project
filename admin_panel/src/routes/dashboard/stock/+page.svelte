<script lang="ts">
    import { onMount } from "svelte";
    import { fetchProducts, createProduct, deleteProduct } from "$lib/api";

    // ---- Stock Management ----
    interface Variant {
        id: number;
        unitName: string;
        price: number;
    }

    interface StockItem {
        id: number;
        name: string;
        price: number;
        stock: number;
        unit: string;
        variants: Variant[];
    }

    let items = $state<StockItem[]>([]);
    let isLoading = $state(true);

    let searchQuery = $state("");
    let showModal = $state(false);
    let newName = $state("");
    let newPrice = $state("");
    let newStock = $state("");
    let newUnit = $state("KG");
    let newImage = $state<File | null>(null);
    let newImagePreview = $state("");
    let formError = $state("");

    import { onDestroy } from "svelte";

    const unitOptions = ["KG", "Box", "Sack - 25kg", "Sack - 50kg", "Piece"];

    let refreshInterval: ReturnType<typeof setInterval>;

    onMount(async () => {
        await loadProducts();
        // Auto-refresh every 30 seconds
        refreshInterval = setInterval(() => {
            loadProducts();
        }, 30000);
    });

    onDestroy(() => {
        if (refreshInterval) clearInterval(refreshInterval);
    });

    async function loadProducts() {
        try {
            isLoading = true;
            const products = await fetchProducts();
            items = products.map((p: any) => ({
                id: p.id,
                name: p.name,
                price: Number(p.price),
                stock: p.stock ?? 0,
                unit: p.unit ?? "Piece",
                leadTime: p.leadTime ?? 3,
                safetyStock: p.safetyStock ?? 5,
                sold: p.sold ?? 0,
                variants: (p.variants ?? []).map((v: any) => ({
                    id: v.id,
                    unitName: v.unitName,
                    price: Number(v.price),
                })),
            }));
        } catch (e) {
            console.error("Failed to load products:", e);
        } finally {
            isLoading = false;
        }
    }

    let filtered = $derived(
        searchQuery.trim()
            ? items.filter(
                  (item) =>
                      item.name
                          .toLowerCase()
                          .includes(searchQuery.toLowerCase()) ||
                      item.unit
                          .toLowerCase()
                          .includes(searchQuery.toLowerCase()),
              )
            : items,
    );

    function formatRupiah(val: number): string {
        return "Rp " + val.toLocaleString("id-ID");
    }

    function needsReorder(item: any): boolean {
        // ROP calculation: ROP = (Lead Time × Avg Daily Sales) + Safety Stock
        // Using Lead Time and Safety Stock from product, Avg Daily Sales = sold / 7 (last 7 days approximation)
        const leadTime = item.leadTime ?? 3;
        const safetyStock = item.safetyStock ?? 5;
        const avgDailySales = (item.sold ?? 0) / 7;
        const rop = (leadTime * avgDailySales) + safetyStock;
        return item.stock <= rop;
    }

    function openModal() {
        newName = "";
        newPrice = "";
        newStock = "";
        newUnit = "KG";
        newImage = null;
        newImagePreview = "";
        formError = "";
        showModal = true;
    }

    function closeModal() {
        showModal = false;
    }

    function handleImageChange(e: Event) {
        const input = e.target as HTMLInputElement;
        const file = input.files?.[0];
        if (file) {
            newImage = file;
            newImagePreview = URL.createObjectURL(file);
        }
    }

    async function addItem() {
        const nameVal = String(newName).trim();
        const priceVal = String(newPrice).trim();
        const stockVal = String(newStock).trim();

        if (!nameVal) {
            formError = "Item name is required";
            return;
        }
        if (!priceVal || isNaN(Number(priceVal)) || Number(priceVal) <= 0) {
            formError = "Valid price is required";
            return;
        }
        if (!stockVal || isNaN(Number(stockVal)) || Number(stockVal) < 0) {
            formError = "Valid stock quantity is required";
            return;
        }

        try {
            await createProduct({
                name: nameVal,
                price: Number(priceVal),
                stock: Number(stockVal),
                unit: newUnit,
                image: newImage,
            });
            await loadProducts();
            closeModal();
        } catch (e) {
            formError = "Failed to save item. Please try again.";
        }
    }

    async function handleDeleteItem(id: number) {
        try {
            await deleteProduct(id);
            items = items.filter((i) => i.id !== id);
        } catch (e) {
            console.error("Failed to delete item:", e);
        }
    }
</script>

<!-- Search & Add -->
<div class="top-actions">
    <div class="search-bar">
        <svg
            class="search-icon"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            ><circle cx="11" cy="11" r="8" /><line
                x1="21"
                y1="21"
                x2="16.65"
                y2="16.65"
            /></svg
        >
        <input
            type="text"
            placeholder="Search item by name or unit..."
            bind:value={searchQuery}
            id="search-stock"
        />
    </div>
    <div class="action-buttons">
        <button class="btn-refresh" onclick={loadProducts} title="Refresh Stock">
            <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                ><path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/>
                <path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/>
            </svg>
            Refresh
        </button>
        <button class="btn-add" onclick={openModal} id="btn-add-stock">
            <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                ><line x1="12" y1="5" x2="12" y2="19" /><line
                    x1="5"
                    y1="12"
                    x2="19"
                    y2="12"
                /></svg
            >
            Add Item
        </button>
    </div>
</div>

<!-- Stock Table -->
<div class="table-container">
    <table class="stock-table">
        <thead>
            <tr>
                <th class="col-no">No</th>
                <th>Item Name</th>
                <th>Price</th>
                <th>Stock</th>
                <th>Unit</th>
                <th>Status</th>
                <th class="col-action">Action</th>
            </tr>
        </thead>
        <tbody>
            {#each filtered as item, i}
                <tr>
                    <td class="col-no">{i + 1}</td>
                    <td>
                        <div class="item-name">
                            <div
                                class="item-icon"
                                style="background: {item.stock > 20
                                    ? 'rgba(0,212,170,0.1)'
                                    : 'rgba(255,77,106,0.1)'}; color: {item.stock >
                                20
                                    ? 'var(--color-success)'
                                    : 'var(--color-danger)'}"
                            >
                                <svg
                                    width="16"
                                    height="16"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    ><path
                                        d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"
                                    /></svg
                                >
                            </div>
                            <div class="item-info">
                                <span class="item-name">{item.name}</span>
                                {#if item.variants.length > 0}
                                    <div class="variant-badges">
                                        {#each item.variants as variant}
                                            <span class="variant-badge">{variant.unitName}</span>
                                        {/each}
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </td>
                    <td class="col-price">{formatRupiah(item.price)}</td>
                    <td>
                        <span
                            class="stock-badge"
                            class:low={item.stock <= 20}
                            class:medium={item.stock > 20 && item.stock <= 50}
                            class:high={item.stock > 50}
                        >
                            {item.stock}
                        </span>
                    </td>
                    <td><span class="unit-badge">{item.unit}</span></td>
                    <td>
                        {#if needsReorder(item)}
                            <span class="status-badge warning">Need Reorder</span>
                        {:else}
                            <span class="status-badge ok">OK</span>
                        {/if}
                    </td>
                    <td class="col-action">
                        <button
                            class="btn-delete"
                            onclick={() => handleDeleteItem(item.id)}
                            title="Delete item"
                        >
                            <svg
                                width="16"
                                height="16"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                ><polyline points="3 6 5 6 21 6" /><path
                                    d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"
                                /></svg
                            >
                        </button>
                    </td>
                </tr>
            {/each}
            {#if filtered.length === 0}
                <tr>
                    <td colspan="6" class="empty-state">
                        {searchQuery
                            ? "No items found matching your search."
                            : 'No stock items. Click "Add Item" to get started.'}
                    </td>
                </tr>
            {/if}
        </tbody>
    </table>
</div>

<!-- Add Item Modal -->
{#if showModal}
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
        class="modal-overlay"
        onclick={closeModal}
        onkeydown={(e) => e.key === "Escape" && closeModal()}
    >
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div
            class="modal"
            onclick={(e) => e.stopPropagation()}
            onkeydown={() => {}}
        >
            <div class="modal-header">
                <h3>Add New Stock Item</h3>
                <button
                    class="modal-close"
                    onclick={closeModal}
                    aria-label="Close"
                >
                    <svg
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        ><line x1="18" y1="6" x2="6" y2="18" /><line
                            x1="6"
                            y1="6"
                            x2="18"
                            y2="18"
                        /></svg
                    >
                </button>
            </div>

            <form
                class="modal-body"
                onsubmit={(e) => {
                    e.preventDefault();
                    addItem();
                }}
            >
                <div class="form-group">
                    <label for="item-name">Item Name</label>
                    <input
                        id="item-name"
                        type="text"
                        placeholder="e.g. Beras Premium"
                        bind:value={newName}
                    />
                </div>
                <div class="form-group">
                    <label for="item-image">Product Image</label>
                    <div class="image-upload-container">
                        <input
                            id="item-image"
                            type="file"
                            accept="image/*"
                            onchange={handleImageChange}
                            class="image-input"
                        />
                        {#if newImagePreview}
                            <div class="image-preview">
                                <img src={newImagePreview} alt="Preview" />
                            </div>
                        {:else}
                            <div class="image-placeholder">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                                    <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                                    <circle cx="8.5" cy="8.5" r="1.5"/>
                                    <polyline points="21 15 16 10 5 21"/>
                                </svg>
                                <span>Click to upload image</span>
                            </div>
                        {/if}
                    </div>
                </div>
                <div class="form-group">
                    <label for="item-price">Price (Rp)</label>
                    <input
                        id="item-price"
                        type="text"
                        inputmode="numeric"
                        placeholder="e.g. 14000"
                        bind:value={newPrice}
                    />
                </div>
                <div class="form-row">
                    <div class="form-group flex-1">
                        <label for="item-stock">Stock</label>
                        <input
                            id="item-stock"
                            type="text"
                            inputmode="numeric"
                            placeholder="e.g. 100"
                            bind:value={newStock}
                        />
                    </div>
                    <div class="form-group flex-1">
                        <label for="item-unit">Unit of Measure</label>
                        <select id="item-unit" bind:value={newUnit}>
                            {#each unitOptions as opt}
                                <option value={opt}>{opt}</option>
                            {/each}
                        </select>
                    </div>
                </div>

                {#if formError}
                    <div class="form-error">{formError}</div>
                {/if}

                <div class="modal-actions">
                    <button
                        type="button"
                        class="btn-cancel"
                        onclick={closeModal}>Cancel</button
                    >
                    <button
                        type="submit"
                        class="btn-submit"
                        id="btn-submit-stock"
                        >Save Item</button
                    >
                </div>
            </form>
        </div>
    </div>
{/if}

<style>
    /* ===== Top Actions ===== */
    .top-actions {
        display: flex;
        gap: 16px;
        align-items: center;
        margin-bottom: 24px;
        flex-wrap: wrap;
    }

    .search-bar {
        position: relative;
        flex: 1;
        max-width: 480px;
    }

    .search-icon {
        position: absolute;
        left: 16px;
        top: 50%;
        transform: translateY(-50%);
        color: var(--color-text-faint);
        pointer-events: none;
    }

    .search-bar input {
        width: 100%;
        padding: 12px 16px 12px 48px;
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-md);
        color: var(--color-text);
        font-size: 0.9rem;
        transition:
            border-color var(--transition-fast),
            box-shadow var(--transition-fast);
    }

    .search-bar input::placeholder {
        color: var(--color-text-faint);
    }

    .search-bar input:focus {
        border-color: var(--color-border-focus);
        box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.15);
    }

    .action-buttons {
        display: flex;
        gap: 10px;
    }

    .btn-refresh {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 12px 20px;
        background: white;
        color: var(--color-text);
        font-size: 0.9rem;
        font-weight: 600;
        border-radius: var(--radius-md);
        border: 1px solid var(--color-border);
        transition: all var(--transition-fast);
        white-space: nowrap;
    }

    .btn-refresh:hover {
        background: rgba(108, 99, 255, 0.05);
        border-color: var(--color-primary);
        color: var(--color-primary);
    }

    .btn-add {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 12px 24px;
        background: var(--gradient-primary);
        color: white;
        font-size: 0.9rem;
        font-weight: 600;
        border-radius: var(--radius-md);
        transition:
            transform var(--transition-fast),
            box-shadow var(--transition-fast);
        white-space: nowrap;
    }

    .btn-add:hover {
        transform: translateY(-1px);
        box-shadow: var(--shadow-glow);
    }

    /* ===== Table ===== */
    .table-container {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
    }

    .stock-table {
        width: 100%;
        border-collapse: collapse;
    }

    .stock-table thead {
        background: rgba(108, 99, 255, 0.05);
    }

    .stock-table th {
        padding: 14px 20px;
        font-size: 0.75rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        text-align: left;
        border-bottom: 1px solid var(--color-border);
    }

    .stock-table td {
        padding: 14px 20px;
        font-size: 0.9rem;
        border-bottom: 1px solid var(--color-border);
        color: var(--color-text);
    }

    .stock-table tr:last-child td {
        border-bottom: none;
    }

    .stock-table tbody tr {
        transition: background var(--transition-fast);
    }

    .stock-table tbody tr:hover {
        background: rgba(108, 99, 255, 0.03);
    }

    .col-no {
        width: 60px;
        text-align: center !important;
    }
    .col-price {
        font-weight: 600;
        font-variant-numeric: tabular-nums;
    }
    .col-action {
        width: 80px;
        text-align: center !important;
    }

    .item-name {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .item-icon {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .item-info {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .item-name {
        font-weight: 500;
    }

    .variant-badges {
        display: flex;
        gap: 4px;
        flex-wrap: wrap;
    }

    .variant-badge {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 4px;
        background: rgba(108, 99, 255, 0.06);
        color: var(--color-primary);
        font-size: 0.7rem;
        font-weight: 600;
    }

    .stock-badge {
        display: inline-block;
        padding: 3px 12px;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 700;
        font-variant-numeric: tabular-nums;
    }

    .stock-badge.high {
        background: rgba(0, 212, 170, 0.1);
        color: var(--color-success);
    }

    .stock-badge.medium {
        background: rgba(255, 193, 7, 0.1);
        color: #e6a800;
    }

    .stock-badge.low {
        background: rgba(255, 77, 106, 0.1);
        color: var(--color-danger);
    }

    .unit-badge {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 6px;
        background: rgba(108, 99, 255, 0.08);
        color: var(--color-primary);
        font-size: 0.8rem;
        font-weight: 600;
    }

    .status-badge {
        display: inline-block;
        padding: 4px 12px;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .status-badge.warning {
        background: var(--color-warning);
        color: white;
    }

    .status-badge.ok {
        background: var(--color-success);
        color: white;
    }

    .btn-delete {
        background: transparent;
        color: var(--color-text-faint);
        padding: 6px;
        border-radius: var(--radius-sm);
        transition: all var(--transition-fast);
    }

    .btn-delete:hover {
        background: rgba(255, 77, 106, 0.1);
        color: var(--color-danger);
    }

    .empty-state {
        text-align: center !important;
        padding: 48px 20px !important;
        color: var(--color-text-faint) !important;
        font-style: italic;
    }

    /* ===== Modal ===== */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.6);
        backdrop-filter: blur(4px);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 100;
        animation: fadeIn 0.2s ease;
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
        }
        to {
            opacity: 1;
        }
    }

    .modal {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        width: 100%;
        max-width: 500px;
        box-shadow: var(--shadow-lg);
        animation: slideUp 0.3s ease;
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
        padding: 24px 28px 0;
    }

    .modal-header h3 {
        font-size: 1.1rem;
        font-weight: 700;
    }

    .modal-close {
        background: transparent;
        color: var(--color-text-muted);
        padding: 4px;
        transition: color var(--transition-fast);
    }

    .modal-close:hover {
        color: var(--color-text);
    }

    .modal-body {
        padding: 24px 28px 28px;
    }

    .form-group {
        margin-bottom: 16px;
    }

    .form-row {
        display: flex;
        gap: 16px;
    }

    .flex-1 {
        flex: 1;
    }

    .form-group label {
        display: block;
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--color-text-muted);
        margin-bottom: 8px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .form-group input,
    .form-group select {
        width: 100%;
        padding: 12px 16px;
        background: var(--color-bg-input);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-md);
        color: var(--color-text);
        font-size: 0.9rem;
        transition:
            border-color var(--transition-fast),
            box-shadow var(--transition-fast);
    }

    .form-group select {
        cursor: pointer;
        appearance: none;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='%238888a8' viewBox='0 0 16 16'%3E%3Cpath d='M8 11L3 6h10l-5 5z'/%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: right 14px center;
        padding-right: 36px;
    }

    .form-group input::placeholder {
        color: var(--color-text-faint);
    }

    .form-group input:focus,
    .form-group select:focus {
        border-color: var(--color-border-focus);
        box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.15);
    }

    .image-upload-container {
        position: relative;
        border: 2px dashed var(--color-border);
        border-radius: var(--radius-md);
        padding: 24px;
        text-align: center;
        cursor: pointer;
        transition: all var(--transition-fast);
        background: var(--color-bg-input);
    }

    .image-upload-container:hover {
        border-color: var(--color-primary);
        background: rgba(108, 99, 255, 0.03);
    }

    .image-input {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        opacity: 0;
        cursor: pointer;
    }

    .image-placeholder {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;
        color: var(--color-text-faint);
    }

    .image-placeholder span {
        font-size: 0.85rem;
    }

    .image-preview {
        max-width: 200px;
        max-height: 150px;
        margin: 0 auto;
        border-radius: var(--radius-sm);
        overflow: hidden;
    }

    .image-preview img {
        width: 100%;
        height: 100%;
        object-fit: cover;
    }

    .form-error {
        padding: 10px 14px;
        background: rgba(255, 77, 106, 0.08);
        border: 1px solid rgba(255, 77, 106, 0.2);
        border-radius: var(--radius-sm);
        color: var(--color-danger);
        font-size: 0.8rem;
        margin-bottom: 16px;
    }

    .modal-actions {
        display: flex;
        gap: 12px;
        justify-content: flex-end;
    }

    .btn-cancel {
        padding: 10px 20px;
        border-radius: var(--radius-sm);
        background: transparent;
        border: 1px solid var(--color-border);
        color: var(--color-text);
        font-size: 0.85rem;
        font-weight: 600;
        transition: all var(--transition-fast);
    }

    .btn-cancel:hover {
        border-color: var(--color-text-muted);
    }

    .btn-submit {
        padding: 10px 24px;
        border-radius: var(--radius-sm);
        background: var(--gradient-primary);
        color: white;
        font-size: 0.85rem;
        font-weight: 600;
        transition: all var(--transition-fast);
    }

    .btn-submit:hover {
        box-shadow: var(--shadow-glow);
        transform: translateY(-1px);
    }

    @media (max-width: 640px) {
        .form-row {
            flex-direction: column;
            gap: 0;
        }
        .top-actions {
            flex-direction: column;
            align-items: stretch;
        }
        .search-bar {
            max-width: 100%;
        }
    }
</style>
