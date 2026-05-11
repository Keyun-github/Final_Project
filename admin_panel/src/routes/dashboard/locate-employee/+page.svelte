<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { fetchAvailableDrivers, type Employee } from "$lib/api";

    let drivers = $state<Employee[]>([]);
    let isLoading = $state(true);
    let searchQuery = $state("");
    let expandedDriverId = $state<number | null>(null);
    let pollInterval: any = $state(null);

    onMount(async () => {
        await loadDrivers();
        pollInterval = setInterval(() => {
            loadDrivers();
        }, 30000);
    });

    onDestroy(() => {
        if (pollInterval) clearInterval(pollInterval);
    });

    async function loadDrivers() {
        try {
            isLoading = true;
            const data = await fetchAvailableDrivers();
            drivers = data;
        } catch (e) {
            console.error("Failed to load drivers:", e);
        } finally {
            isLoading = false;
        }
    }

    let filtered = $derived(
        searchQuery.trim()
            ? drivers.filter((d) =>
                  d.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                  (d.phone || "").includes(searchQuery),
              )
            : drivers,
    );

    function toggleExpand(id: number) {
        expandedDriverId = expandedDriverId === id ? null : id;
    }

    function getDriverById(id: number): Employee | undefined {
        return drivers.find((d) => d.id === id);
    }
</script>

<div class="page-header">
    <div class="header-title">
        <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
        >
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
            <circle cx="12" cy="10" r="3" />
        </svg>
        <h1>Lacak Driver</h1>
    </div>
    <p class="header-subtitle">
        Pantau lokasi driver yang sedang aktif. Klik "Lacak Lokasi" untuk
        melihat posisi driver di peta.
    </p>
</div>

<div class="search-bar">
    <svg
        class="search-icon"
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        ><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg
    >
    <input
        type="text"
        placeholder="Cari driver berdasarkan nama atau nomor telepon..."
        bind:value={searchQuery}
    />
    <button class="btn-refresh" onclick={loadDrivers}>
        <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
        >
            <path d="M21 2v6h-6" /><path
                d="M3 12a9 9 0 0 1 15-6.7L21 8"
            /><path d="M3 22v-6h6" /><path
                d="M21 12a9 9 0 0 1-15 6.7L3 16"
            />
        </svg>
        Refresh
    </button>
</div>

