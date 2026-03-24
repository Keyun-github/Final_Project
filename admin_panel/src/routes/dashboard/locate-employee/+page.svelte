<script lang="ts">
    import { onMount } from "svelte";

    // Locate Employee — with map view
    let searchQuery = $state("");
    let selectedEmployee = $state<Employee | null>(null);
    let mapElement: HTMLDivElement | undefined = $state();

    interface Employee {
        id: number;
        name: string;
        telp: string;
        location: string;
        status: string;
        lat: number;
        lng: number;
    }

    const employees: Employee[] = [
        {
            id: 1,
            name: "Budi Santoso",
            telp: "081234567890",
            location: "Jakarta",
            status: "On Duty",
            lat: -6.2088,
            lng: 106.8456,
        },
        {
            id: 2,
            name: "Siti Nurhaliza",
            telp: "082345678901",
            location: "Bandung",
            status: "On Duty",
            lat: -6.9175,
            lng: 107.6191,
        },
    ];

    let filtered = $derived(
        searchQuery.trim()
            ? employees.filter(
                  (e) =>
                      e.name
                          .toLowerCase()
                          .includes(searchQuery.toLowerCase()) ||
                      e.location
                          .toLowerCase()
                          .includes(searchQuery.toLowerCase()),
              )
            : employees,
    );

    function selectEmployee(emp: Employee) {
        selectedEmployee = emp;
    }

    function closeMap() {
        selectedEmployee = null;
    }

    // Load Leaflet map when employee is selected
    let leafletLoaded = $state(false);

    onMount(() => {
        // Inject Leaflet CSS
        if (!document.querySelector('link[href*="leaflet"]')) {
            const link = document.createElement("link");
            link.rel = "stylesheet";
            link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
            document.head.appendChild(link);
        }
        // Inject Leaflet JS
        if (!(window as any).L) {
            const script = document.createElement("script");
            script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
            script.onload = () => {
                leafletLoaded = true;
            };
            document.head.appendChild(script);
        } else {
            leafletLoaded = true;
        }
    });

    let mapInstance: any = null;
    let mapMarker: any = null;

    $effect(() => {
        if (selectedEmployee && leafletLoaded && mapElement) {
            const L = (window as any).L;
            if (!L) return;

            // Destroy old map if it exists
            if (mapInstance) {
                mapInstance.remove();
                mapInstance = null;
            }

            // Small delay to ensure DOM is ready
            setTimeout(() => {
                if (!mapElement) return;
                mapInstance = L.map(mapElement).setView(
                    [selectedEmployee!.lat, selectedEmployee!.lng],
                    14,
                );

                L.tileLayer(
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    {
                        attribution: "© OpenStreetMap contributors",
                    },
                ).addTo(mapInstance);

                mapMarker = L.marker([
                    selectedEmployee!.lat,
                    selectedEmployee!.lng,
                ]).addTo(mapInstance);
                mapMarker
                    .bindPopup(
                        `<strong>${selectedEmployee!.name}</strong><br/>${selectedEmployee!.location}<br/><em>${selectedEmployee!.status}</em>`,
                    )
                    .openPopup();

                // Force map resize
                setTimeout(() => mapInstance?.invalidateSize(), 100);
            }, 50);
        }
    });
</script>

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
        placeholder="Search driver by name or location..."
        bind:value={searchQuery}
        id="search-employee"
    />
</div>

