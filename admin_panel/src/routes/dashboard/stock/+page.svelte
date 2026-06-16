<script lang="ts">
    import { onMount } from "svelte";
    import {
        fetchProducts,
        createProduct,
        deleteProduct,
        fetchUnits,
        createUnit,
        deleteUnit,
        type UnitItem,
    } from "$lib/api";
    import {
        initProductsWebSocket,
        onProductCreated,
        onProductUpdated,
        onProductDeleted,
        disconnectProductsWebSocket,
    } from "$lib/products_websocket";

    // ---- Stock Management ----
    interface Variant {
        id: number;
        unitName: string;
        price: number;
        stock: number;
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

    // Per-variant stock inputs (when adding a new product)
    interface VariantDraft {
        unitName: string;
        price: string;
        stock: string;
    }
    let newVariants = $state<VariantDraft[]>([
        { unitName: "KG", price: "", stock: "" },
    ]);

    // ---- Toast Notification ----
    let toastMessage = $state("");
    let toastType = $state<"success" | "error">("success");
    let toastVisible = $state(false);
    let toastTimer: ReturnType<typeof setTimeout> | null = null;

    function showToast(message: string, type: "success" | "error" = "success") {
        toastMessage = message;
        toastType = type;
        toastVisible = true;
        if (toastTimer) clearTimeout(toastTimer);
        toastTimer = setTimeout(() => {
            toastVisible = false;
        }, 3000);
    }

    import { onDestroy } from "svelte";

    // ---- Units of measure (loaded from backend so customer + admin stay in sync) ----
    let unitOptions = $state<string[]>([
        "KG",
        "Box",
        "Sack - 25kg",
        "Sack - 50kg",
        "Piece",
    ]);
    let units = $state<UnitItem[]>([]);
    let showUnitsModal = $state(false);
    let newUnitName = $state("");
    let unitFormError = $state("");
    let deletingUnitId = $state<number | null>(null);

    let refreshInterval: ReturnType<typeof setInterval>;

    async function loadUnits() {
        try {
            const list = await fetchUnits();
            units = list;
            unitOptions = list.map((u) => u.name);
        } catch (e) {
            console.error("Failed to load units:", e);
        }
    }

    async function handleAddUnit() {
        const name = newUnitName.trim();
        if (!name) {
            unitFormError = "Nama unit tidak boleh kosong";
            return;
        }
        unitFormError = "";
        try {
            await createUnit(name);
            newUnitName = "";
            await loadUnits();
        } catch (e: any) {
            unitFormError = e?.message ?? "Gagal menambah unit";
        }
    }

    async function handleDeleteUnit(id: number) {
        deletingUnitId = id;
        try {
            await deleteUnit(id);
            await loadUnits();
        } catch (e: any) {
            showToast(e?.message ?? "Gagal menghapus unit", "error");
        } finally {
            deletingUnitId = null;
        }
    }

    onMount(async () => {
        await Promise.all([loadProducts(), loadUnits()]);
        // Auto-refresh every 30 seconds
        refreshInterval = setInterval(() => {
            loadProducts();
        }, 30000);
        // Initialize WebSocket for real-time updates
        initProductsWebSocket();
        onProductCreated(() => loadProducts());
        onProductUpdated(() => loadProducts());
        onProductDeleted(() => loadProducts());
    });

    onDestroy(() => {
        if (refreshInterval) clearInterval(refreshInterval);
        if (toastTimer) clearTimeout(toastTimer);
        disconnectProductsWebSocket();
    });

    async function loadProducts() {
        try {
            isLoading = true;
            const products = await fetchProducts();
            items = products.map((p: any) => {
                const variants = (p.variants ?? []).map((v: any) => ({
                    id: v.id,
                    unitName: v.unitName,
                    price: Number(v.price),
                    stock: v.stock ?? 0,
                }));
                // If the product has variants, the row-level "stock" column
                // is the sum of all variant stocks so admins can still see a
                // single "total" number at a glance.
                const totalStock =
                    variants.length > 0
                        ? variants.reduce(
                              (s: number, v: { stock: number }) => s + v.stock,
                              0,
                          )
                        : (p.stock ?? 0);
                return {
                    id: p.id,
                    name: p.name,
                    price: Number(p.price),
                    stock: totalStock,
                    unit: p.unit ?? "Piece",
                    leadTime: p.leadTime ?? 3,
                    safetyStock: p.safetyStock ?? 5,
                    sold: p.sold ?? 0,
                    variants,
                };
            });
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
        const leadTime = item.leadTime ?? 3;
        const safetyStock = item.safetyStock ?? 5;
        const stock = item.stock ?? 0;
        const sold = item.sold ?? 0;

        // Note: 'sold' is cumulative lifetime sales, NOT recent 7-day average
        // For products with high cumulative sales, velocity-based ROP is unreliable
        // Use simplified threshold based on safetyStock for high-sold products

        if (sold === 0) {
            // New product with no sales - use safetyStock as threshold
            return stock <= safetyStock;
        }

        if (sold < 7) {
            // Very few sales - use simplified ROP: safetyStock + leadTime
            const rop = safetyStock + leadTime;
            return stock <= rop;
        }

        // For products with significant sales but not extremely high
        // Use a moderate ROP that doesn't inflate due to cumulative totals
        // Cap avgDailySales contribution to avoid extreme ROP values
        const avgDailySales = Math.min(sold / 7, 10); // Cap at 10 units/day for ROP calculation
        const rop = (leadTime * avgDailySales) + safetyStock;
        return stock <= rop;
    }

    function openModal() {
        newName = "";
        newPrice = "";
        newStock = "";
        newUnit = "KG";
        newImage = null;
        newImagePreview = "";
        formError = "";
        newVariants = [{ unitName: "KG", price: "", stock: "" }];
        showModal = true;
    }

    function addVariantDraft() {
        newVariants = [
            ...newVariants,
            { unitName: unitOptions[0] ?? "Piece", price: "", stock: "" },
        ];
    }

    function removeVariantDraft(idx: number) {
        newVariants = newVariants.filter((_, i) => i !== idx);
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

        if (!nameVal) {
            formError = "Item name is required";
            return;
        }

        // Validate every variant row
        const cleanVariants: {
            unitName: string;
            price: number;
            stock: number;
        }[] = [];
        for (let i = 0; i < newVariants.length; i++) {
            const v = newVariants[i];
            const unit = v.unitName.trim();
            const price = Number(String(v.price).trim());
            const stock = Number(String(v.stock).trim() || "0");
            if (!unit) {
                formError = `Variant #${i + 1}: unit wajib dipilih`;
                return;
            }
            if (!v.price || isNaN(price) || price <= 0) {
                formError = `Variant #${i + 1}: harga harus angka > 0`;
                return;
            }
            if (isNaN(stock) || stock < 0) {
                formError = `Variant #${i + 1}: stok harus angka ≥ 0`;
                return;
            }
            cleanVariants.push({ unitName: unit, price, stock });
        }

        if (cleanVariants.length === 0) {
            formError = "Minimal 1 variant harus diisi";
            return;
        }

        // Keep the legacy single-unit form fields populated so the rest of the
        // submit pipeline (and the backend dto.stock) still get sensible values
        // for the *primary* variant. The backend will create a variant from
        // these and add the rest via the variants array.
        const first = cleanVariants[0];
        const primaryPrice = String(first.price);
        const primaryStock = String(first.stock);
        const primaryUnit = first.unitName;

        try {
            // The current API only accepts a single stock/unit per call, so we
            // sequentially upsert each variant. createProduct handles the
            // "product already exists" case by adding a new variant row.
            for (let i = 0; i < cleanVariants.length; i++) {
                const v = cleanVariants[i];
                const isLast = i === cleanVariants.length - 1;
                const result = await createProduct({
                    name: nameVal,
                    price: v.price,
                    stock: v.stock,
                    unit: v.unitName,
                    image: isLast ? newImage : null,
                });

                if (!isLast && result?.action !== "updated") {
                    // First insert created the product; subsequent calls
                    // would create a *new* product with the same name. Bail.
                    throw new Error(
                        "Gagal menambah variant lanjutan: produk belum ada",
                    );
                }
            }

            // Show the total stock summed across all variants
            const totalStock = cleanVariants.reduce((s, v) => s + v.stock, 0);
            showToast(
                `✅ Produk disimpan (${cleanVariants.length} variant, total stok ${totalStock})`,
                "success",
            );

            await loadProducts();
            closeModal();
        } catch (e: any) {
            formError =
                e?.message ?? "Failed to save item. Please try again.";
            showToast("❌ Gagal menyimpan produk", "error");
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
        <button class="btn-units" onclick={() => (showUnitsModal = true)} id="btn-manage-units">
            <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                ><circle cx="12" cy="12" r="3" /><path
                    d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"
                /></svg
            >
            Kelola Unit
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
                                            <span class="variant-badge">
                                                {variant.unitName}: {variant.stock}
                                            </span>
                                        {/each}
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </td>
                    <td class="col-price">{formatRupiah(item.price)}</td>
                    <td>
                        <div class="stock-cell">
                            <span
                                class="stock-badge"
                                class:low={item.stock <= 20}
                                class:medium={item.stock > 20 && item.stock <= 50}
                                class:high={item.stock > 50}
                            >
                                {item.stock}
                            </span>
                            {#if item.variants.length > 0}
                                <span class="stock-hint">
                                    ({item.variants.length} variant)
                                </span>
                            {/if}
                        </div>
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
                <div class="form-group">
                    <label>Variants (Unit, Price, Stock)</label>
                    <p class="form-hint">
                        Setiap variant punya stok sendiri. Mis. Aqua Galon bisa
                        punya unit "Piece" stok 60 dan "Galon" stok 30 — keduanya
                        tidak tercampur.
                    </p>
                    <div class="variant-drafts">
                        {#each newVariants as variant, idx (idx)}
                            <div class="variant-draft-row">
                                <select
                                    bind:value={variant.unitName}
                                    aria-label="Unit {idx + 1}"
                                >
                                    {#each unitOptions as opt}
                                        <option value={opt}>{opt}</option>
                                    {/each}
                                </select>
                                <input
                                    type="text"
                                    inputmode="numeric"
                                    placeholder="Harga"
                                    bind:value={variant.price}
                                    aria-label="Price for variant {idx + 1}"
                                />
                                <input
                                    type="text"
                                    inputmode="numeric"
                                    placeholder="Stok"
                                    bind:value={variant.stock}
                                    aria-label="Stock for variant {idx + 1}"
                                />
                                <button
                                    type="button"
                                    class="variant-remove"
                                    onclick={() => removeVariantDraft(idx)}
                                    aria-label="Hapus variant"
                                    disabled={newVariants.length === 1}
                                >
                                    ×
                                </button>
                            </div>
                        {/each}
                    </div>
                    <button
                        type="button"
                        class="btn-add-variant"
                        onclick={addVariantDraft}
                    >
                        + Tambah Variant
                    </button>
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

<!-- Toast Notification -->
{#if toastVisible}
    <div class="toast toast--{toastType}" role="status" aria-live="polite">
        {toastMessage}
    </div>
{/if}

<!-- ===== Manage Units Modal ===== -->
{#if showUnitsModal}
    <div
        class="modal-backdrop"
        onclick={() => (showUnitsModal = false)}
        onkeydown={(e) => e.key === "Escape" && (showUnitsModal = false)}
        role="button"
        tabindex="-1"
        aria-label="Close units modal"
    >
        <div
            class="modal-card"
            onclick={(e) => e.stopPropagation()}
            onkeydown={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
        >
            <div class="modal-header">
                <h2>Kelola Unit of Measure</h2>
                <button
                    class="modal-close"
                    onclick={() => (showUnitsModal = false)}
                    aria-label="Close">×</button
                >
            </div>

            <div class="modal-body">
                <p class="modal-hint">
                    Unit yang ditambah akan tersedia di form Add Item dan di app
                    customer.
                </p>

                <div class="units-list">
                    {#each units as u (u.id)}
                        <div class="unit-row">
                            <span class="unit-name">
                                {u.name}
                                {#if u.isDefault}
                                    <span class="unit-badge">default</span>
                                {/if}
                            </span>
                            {#if !u.isDefault}
                                <button
                                    class="unit-delete"
                                    disabled={deletingUnitId === u.id}
                                    onclick={() => handleDeleteUnit(u.id)}
                                    aria-label="Hapus unit"
                                >
                                    {deletingUnitId === u.id ? "..." : "×"}
                                </button>
                            {/if}
                        </div>
                    {/each}
                </div>

                <div class="unit-add-form">
                    <input
                        type="text"
                        placeholder="Unit baru (contoh: Lusin, Pack)"
                        bind:value={newUnitName}
                        onkeydown={(e) => e.key === "Enter" && handleAddUnit()}
                        id="input-new-unit"
                    />
                    <button class="btn-add-unit" onclick={handleAddUnit}
                        >Tambah</button
                    >
                </div>
                {#if unitFormError}
                    <div class="form-error">{unitFormError}</div>
                {/if}
            </div>

            <div class="modal-footer">
                <button
                    class="btn-secondary"
                    onclick={() => (showUnitsModal = false)}>Tutup</button
                >
            </div>
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

    /* ===== Manage Units Button ===== */
    .btn-units {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: var(--color-bg-card);
        color: var(--color-text);
        border: 1px solid var(--color-border);
        padding: 8px 16px;
        border-radius: var(--radius-md, 8px);
        font-weight: 600;
        font-size: 14px;
        cursor: pointer;
        transition: all 0.2s;
    }
    .btn-units:hover {
        background: var(--color-primary, #6c63ff);
        color: white;
        border-color: var(--color-primary, #6c63ff);
    }

    /* ===== Modal ===== */
    .modal-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 20px;
    }
    .modal-card {
        background: var(--color-bg-card, white);
        border-radius: var(--radius-lg, 12px);
        width: 100%;
        max-width: 480px;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
    }
    .modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 20px 24px;
        border-bottom: 1px solid var(--color-border, #e5e7eb);
    }
    .modal-header h2 {
        font-size: 18px;
        font-weight: 700;
        margin: 0;
    }
    .modal-close {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: var(--color-text-secondary, #6b7280);
        line-height: 1;
    }
    .modal-body {
        padding: 20px 24px;
    }
    .modal-hint {
        font-size: 13px;
        color: var(--color-text-secondary, #6b7280);
        margin: 0 0 16px;
    }
    .modal-footer {
        padding: 16px 24px;
        border-top: 1px solid var(--color-border, #e5e7eb);
        display: flex;
        justify-content: flex-end;
        gap: 8px;
    }
    .btn-secondary {
        background: var(--color-bg-card, white);
        color: var(--color-text);
        border: 1px solid var(--color-border, #e5e7eb);
        padding: 8px 16px;
        border-radius: var(--radius-md, 8px);
        cursor: pointer;
        font-weight: 600;
    }
    .btn-secondary:hover {
        background: var(--color-bg, #f3f4f6);
    }

    .units-list {
        display: flex;
        flex-direction: column;
        gap: 8px;
        margin-bottom: 20px;
    }
    .unit-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 10px 14px;
        background: var(--color-bg, #f9fafb);
        border: 1px solid var(--color-border, #e5e7eb);
        border-radius: 8px;
    }
    .unit-name {
        font-weight: 500;
        font-size: 14px;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .unit-badge {
        font-size: 10px;
        background: var(--color-primary, #6c63ff);
        color: white;
        padding: 2px 8px;
        border-radius: 999px;
        text-transform: uppercase;
        font-weight: 700;
        letter-spacing: 0.5px;
    }
    .unit-delete {
        background: none;
        border: 1px solid var(--color-border, #e5e7eb);
        color: #ef4444;
        width: 28px;
        height: 28px;
        border-radius: 6px;
        cursor: pointer;
        font-size: 18px;
        line-height: 1;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    .unit-delete:hover:not(:disabled) {
        background: #fee2e2;
        border-color: #ef4444;
    }
    .unit-delete:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }
    .unit-add-form {
        display: flex;
        gap: 8px;
    }
    .unit-add-form input {
        flex: 1;
        padding: 8px 12px;
        border: 1px solid var(--color-border, #e5e7eb);
        border-radius: 8px;
        font-size: 14px;
    }
    .btn-add-unit {
        background: var(--color-primary, #6c63ff);
        color: white;
        border: none;
        padding: 8px 16px;
        border-radius: 8px;
        cursor: pointer;
        font-weight: 600;
    }
    .btn-add-unit:hover {
        background: var(--color-primary-hover, #5a52d5);
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

    .stock-cell {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 2px;
    }
    .stock-hint {
        font-size: 0.7rem;
        color: var(--color-text-secondary, #6b7280);
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

    .form-hint {
        font-size: 12px;
        color: var(--color-text-secondary, #6b7280);
        margin: 4px 0 12px;
    }

    .variant-drafts {
        display: flex;
        flex-direction: column;
        gap: 8px;
        margin-bottom: 8px;
    }
    .variant-draft-row {
        display: grid;
        grid-template-columns: 1.2fr 1fr 0.8fr 36px;
        gap: 6px;
        align-items: center;
    }
    .variant-draft-row select,
    .variant-draft-row input {
        padding: 8px 10px;
        border: 1px solid var(--color-border, #e5e7eb);
        border-radius: var(--radius-sm, 6px);
        font-size: 13px;
        background: var(--color-bg-card, white);
        color: var(--color-text);
    }
    .variant-remove {
        width: 32px;
        height: 32px;
        background: none;
        border: 1px solid var(--color-border, #e5e7eb);
        color: #ef4444;
        border-radius: var(--radius-sm, 6px);
        font-size: 18px;
        line-height: 1;
        cursor: pointer;
    }
    .variant-remove:hover:not(:disabled) {
        background: #fee2e2;
        border-color: #ef4444;
    }
    .variant-remove:disabled {
        opacity: 0.4;
        cursor: not-allowed;
    }
    .btn-add-variant {
        background: none;
        border: 1px dashed var(--color-border, #d1d5db);
        color: var(--color-primary, #6c63ff);
        padding: 8px 12px;
        border-radius: var(--radius-sm, 6px);
        cursor: pointer;
        font-size: 13px;
        font-weight: 600;
    }
    .btn-add-variant:hover {
        background: rgba(108, 99, 255, 0.06);
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

    /* ===== Toast Notification ===== */
    .toast {
        position: fixed;
        top: 24px;
        right: 24px;
        z-index: 200;
        padding: 14px 22px;
        border-radius: 10px;
        font-size: 0.9rem;
        font-weight: 600;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
        animation: toastSlide 0.3s ease;
        max-width: 420px;
    }

    .toast--success {
        background: rgba(0, 212, 170, 0.95);
        color: white;
        border: 1px solid rgba(0, 212, 170, 0.5);
    }

    .toast--error {
        background: rgba(255, 77, 106, 0.95);
        color: white;
        border: 1px solid rgba(255, 77, 106, 0.5);
    }

    @keyframes toastSlide {
        from {
            transform: translateX(120%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
</style>