<div class="drivers-container">
    {#if isLoading}
        <div class="loading-state">
            <div class="spinner"></div>
            <p>Memuat data driver...</p>
        </div>
    {:else if drivers.length === 0}
        <div class="empty-state">
            <svg
                width="64"
                height="64"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1.5"
            >
                <path
                    d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"
                /><circle cx="9" cy="7" r="4" /><path
                    d="M23 21v-2a4 4 0 0 0-3-3.87"
                /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
            </svg>
            <h3>Belum Ada Driver On Duty</h3>
            <p>
                Saat ini belum ada driver yang sedang dalam status On Duty.
                Driver harus login di aplikasi kurir untuk dapat dilacak.
            </p>
        </div>
    {:else}
        <div class="drivers-count">
            <span class="count-badge">{drivers.length}</span>
            Driver sedang On Duty
        </div>

        <div class="drivers-table">
            <table>
                <thead>
                    <tr>
                        <th>No</th>
                        <th>Nama Driver</th>
                        <th>Nomor Telepon</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    {#each filtered as driver, i}
                        <tr class="driver-row" class:expanded={expandedDriverId === driver.id}>
                            <td class="col-no">{i + 1}</td>
                            <td>
                                <div class="driver-name">
                                    <div class="driver-avatar">{driver.name.charAt(0)}</div>
                                    <span>{driver.name}</span>
                                </div>
                            </td>
                            <td class="col-phone">
                                <span class="phone-badge">
                                    <svg
                                        width="14"
                                        height="14"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        stroke-width="2"
                                    >
                                        <path
                                            d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"
                                        />
                                    </svg>
                                    {driver.phone || "-"}
                                </span>
                            </td>
                            <td class="col-action">
                                <button
                                    class="btn-locate"
                                    class:active={expandedDriverId === driver.id}
                                    onclick={() => toggleExpand(driver.id)}
                                >
                                    <svg
                                        width="16"
                                        height="16"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        stroke-width="2"
                                    >
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                                        <circle cx="12" cy="10" r="3" />
                                    </svg>
                                    {expandedDriverId === driver.id
                                        ? "Tutup Peta"
                                        : "Lacak Lokasi"}
                                </button>
                            </td>
                        </tr>
                        {#if expandedDriverId === driver.id}
                            <tr class="expanded-row">
                                <td colspan="4">
                                    <div class="map-card">
                                        <div class="map-header-info">
                                            <h4>
                                                <svg
                                                    width="16"
                                                    height="16"
                                                    viewBox="0 0 24 24"
                                                    fill="none"
                                                    stroke="currentColor"
                                                    stroke-width="2"
                                                >
                                                    <path
                                                        d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"
                                                    />
                                                    <circle cx="12" cy="10" r="3" />
                                                </svg>
                                                Lokasi Driver
                                            </h4>
                                            <span class={driver.isAvailable ? 'status-tersedia' : 'status-on-duty'}>
                                                    {driver.isAvailable ? 'Tersedia' : 'On Duty'}
                                                </span>
                                        </div>
                                        <div class="map-placeholder">
                                            <div class="map-grid">
                                                <div class="map-road map-road-h1"></div>
                                                <div class="map-road map-road-h2"></div>
                                                <div class="map-road map-road-v1"></div>
                                                <div class="map-road map-road-v2"></div>
                                                <div class="driver-marker">
                                                    <div class="driver-marker-dot"></div>
                                                    <div class="driver-marker-pulse"></div>
                                                </div>
                                                <div class="destination-marker"></div>
                                                <div class="route-line"></div>
                                            </div>
                                            <div class="map-label">
                                                <span class="label-driver">Driver</span>
                                                <span class="label-destination">Tujuan</span>
                                            </div>
                                        </div>
                                        <div class="driver-info-row">
                                            <div class="info-item">
                                                <span class="info-label">Koordinat</span>
                                                <span class="info-value">
                                                    {driver.currentLat?.toFixed(4) ?? "-"},
                                                    {driver.currentLng?.toFixed(4) ?? "-"}
                                                </span>
                                            </div>
                                            {#if driver.vehiclePlate}
                                                <div class="info-item">
                                                    <span class="info-label">Kendaraan</span>
                                                    <span class="info-value">
                                                        {driver.vehiclePlate}
                                                        {#if driver.vehicleBrand}
                                                            - {driver.vehicleBrand}
                                                        {/if}
                                                        {#if driver.vehicleColor}
                                                            - {driver.vehicleColor}
                                                        {/if}
                                                    </span>
                                                </div>
                                            {/if}
                                        </div>
                                        <p class="map-note">
                                            📡 Peta akan menampilkan lokasi real-time saat
                                            driver mengaktifkan GPS di aplikasi kurir
                                        </p>
                                    </div>
                                </td>
                            </tr>
                        {/if}
                    {/each}
                    {#if filtered.length === 0}
                        <tr>
                            <td colspan="4" class="empty-state-search">
                                Tidak ada driver yang cocok dengan pencarian
                            </td>
                        </tr>
                    {/if}
                </tbody>
            </table>
        </div>
    {/if}
</div>

<style>
    .map-placeholder {
        width: 100%;
        height: 280px;
        background: #e8f0fe;
        border-radius: var(--radius-md);
        overflow: hidden;
        position: relative;
    }

    .map-grid {
        width: 100%;
        height: 100%;
        background: #e8f4f0;
        position: relative;
    }

    .map-road {
        position: absolute;
        background: rgba(255, 255, 255, 0.9);
        border: 1px solid rgba(0, 0, 0, 0.1);
    }

    .map-road-h1 {
        left: 0;
        right: 0;
        top: 35%;
        height: 20px;
    }

    .map-road-h2 {
        left: 0;
        right: 0;
        top: 65%;
        height: 20px;
    }

    .map-road-v1 {
        top: 0;
        bottom: 0;
        left: 30%;
        width: 20px;
    }

    .map-road-v2 {
        top: 0;
        bottom: 0;
        left: 70%;
        width: 20px;
    }

    .driver-marker {
        position: absolute;
        top: 30%;
        left: 20%;
        transform: translate(-50%, -50%);
        z-index: 10;
    }

    .driver-marker-dot {
        width: 20px;
        height: 20px;
        background: var(--color-primary);
        border: 3px solid white;
        border-radius: 50%;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    }

    .driver-marker-pulse {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 40px;
        height: 40px;
        background: var(--color-primary);
        border-radius: 50%;
        opacity: 0.3;
        animation: pulse 2s ease-out infinite;
    }

    @keyframes pulse {
        0% {
            transform: translate(-50%, -50%) scale(0.5);
            opacity: 0.4;
        }
        100% {
            transform: translate(-50%, -50%) scale(1.5);
            opacity: 0;
        }
    }

    .destination-marker {
        position: absolute;
        top: 60%;
        right: 20%;
        width: 18px;
        height: 18px;
        background: #e53935;
        border: 3px solid white;
        border-radius: 50%;
        transform: translate(50%, -50%);
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    }

    .route-line {
        position: absolute;
        top: 35%;
        left: calc(20% + 10px);
        width: calc(50% - 10px);
        height: 3px;
        background: #9e9e9e;
    }

    .route-line::before {
        content: "";
        position: absolute;
        left: 0;
        top: 0;
        height: 3px;
        width: 50%;
        background: var(--color-primary);
    }

    .map-label {
        position: absolute;
        bottom: 12px;
        left: 12px;
        right: 12px;
        display: flex;
        justify-content: space-between;
    }

    .label-driver,
    .label-destination {
        background: white;
        padding: 4px 10px;
        border-radius: 4px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .label-driver {
        color: var(--color-primary);
    }

    .label-destination {
        color: #e53935;
    }
    .page-header {
        margin-bottom: 24px;
    }

    .header-title {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 8px;
        color: var(--color-text);
    }

    .header-title h1 {
        font-size: 1.5rem;
        font-weight: 700;
        margin: 0;
    }

    .header-subtitle {
        color: var(--color-text-muted);
        font-size: 0.9rem;
        margin: 0;
        padding-left: 36px;
    }

    .search-bar {
        position: relative;
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 20px;
    }

    .search-icon {
        position: absolute;
        left: 16px;
        color: var(--color-text-faint);
        pointer-events: none;
    }

    .search-bar input {
        flex: 1;
        max-width: 500px;
        padding: 12px 16px 12px 48px;
        background: var(--color-bg-input);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-md);
        font-size: 0.9rem;
        color: var(--color-text);
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
        outline: none;
    }

    .btn-refresh {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 10px 18px;
        background: var(--color-primary);
        color: white;
        font-size: 0.85rem;
        font-weight: 600;
        border: none;
        border-radius: var(--radius-md);
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .btn-refresh:hover {
        background: var(--color-primary-hover);
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
    }

    .drivers-container {
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
        to {
            transform: rotate(360deg);
        }
    }

    .empty-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 80px 20px;
        color: var(--color-text-muted);
        text-align: center;
    }

    .empty-state svg {
        margin-bottom: 16px;
        opacity: 0.4;
    }

    .empty-state h3 {
        font-size: 1.1rem;
        font-weight: 600;
        margin: 0 0 8px 0;
        color: var(--color-text);
    }

    .empty-state p {
        font-size: 0.9rem;
        margin: 0;
        max-width: 400px;
    }

    .drivers-count {
        padding: 12px 20px;
        background: rgba(108, 99, 255, 0.05);
        border-bottom: 1px solid var(--color-border);
        font-size: 0.85rem;
        color: var(--color-text-muted);
    }

    .count-badge {
        display: inline-block;
        background: var(--color-primary);
        color: white;
        padding: 2px 10px;
        border-radius: 12px;
        font-size: 0.8rem;
        font-weight: 600;
        margin-right: 8px;
    }

    .drivers-table {
        width: 100%;
    }

    .drivers-table table {
        width: 100%;
        border-collapse: collapse;
    }

    .drivers-table thead {
        background: rgba(108, 99, 255, 0.05);
    }

    .drivers-table th {
        padding: 14px 20px;
        font-size: 0.75rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        text-align: left;
        border-bottom: 1px solid var(--color-border);
    }

    .drivers-table td {
        padding: 16px 20px;
        font-size: 0.9rem;
        border-bottom: 1px solid var(--color-border);
        color: var(--color-text);
    }

    .driver-row:hover {
        background: rgba(108, 99, 255, 0.03);
    }

    .driver-row.expanded {
        background: rgba(108, 99, 255, 0.05);
    }

    .col-no {
        width: 60px;
        text-align: center;
    }

    .col-phone {
        width: 200px;
    }

    .col-action {
        width: 150px;
    }

    .driver-name {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .driver-avatar {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        background: var(--color-primary);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.85rem;
        flex-shrink: 0;
    }

    .phone-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        color: var(--color-text-muted);
        font-size: 0.9rem;
    }

    .btn-locate {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 8px 16px;
        background: rgba(108, 99, 255, 0.1);
        color: var(--color-primary);
        font-size: 0.8rem;
        font-weight: 600;
        border: none;
        border-radius: var(--radius-sm);
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .btn-locate:hover,
    .btn-locate.active {
        background: var(--color-primary);
        color: white;
    }

    .expanded-row td {
        padding: 0;
        background: #f8f9ff;
    }

    .map-card {
        padding: 20px;
    }

    .map-header-info {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
    }

    .map-header-info h4 {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 1rem;
        font-weight: 600;
        margin: 0;
        color: var(--color-text);
    }

    .status-on-duty {
        display: inline-block;
        padding: 4px 12px;
        background: rgba(239, 68, 68, 0.1);
        color: #ef4444;
        font-size: 0.75rem;
        font-weight: 600;
        border-radius: 20px;
    }

    .status-tersedia {
        display: inline-block;
        padding: 4px 12px;
        background: rgba(34, 197, 94, 0.1);
        color: #22c55e;
        font-size: 0.75rem;
        font-weight: 600;
        border-radius: 20px;
    }

    .map-placeholder {
        width: 100%;
        height: 280px;
        background: #f0f4ff;
        border-radius: var(--radius-md);
        overflow: hidden;
        margin-bottom: 16px;
    }

    .driver-info-row {
        display: flex;
        gap: 32px;
        padding: 12px 16px;
        background: white;
        border-radius: var(--radius-sm);
        margin-bottom: 12px;
    }

    .info-item {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .info-label {
        font-size: 0.7rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--color-text-muted);
        font-weight: 600;
    }

    .info-value {
        font-size: 0.9rem;
        font-weight: 600;
        color: var(--color-text);
        font-variant-numeric: tabular-nums;
    }

    .map-note {
        font-size: 0.8rem;
        color: var(--color-text-muted);
        margin: 0;
    }

    .empty-state-search {
        text-align: center !important;
        padding: 48px 20px !important;
        color: var(--color-text-faint) !important;
    }
</style>