<div class="table-container">
    <table class="locate-table">
        <thead>
            <tr>
                <th>No</th>
                <th>Name</th>
                <th>Phone</th>
                <th>Location</th>
                <th>Status</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            {#each filtered as emp, i}
                <tr class:selected={selectedEmployee?.id === emp.id}>
                    <td class="col-no">{i + 1}</td>
                    <td>
                        <div class="employee-name">
                            <div class="emp-avatar">{emp.name.charAt(0)}</div>
                            {emp.name}
                        </div>
                    </td>
                    <td>{emp.telp}</td>
                    <td>
                        <span class="location-badge">
                            <svg
                                width="14"
                                height="14"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                ><path
                                    d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"
                                /><circle cx="12" cy="10" r="3" /></svg
                            >
                            {emp.location}
                        </span>
                    </td>
                    <td>
                        <span
                            class="status-badge"
                            class:on-duty={emp.status === "On Duty"}
                        >
                            {emp.status}
                        </span>
                    </td>
                    <td>
                        <button
                            class="btn-locate"
                            onclick={() => selectEmployee(emp)}
                            title="View on map"
                        >
                            <svg
                                width="16"
                                height="16"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                ><path
                                    d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"
                                /><circle cx="12" cy="10" r="3" /></svg
                            >
                            View Map
                        </button>
                    </td>
                </tr>
            {/each}
            {#if filtered.length === 0}
                <tr>
                    <td colspan="6" class="empty-state"
                        >No drivers found matching your search.</td
                    >
                </tr>
            {/if}
        </tbody>
    </table>
</div>

<!-- Map Panel -->
{#if selectedEmployee}
    <div class="map-panel">
        <div class="map-header">
            <div class="map-title-group">
                <h3 class="map-title">
                    <svg
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        ><path
                            d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"
                        /><circle cx="12" cy="10" r="3" /></svg
                    >
                    {selectedEmployee.name} — {selectedEmployee.location}
                </h3>
                <span
                    class="map-status"
                    class:on-duty={selectedEmployee.status === "On Duty"}
                >
                    {selectedEmployee.status}
                </span>
            </div>
            <button class="map-close" onclick={closeMap} aria-label="Close map">
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
        <div class="map-container" bind:this={mapElement}></div>
        <div class="map-footer">
            <span class="map-coord">Lat: {selectedEmployee.lat.toFixed(4)}</span
            >
            <span class="map-coord">Lng: {selectedEmployee.lng.toFixed(4)}</span
            >
            <span class="map-note"
                >📡 Real-time tracking will update automatically</span
            >
        </div>
    </div>
{/if}

<style>
    .search-bar {
        position: relative;
        margin-bottom: 24px;
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
        padding: 14px 16px 14px 48px;
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

    .table-container {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
    }

    .locate-table {
        width: 100%;
        border-collapse: collapse;
    }

    .locate-table thead {
        background: rgba(108, 99, 255, 0.05);
    }

    .locate-table th {
        padding: 14px 20px;
        font-size: 0.75rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        text-align: left;
        border-bottom: 1px solid var(--color-border);
    }

    .locate-table td {
        padding: 16px 20px;
        font-size: 0.9rem;
        border-bottom: 1px solid var(--color-border);
        color: var(--color-text);
    }

    .locate-table tr:last-child td {
        border-bottom: none;
    }

    .locate-table tbody tr {
        transition: background var(--transition-fast);
        cursor: pointer;
    }

    .locate-table tbody tr:hover {
        background: rgba(108, 99, 255, 0.03);
    }

    .locate-table tbody tr.selected {
        background: rgba(108, 99, 255, 0.08);
        border-left: 3px solid var(--color-primary);
    }

    .col-no {
        width: 60px;
        text-align: center !important;
    }

    .employee-name {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .emp-avatar {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background: var(--color-primary);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.8rem;
        flex-shrink: 0;
    }

    .location-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        color: var(--color-text-muted);
    }

    .status-badge {
        display: inline-block;
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 600;
        background: rgba(136, 136, 168, 0.1);
        color: var(--color-text-muted);
    }

    .status-badge.on-duty {
        background: rgba(0, 212, 170, 0.1);
        color: var(--color-success);
    }

    .btn-locate {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 6px 14px;
        border-radius: var(--radius-sm);
        background: rgba(108, 99, 255, 0.1);
        color: var(--color-primary);
        font-size: 0.8rem;
        font-weight: 600;
        transition: all var(--transition-fast);
    }

    .btn-locate:hover {
        background: rgba(108, 99, 255, 0.2);
        transform: translateY(-1px);
    }

    .empty-state {
        text-align: center !important;
        padding: 48px 20px !important;
        color: var(--color-text-faint) !important;
        font-style: italic;
    }

    /* ===== Map Panel ===== */
    .map-panel {
        margin-top: 24px;
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
        animation: slideUp 0.3s ease;
    }

    @keyframes slideUp {
        from {
            opacity: 0;
            transform: translateY(12px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    .map-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px 20px;
        border-bottom: 1px solid var(--color-border);
    }

    .map-title-group {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .map-title {
        font-size: 0.95rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .map-status {
        font-size: 0.7rem;
        font-weight: 600;
        padding: 3px 10px;
        border-radius: 20px;
        background: rgba(136, 136, 168, 0.1);
        color: var(--color-text-muted);
    }

    .map-status.on-duty {
        background: rgba(0, 212, 170, 0.1);
        color: var(--color-success);
    }

    .map-close {
        background: transparent;
        color: var(--color-text-muted);
        padding: 4px;
        transition: color var(--transition-fast);
    }

    .map-close:hover {
        color: var(--color-text);
    }

    .map-container {
        width: 100%;
        height: 400px;
        background: var(--color-bg-input);
    }

    .map-footer {
        padding: 12px 20px;
        border-top: 1px solid var(--color-border);
        display: flex;
        align-items: center;
        gap: 20px;
        font-size: 0.8rem;
        color: var(--color-text-muted);
    }

    .map-coord {
        font-variant-numeric: tabular-nums;
        font-family: monospace;
    }

    .map-note {
        margin-left: auto;
        font-size: 0.75rem;
        color: var(--color-text-faint);
    }
</style>
