<script lang="ts">
    import { onMount } from "svelte";
    import { fetchOrderStats } from "$lib/api";

    // ---- Dashboard Stats & Charts ----
    let stats = $state([
        { label: "Total Employee", value: "48", icon: "employee", color: "#6c63ff" },
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

    onMount(async () => {
        try {
            const data = await fetchOrderStats();
            const revenue = Number(data.revenueToday || 0);
            stats = [
                { label: "Total Employee", value: "48", icon: "employee", color: "#6c63ff" },
                { label: "Revenue Today", value: "Rp " + revenue.toLocaleString("id-ID"), icon: "revenue", color: "#00d4aa" },
                { label: "Total Orders Today", value: String(data.totalOrdersToday || 0), icon: "orders-today", color: "#42a5f5" },
                { label: "Total Orders This Month", value: String(data.totalOrdersThisMonth || 0), icon: "orders-month", color: "#ffb74d" },
            ];
            if (data.ordersPerHour) ordersToday = data.ordersPerHour;
            if (data.ordersPerDay) ordersMonth = data.ordersPerDay;
        } catch (e) {
            console.error("Failed to load dashboard stats:", e);
        }
    });
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
</style>
