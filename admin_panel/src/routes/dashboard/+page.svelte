<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import {
        fetchOrderStats,
        fetchDashboardTimeSlots,
        fetchOrdersBySlot,
        setTimeSlotActive,
        fetchEmployees,
        type DashboardSlot,
        type SlotOrder,
    } from "$lib/api";

    // ---- Dashboard Stats & Charts ----
    let stats = $state([
        { label: "Total Employee", value: "0", icon: "employee", color: "#6c63ff" },
        { label: "Revenue Today", value: "Rp 0", icon: "revenue", color: "#00d4aa" },
        { label: "Total Orders Today", value: "0", icon: "orders-today", color: "#42a5f5" },
        { label: "Total Orders This Month", value: "0", icon: "orders-month", color: "#ffb74d" },
    ]);

    let ordersToday = $state(Array.from({ length: 24 }, () => 0));
    let ordersMonth = $state(Array.from({ length: 30 }, () => 0));

    let maxOrderToday = $derived(Math.max(...ordersToday, 1));
    let maxOrderMonth = $derived(Math.max(...ordersMonth, 1));

    const hoursLabels = Array.from(
        { length: 24 },
        (_, i) => `${i.toString().padStart(2, "0")}:00`,
    );

    // ---- Time Slot Chart State ----
    let slotData = $state<DashboardSlot[]>([]);
    let maxOrderPerSlot = $derived(Math.max(0, ...slotData.map((s) => s.orderCount), 1));

    // ---- Slot Detail Modal ----
    let showSlotModal = $state(false);
    let selectedSlot = $state<DashboardSlot | null>(null);
    let slotOrders = $state<SlotOrder[]>([]);
    let loadingSlotOrders = $state(false);
    let togglingSlot = $state(false);
    let slotActionError = $state("");

    function getTodayDate(): string {
        return new Date().toISOString().split("T")[0];
    }

    let pollInterval: any = $state(null);

    onMount(async () => {
        await loadStats();
        await loadSlotData();
        // Start polling every 30 seconds for real-time updates
        pollInterval = setInterval(() => {
            loadStats();
            loadSlotData();
        }, 30000);
    });

    onDestroy(() => {
        if (pollInterval) {
            clearInterval(pollInterval);
        }
    });

    async function loadStats() {
        try {
            const [data, employees] = await Promise.all([
                fetchOrderStats(),
                fetchEmployees(),
            ]);
            const revenue = Number(data.revenueToday || 0);
            stats = [
                { label: "Total Employee", value: String(employees.length), icon: "employee", color: "#6c63ff" },
                { label: "Revenue Today", value: "Rp " + revenue.toLocaleString("id-ID"), icon: "revenue", color: "#00d4aa" },
                { label: "Total Orders Today", value: String(data.totalOrdersToday || 0), icon: "orders-today", color: "#42a5f5" },
                { label: "Total Orders This Month", value: String(data.totalOrdersThisMonth || 0), icon: "orders-month", color: "#ffb74d" },
            ];
            if (data.ordersPerHour) ordersToday = data.ordersPerHour;
            if (data.ordersPerDay) ordersMonth = data.ordersPerDay;
        } catch (e) {
            console.error("Failed to load dashboard stats:", e);
        }
    }

    async function loadSlotData() {
        try {
            slotData = await fetchDashboardTimeSlots(getTodayDate());
        } catch (e) {
            console.error("Failed to load slot data:", e);
        }
    }

    async function openSlotModal(slot: DashboardSlot) {
        selectedSlot = slot;
        slotOrders = [];
        slotActionError = "";
        showSlotModal = true;
        await loadSlotOrders();
    }

    function closeSlotModal() {
        showSlotModal = false;
        selectedSlot = null;
        slotOrders = [];
        slotActionError = "";
    }

    async function loadSlotOrders() {
        if (!selectedSlot) return;
        try {
            loadingSlotOrders = true;
            slotOrders = await fetchOrdersBySlot(getTodayDate(), selectedSlot.time);
        } catch (e) {
            console.error("Failed to load slot orders:", e);
            slotActionError = "Gagal memuat pesanan di slot ini.";
        } finally {
            loadingSlotOrders = false;
        }
    }

    async function toggleSlot() {
        if (!selectedSlot) return;
        const action = selectedSlot.isActive ? "menonaktifkan" : "mengaktifkan";
        const confirmed = confirm(
            `Apakah Anda yakin ingin ${action} slot ${selectedSlot.time}?`,
        );
        if (!confirmed) return;

        try {
            togglingSlot = true;
            slotActionError = "";
            const newState = !selectedSlot.isActive;
            const result = await setTimeSlotActive(selectedSlot.slotId, newState);
            // Update local state
            selectedSlot = { ...selectedSlot, isActive: result.slot.isActive };
            slotData = slotData.map((s) =>
                s.slotId === selectedSlot!.slotId
                    ? { ...s, isActive: result.slot.isActive }
                    : s,
            );
        } catch (e) {
            console.error("Failed to toggle slot:", e);
            slotActionError =
                e instanceof Error
                    ? e.message
                    : "Gagal mengubah status slot.";
        } finally {
            togglingSlot = false;
        }
    }

    function formatCurrency(n: number): string {
        return "Rp " + n.toLocaleString("id-ID");
    }

    function formatTime(dateStr: string): string {
        try {
            const d = new Date(dateStr);
            return `${d.getHours().toString().padStart(2, "0")}:${d
                .getMinutes()
                .toString()
                .padStart(2, "0")}`;
        } catch {
            return "-";
        }
    }

    function statusLabel(status: string): string {
        const map: Record<string, string> = {
            pending: "Pending",
            pending_payment: "Pending Payment",
            pickingUp: "Picking Up",
            pickedUp: "Picked Up",
            delivering: "Delivering",
            delivered: "Delivered",
            cancelled: "Cancelled",
        };
        return map[status] ?? status;
    }
</script>

<!-- Stats Grid -->
<section class="stats-grid">
    {#each stats as stat}
        <div class="stat-card">
            <div
                class="stat-icon"
                style="background: {stat.color}15; color: {stat.color}"
            >
                {#if stat.icon === "employee"}
                    <svg
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        ><path
                            d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"
                        /><circle cx="9" cy="7" r="4" /><path
                            d="M23 21v-2a4 4 0 00-3-3.87"
                        /><path d="M16 3.13a4 4 0 010 7.75" /></svg
                    >
                {:else if stat.icon === "revenue"}
                    <svg
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        ><line x1="12" y1="1" x2="12" y2="23" /><path
                            d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"
                        /></svg
                    >
                {:else if stat.icon === "orders-today"}
                    <svg
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        ><path
                            d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"
                        /><line x1="3" y1="6" x2="21" y2="6" /></svg
                    >
                {:else if stat.icon === "orders-month"}
                    <svg
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        ><rect
                            x="3"
                            y="4"
                            width="18"
                            height="18"
                            rx="2"
                            ry="2"
                        /><line x1="16" y1="2" x2="16" y2="6" /><line
                            x1="8"
                            y1="2"
                            x2="8"
                            y2="6"
                        /><line x1="3" y1="10" x2="21" y2="10" /></svg
                    >
                {/if}
            </div>
            <div class="stat-info">
                <p class="stat-label">{stat.label}</p>
                <p class="stat-value">{stat.value}</p>
            </div>
        </div>
    {/each}
</section>

<!-- Charts -->
<section class="charts-grid">
    <!-- Orders Today Chart -->
    <div class="chart-card">
        <div class="chart-header">
            <h3 class="chart-title">Total Orders Today</h3>
            <span class="chart-badge">Hourly</span>
        </div>
        <div class="chart-area">
            <div class="bar-chart">
                {#each ordersToday as val, i}
                    <div class="bar-col" title="{hoursLabels[i]}: {val} orders">
                        <div
                            class="bar"
                            style="height: {maxOrderToday > 0
                                ? (val / maxOrderToday) * 100
                                : 0}%; background: {val === maxOrderToday &&
                            val > 0
                                ? 'var(--color-accent)'
                                : 'var(--color-primary)'};"
                        ></div>
                        {#if i % 3 === 0}
                            <span class="bar-label">{i}h</span>
                        {/if}
                    </div>
                {/each}
            </div>
        </div>
        <div class="chart-footer">
            <span class="chart-total"
                >Total: <strong>{ordersToday.reduce((a, b) => a + b, 0)}</strong
                > orders</span
            >
            <span class="chart-peak"
                >Peak: <strong
                    >{hoursLabels[ordersToday.indexOf(maxOrderToday)]}</strong
                ></span
            >
        </div>
    </div>

    <!-- Orders This Month Chart -->
    <div class="chart-card">
        <div class="chart-header">
            <h3 class="chart-title">Total Orders This Month</h3>
            <span class="chart-badge">Daily</span>
        </div>
        <div class="chart-area">
            <div class="bar-chart bar-chart--month">
                {#each ordersMonth as val, i}
                    <div class="bar-col" title="Day {i + 1}: {val} orders">
                        <div
                            class="bar"
                            style="height: {maxOrderMonth > 0
                                ? (val / maxOrderMonth) * 100
                                : 0}%; background: {val === maxOrderMonth
                                ? 'var(--color-accent)'
                                : 'var(--color-info)'};"
                        ></div>
                        {#if (i + 1) % 5 === 0 || i === 0}
                            <span class="bar-label">{i + 1}</span>
                        {/if}
                    </div>
                {/each}
            </div>
        </div>
        <div class="chart-footer">
            <span class="chart-total"
                >Total: <strong>{ordersMonth.reduce((a, b) => a + b, 0)}</strong
                > orders</span
            >
            <span class="chart-peak"
                >Avg: <strong
                    >{Math.round(
                        ordersMonth.reduce((a, b) => a + b, 0) /
                            ordersMonth.length,
                    )}</strong
                >/day</span
            >
        </div>
    </div>
</section>

<!-- Time Slot Bookings Today -->
<section class="chart-card slot-section">
    <div class="chart-header">
        <h3 class="chart-title">Time Slot Bookings Hari Ini</h3>
        <div class="slot-header-right">
            <span class="chart-badge">30-min</span>
            <span class="chart-legend">
                <span class="legend-dot legend-dot--active"></span> Aktif
                <span class="legend-dot legend-dot--disabled"></span> Disabled
            </span>
        </div>
    </div>
    <div class="chart-area chart-area--slots">
        {#if slotData.length === 0}
            <div class="slot-empty">Memuat data slot...</div>
        {:else}
            <div class="bar-chart bar-chart--slots">
                {#each slotData as slot (slot.slotId)}
                    <button
                        type="button"
                        class="bar-col bar-col--slot"
                        class:bar-col--disabled={!slot.isActive}
                        title={`${slot.time} - ${slot.orderCount} pesanan - ${slot.isActive ? "Aktif" : "Disabled"}`}
                        onclick={() => openSlotModal(slot)}
                    >
                        <div class="bar-value">{slot.orderCount}</div>
                        <div
                            class="bar"
                            style="height: {maxOrderPerSlot > 0
                                ? (slot.orderCount / maxOrderPerSlot) * 100
                                : 0}%; background: {!slot.isActive
                                ? 'var(--color-text-faint)'
                                : slot.orderCount === maxOrderPerSlot && slot.orderCount > 0
                                    ? 'var(--color-accent)'
                                    : 'var(--color-primary)'};"
                        ></div>
                        <span class="bar-label">{slot.time}</span>
                        {#if !slot.isActive}
                            <span class="bar-flag">OFF</span>
                        {/if}
                    </button>
                {/each}
            </div>
        {/if}
    </div>
    <div class="chart-footer">
        <span class="chart-total">
            Total order: <strong>{slotData.reduce((a, s) => a + s.orderCount, 0)}</strong>
        </span>
        <span class="chart-peak">
            Slot aktif:
            <strong
                >{slotData.filter((s) => s.isActive).length}/{slotData.length}</strong
            >
        </span>
    </div>
</section>

<!-- Slot Detail Modal -->
{#if showSlotModal && selectedSlot}
    <div
        class="modal-backdrop"
        onclick={closeSlotModal}
        onkeydown={(e) => e.key === "Escape" && closeSlotModal()}
        role="button"
        tabindex="-1"
    >
        <div
            class="modal-content"
            onclick={(e) => e.stopPropagation()}
            onkeydown={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
        >
            <div class="modal-header">
                <div>
                    <h3 class="modal-title">
                        Pesanan Jam {selectedSlot.time}
                    </h3>
                    <p class="modal-subtitle">
                        {selectedSlot.orderCount} pesanan •
                        {selectedSlot.bookings}/{selectedSlot.maxBookings} booking •
                        {selectedSlot.isActive ? "Aktif" : "Disabled"}
                    </p>
                </div>
                <button
                    type="button"
                    class="modal-close"
                    onclick={closeSlotModal}
                    aria-label="Tutup"
                >
                    ×
                </button>
            </div>

            <div class="modal-body">
                {#if slotActionError}
                    <div class="alert-error">{slotActionError}</div>
                {/if}

                {#if loadingSlotOrders}
                    <div class="slot-empty">Memuat pesanan...</div>
                {:else if slotOrders.length === 0}
                    <div class="slot-empty">
                        Tidak ada pesanan di slot ini hari ini.
                    </div>
                {:else}
                    <table class="orders-table">
                        <thead>
                            <tr>
                                <th>Order ID</th>
                                <th>Customer</th>
                                <th>Status</th>
                                <th>Driver</th>
                                <th>Waktu</th>
                                <th class="num">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each slotOrders as order (order.id)}
                                <tr>
                                    <td class="mono">#ORD-{String(order.id).padStart(3, "0")}</td>
                                    <td>
                                        <div class="cell-customer">
                                            <span>{order.customerName}</span>
                                            <span class="cell-sub">{order.customerPhone || "-"}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="status-pill status-{order.status}">
                                            {statusLabel(order.status)}
                                        </span>
                                    </td>
                                    <td>{order.driverName ?? "-"}</td>
                                    <td class="mono">{formatTime(order.createdAt)}</td>
                                    <td class="num">{formatCurrency(order.totalAmount)}</td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                {/if}
            </div>

            <div class="modal-footer">
                <button
                    type="button"
                    class="btn-secondary"
                    onclick={closeSlotModal}
                >
                    Tutup
                </button>
                <button
                    type="button"
                    class={selectedSlot.isActive ? "btn-danger" : "btn-primary"}
                    onclick={toggleSlot}
                    disabled={togglingSlot}
                >
                    {togglingSlot
                        ? "Memproses..."
                        : selectedSlot.isActive
                            ? "Nonaktifkan Slot Ini"
                            : "Aktifkan Slot Ini"}
                </button>
            </div>
        </div>
    </div>
{/if}

<style>
    /* ===== Stats Grid ===== */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 20px;
        margin-bottom: 28px;
    }

    .stat-card {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        padding: 24px;
        display: flex;
        align-items: center;
        gap: 16px;
        transition:
            transform var(--transition-fast),
            box-shadow var(--transition-fast);
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: var(--shadow-md);
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: var(--radius-md);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .stat-info {
        flex: 1;
    }

    .stat-label {
        font-size: 0.8rem;
        color: var(--color-text-muted);
        margin-bottom: 4px;
    }

    .stat-value {
        font-size: 1.25rem;
        font-weight: 700;
        color: var(--color-text);
    }

    /* ===== Charts ===== */
    .charts-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 20px;
    }

    .chart-card {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        padding: 24px;
    }

    .chart-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
    }

    .chart-title {
        font-size: 1rem;
        font-weight: 700;
    }

    .chart-badge {
        font-size: 0.7rem;
        font-weight: 600;
        padding: 4px 10px;
        border-radius: 20px;
        background: rgba(108, 99, 255, 0.1);
        color: var(--color-primary);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .chart-area {
        height: 180px;
        display: flex;
        align-items: flex-end;
    }

    .bar-chart {
        display: flex;
        align-items: flex-end;
        gap: 3px;
        width: 100%;
        height: 100%;
    }

    .bar-col {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        height: 100%;
        justify-content: flex-end;
        position: relative;
        cursor: pointer;
    }

    .bar {
        width: 100%;
        min-height: 2px;
        border-radius: 3px 3px 0 0;
        transition:
            height 0.5s ease,
            opacity var(--transition-fast);
        opacity: 0.8;
    }

    .bar-col:hover .bar {
        opacity: 1;
        filter: brightness(1.2);
    }

    .bar-label {
        font-size: 0.6rem;
        color: var(--color-text-faint);
        margin-top: 6px;
        white-space: nowrap;
    }

    .chart-footer {
        display: flex;
        justify-content: space-between;
        margin-top: 16px;
        font-size: 0.8rem;
        color: var(--color-text-muted);
    }

    @media (max-width: 1024px) {
        .charts-grid {
            grid-template-columns: 1fr;
        }
    }

    @media (max-width: 768px) {
        .stats-grid {
            grid-template-columns: 1fr 1fr;
        }
    }

    @media (max-width: 480px) {
        .stats-grid {
            grid-template-columns: 1fr;
        }
    }

    /* ===== Time Slot Section ===== */
    .slot-section {
        margin-top: 20px;
    }

    .slot-header-right {
        display: flex;
        align-items: center;
        gap: 14px;
    }

    .chart-legend {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 0.72rem;
        color: var(--color-text-muted);
    }

    .legend-dot {
        display: inline-block;
        width: 10px;
        height: 10px;
        border-radius: 3px;
        margin: 0 4px 0 8px;
    }

    .legend-dot--active {
        background: var(--color-primary);
    }

    .legend-dot--disabled {
        background: var(--color-text-faint);
    }

    .chart-area--slots {
        height: 200px;
    }

    .bar-chart--slots {
        gap: 4px;
    }

    .bar-col--slot {
        position: relative;
        background: transparent;
        border: 0;
        padding: 0;
        font: inherit;
        color: inherit;
        cursor: pointer;
    }

    .bar-col--slot:focus-visible {
        outline: 2px solid var(--color-primary);
        outline-offset: 2px;
        border-radius: 6px;
    }

    .bar-col--slot:hover .bar {
        filter: brightness(1.2);
    }

    .bar-col--disabled {
        cursor: pointer;
    }

    .bar-value {
        font-size: 0.7rem;
        font-weight: 700;
        color: var(--color-text);
        margin-bottom: 4px;
        min-height: 1em;
    }

    .bar-flag {
        position: absolute;
        top: 4px;
        right: 2px;
        font-size: 0.55rem;
        font-weight: 700;
        padding: 1px 4px;
        border-radius: 4px;
        background: rgba(255, 77, 106, 0.15);
        color: var(--color-danger);
        letter-spacing: 0.05em;
    }

    .slot-empty {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-text-muted);
        font-size: 0.85rem;
    }

    /* ===== Modal ===== */
    .modal-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(15, 14, 35, 0.65);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 100;
        padding: 24px;
        animation: fadeIn 0.2s ease;
    }

    .modal-content {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        width: 100%;
        max-width: 860px;
        max-height: 86vh;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        box-shadow: 0 24px 48px rgba(0, 0, 0, 0.4);
        animation: modalPop 0.2s ease;
    }

    @keyframes modalPop {
        from {
            transform: scale(0.96);
            opacity: 0;
        }
        to {
            transform: scale(1);
            opacity: 1;
        }
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        padding: 20px 24px;
        border-bottom: 1px solid var(--color-border);
    }

    .modal-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--color-text);
    }

    .modal-subtitle {
        font-size: 0.8rem;
        color: var(--color-text-muted);
        margin-top: 4px;
    }

    .modal-close {
        background: transparent;
        border: 0;
        font-size: 1.6rem;
        line-height: 1;
        color: var(--color-text-muted);
        cursor: pointer;
        padding: 0 6px;
        border-radius: 6px;
        transition: all var(--transition-fast);
    }

    .modal-close:hover {
        background: rgba(255, 77, 106, 0.1);
        color: var(--color-danger);
    }

    .modal-body {
        flex: 1;
        overflow-y: auto;
        padding: 16px 24px;
    }

    .modal-footer {
        display: flex;
        justify-content: flex-end;
        gap: 10px;
        padding: 16px 24px;
        border-top: 1px solid var(--color-border);
        background: rgba(0, 0, 0, 0.1);
    }

    .btn-secondary,
    .btn-primary,
    .btn-danger {
        padding: 9px 18px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.85rem;
        cursor: pointer;
        border: 0;
        transition: all var(--transition-fast);
    }

    .btn-secondary {
        background: rgba(255, 255, 255, 0.06);
        color: var(--color-text);
    }

    .btn-secondary:hover {
        background: rgba(255, 255, 255, 0.12);
    }

    .btn-primary {
        background: var(--color-primary);
        color: white;
    }

    .btn-primary:hover {
        filter: brightness(1.1);
    }

    .btn-danger {
        background: var(--color-danger);
        color: white;
    }

    .btn-danger:hover {
        filter: brightness(1.1);
    }

    .btn-secondary:disabled,
    .btn-primary:disabled,
    .btn-danger:disabled {
        opacity: 0.6;
        cursor: not-allowed;
    }

    .alert-error {
        background: rgba(255, 77, 106, 0.12);
        border: 1px solid rgba(255, 77, 106, 0.3);
        color: var(--color-danger);
        padding: 10px 14px;
        border-radius: 8px;
        font-size: 0.85rem;
        margin-bottom: 12px;
    }

    /* ===== Orders Table ===== */
    .orders-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 0.85rem;
    }

    .orders-table thead th {
        text-align: left;
        font-weight: 600;
        color: var(--color-text-muted);
        font-size: 0.75rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        padding: 8px 10px;
        border-bottom: 1px solid var(--color-border);
    }

    .orders-table tbody td {
        padding: 10px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.04);
    }

    .orders-table tbody tr:hover {
        background: rgba(108, 99, 255, 0.06);
    }

    .orders-table .num {
        text-align: right;
        font-variant-numeric: tabular-nums;
    }

    .orders-table .mono {
        font-family: ui-monospace, SFMono-Regular, monospace;
        font-size: 0.8rem;
    }

    .cell-customer {
        display: flex;
        flex-direction: column;
    }

    .cell-sub {
        font-size: 0.72rem;
        color: var(--color-text-muted);
    }

    .status-pill {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 10px;
        font-size: 0.7rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        background: rgba(108, 99, 255, 0.15);
        color: var(--color-primary);
    }

    .status-pill.status-delivered {
        background: rgba(0, 212, 170, 0.15);
        color: var(--color-accent);
    }

    .status-pill.status-cancelled {
        background: rgba(255, 77, 106, 0.15);
        color: var(--color-danger);
    }

    .status-pill.status-delivering,
    .status-pill.status-pickingUp,
    .status-pill.status-pickedUp {
        background: rgba(66, 165, 245, 0.15);
        color: #42a5f5;
    }
</style>
