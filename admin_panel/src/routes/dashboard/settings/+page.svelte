<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import {
        fetchStoreConfig,
        resolveStoreConfig,
        updateStoreConfigFromCoords,
        geocodeAddress,
        reverseGeocodeAddress,
        type StoreConfig,
    } from '$lib/api';

    let config = $state<StoreConfig | null>(null);
    let address = $state('');
    let isLoading = $state(true);
    let isSaving = $state(false);
    let isGeocoding = $state(false);

    let mapContainer: HTMLDivElement | null = $state(null);
    let mapInstance: any = null;
    let markerInstance: any = null;

    let pickedLat = $state<number | null>(null);
    let pickedLng = $state<number | null>(null);
    let pickedDisplayName = $state('');
    let hasPickedOnMap = $state(false);

    let toastMessage = $state('');
    let toastType = $state<'success' | 'error'>('success');
    let toastVisible = $state(false);
    let toastTimer: ReturnType<typeof setTimeout> | null = null;

    function showToast(message: string, type: 'success' | 'error' = 'success') {
        toastMessage = message;
        toastType = type;
        toastVisible = true;
        if (toastTimer) clearTimeout(toastTimer);
        toastTimer = setTimeout(() => {
            toastVisible = false;
        }, 3000);
    }

    onMount(async () => {
        await loadConfig();
        loadLeaflet();
    });

    onDestroy(() => {
        if (toastTimer) clearTimeout(toastTimer);
        if (mapInstance) mapInstance.remove();
    });

    async function loadConfig() {
        try {
            isLoading = true;
            const data = await fetchStoreConfig();
            config = data;
            address = data.address;
            pickedLat = data.lat;
            pickedLng = data.lng;
        } catch (e) {
            console.error('Failed to load store config:', e);
            showToast('❌ Gagal memuat konfigurasi toko', 'error');
        } finally {
            isLoading = false;
        }
    }

    async function loadLeaflet() {
        if (typeof window === 'undefined') return;
        // Inject Leaflet CSS once.
        if (!document.getElementById('leaflet-css-settings')) {
            const link = document.createElement('link');
            link.id = 'leaflet-css-settings';
            link.rel = 'stylesheet';
            link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
            document.head.appendChild(link);
        }
        // Inject Leaflet JS once; initMap after it loads.
        if ((window as any).L) {
            initMap();
            return;
        }
        if (!document.getElementById('leaflet-script-settings')) {
            const script = document.createElement('script');
            script.id = 'leaflet-script-settings';
            script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
            script.onload = () => initMap();
            document.head.appendChild(script);
        }
    }

    function initMap() {
        if (!mapContainer || mapInstance) return;
        const L = (window as any).L;
        if (!L) return;

        const initialCenter: [number, number] = [
            pickedLat ?? -7.2628478,
            pickedLng ?? 112.7336368,
        ];
        mapInstance = L.map(mapContainer).setView(initialCenter, 16);
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19,
        }).addTo(mapInstance);

        const marker = L.marker(initialCenter, { draggable: true }).addTo(
            mapInstance,
        );
        marker.on('dragend', async () => {
            const pos = marker.getLatLng();
            pickedLat = pos.lat;
            pickedLng = pos.lng;
            hasPickedOnMap = true;
            await fetchDisplayName(pos.lat, pos.lng);
        });
        markerInstance = marker;

        mapInstance.on('click', async (e: any) => {
            const { lat, lng } = e.latlng;
            pickedLat = lat;
            pickedLng = lng;
            hasPickedOnMap = true;
            marker.setLatLng([lat, lng]);
            await fetchDisplayName(lat, lng);
        });
    }

    async function fetchDisplayName(lat: number, lng: number) {
        try {
            const result = await reverseGeocodeAddress(lat, lng);
            if (result.displayName) {
                pickedDisplayName = result.displayName;
                // Only auto-fill if the address field is empty OR the admin
                // picked a fresh point on the map.
                if (!address.trim() || hasPickedOnMap) {
                    address = result.displayName;
                }
            }
        } catch (e) {
            console.error('Reverse geocode failed:', e);
        }
    }

    function updateMarkerOnMap(lat: number, lng: number) {
        if (!mapInstance || !markerInstance) return;
        markerInstance.setLatLng([lat, lng]);
        mapInstance.setView([lat, lng], 16);
    }

    /**
     * Address-only save: backend geocodes via Nominatim.
     */
    async function saveByAddress() {
        const cleanAddress = address.trim();
        if (!cleanAddress) {
            showToast('❌ Alamat tidak boleh kosong', 'error');
            return;
        }

        try {
            isSaving = true;
            isGeocoding = true;
            const updated = await resolveStoreConfig(cleanAddress);
            config = updated;
            address = updated.address;
            pickedLat = updated.lat;
            pickedLng = updated.lng;
            hasPickedOnMap = false;
            updateMarkerOnMap(updated.lat, updated.lng);
            showToast('✅ Lokasi toko berhasil disimpan', 'success');
        } catch (e: any) {
            console.error('Failed to save by address:', e);
            showToast(
                `❌ Gagal: ${e?.message ?? 'tidak bisa menemukan koordinat untuk alamat ini'}`,
                'error',
            );
        } finally {
            isSaving = false;
            isGeocoding = false;
        }
    }

    /**
     * Map-pick save: admin clicked on the map, address field is filled
     * with whatever the admin wants displayed.
     */
    async function saveByMap() {
        if (pickedLat == null || pickedLng == null) {
            showToast(
                '❌ Klik peta dulu untuk pilih lokasi, atau ketik alamat lalu klik "Simpan Otomatis"',
                'error',
            );
            return;
        }
        if (!address.trim()) {
            showToast(
                '❌ Alamat tidak boleh kosong. Klik peta untuk auto-isi dari koordinat.',
                'error',
            );
            return;
        }

        try {
            isSaving = true;
            const updated = await updateStoreConfigFromCoords(
                address.trim(),
                pickedLat,
                pickedLng,
            );
            config = updated;
            showToast('✅ Lokasi toko berhasil disimpan', 'success');
        } catch (e: any) {
            console.error('Failed to save by map:', e);
            showToast(
                `❌ Gagal: ${e?.message ?? 'unknown error'}`,
                'error',
            );
        } finally {
            isSaving = false;
        }
    }

    /**
     * Preview-only geocode: show what the backend would pick for the
     * typed address without committing. Updates the marker on the map.
     */
    async function previewGeocode() {
        const cleanAddress = address.trim();
        if (!cleanAddress) {
            showToast('❌ Ketik alamat dulu', 'error');
            return;
        }
        try {
            isGeocoding = true;
            const result = await geocodeAddress(cleanAddress);
            if (!result.found || result.lat == null || result.lng == null) {
                showToast(
                    '❌ Tidak bisa menemukan koordinat untuk alamat ini. Coba lebih spesifik.',
                    'error',
                );
                return;
            }
            pickedLat = result.lat;
            pickedLng = result.lng;
            hasPickedOnMap = false;
            updateMarkerOnMap(result.lat, result.lng);
            pickedDisplayName = result.displayName ?? '';
            showToast(
                `✅ Ditemukan: (${result.lat.toFixed(5)}, ${result.lng.toFixed(5)})`,
                'success',
            );
        } catch (e: any) {
            console.error('Preview geocode failed:', e);
            showToast(`❌ Gagal: ${e?.message ?? 'unknown error'}`, 'error');
        } finally {
            isGeocoding = false;
        }
    }
</script>

<svelte:head>
    <title>Pengaturan Toko — Admin</title>
</svelte:head>

<div class="page-header">
    <div>
        <h1>Pengaturan Toko</h1>
        <p class="page-subtitle">
            Ketik alamat toko lalu klik "Simpan Otomatis" — sistem akan
            mencari koordinat sendiri. Atau klik peta untuk pilih lokasi
            secara manual.
        </p>
    </div>
    <button class="btn-refresh" onclick={loadConfig} title="Refresh">
        <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            ><path d="M21 2v6h-6" /><path d="M3 12a9 9 0 0 1 15-6.7L21 8" />
            <path d="M3 22v-6h6" /><path d="M21 12a9 9 0 0 1-15 6.7L3 16" />
        </svg>
        Refresh
    </button>
</div>

{#if isLoading}
    <div class="loading">
        <div class="spinner"></div>
        <p>Memuat konfigurasi...</p>
    </div>
{:else}
    <div class="settings-grid">
        <!-- Address Form -->
        <div class="card">
            <div class="card-header">
                <h2>Alamat Toko</h2>
                <p class="card-subtitle">
                    Sistem akan otomatis menemukan koordinat dari
                    alamat yang diketik.
                </p>
            </div>
            <div class="card-body">
                <div class="form-group">
                    <label for="store-address">Alamat</label>
                    <textarea
                        id="store-address"
                        bind:value={address}
                        placeholder="Jl. Contoh No. 123, Kelurahan, Kecamatan, Kota"
                        rows="3"
                    ></textarea>
                    <p class="form-hint">
                        Tips: tulis alamat lengkap dengan kelurahan dan kota
                        supaya Nominatim bisa menemukan koordinat yang tepat.
                    </p>
                </div>

                <div class="action-row">
                    <button
                        type="button"
                        class="btn-secondary"
                        onclick={previewGeocode}
                        disabled={isGeocoding || isSaving}
                    >
                        🔍 Cari di Peta (Preview)
                    </button>
                    <button
                        type="button"
                        class="btn-save"
                        onclick={saveByAddress}
                        disabled={isSaving || isGeocoding}
                    >
                        {isGeocoding
                            ? 'Mencari koordinat...'
                            : isSaving
                              ? 'Menyimpan...'
                              : 'Simpan Otomatis'}
                    </button>
                </div>

                <div class="divider">
                    <span>ATAU</span>
                </div>

                <button
                    type="button"
                    class="btn-save-map"
                    onclick={saveByMap}
                    disabled={isSaving || pickedLat == null}
                >
                    {isSaving
                        ? 'Menyimpan...'
                        : '📍 Simpan dari Klik Peta'}
                </button>
                <p class="form-hint center">
                    Klik di peta di samping untuk pilih titik. Alamat di
                    atas akan dipakai sebagai display name.
                </p>

                {#if pickedLat != null && pickedLng != null}
                    <div class="coord-display">
                        <span>📍 Titik dipilih:</span>
                        <code
                            >{pickedLat.toFixed(5)}, {pickedLng.toFixed(5)}</code
                        >
                        {#if pickedDisplayName}
                            <p class="form-hint">
                                Auto-isi: {pickedDisplayName}
                            </p>
                        {/if}
                    </div>
                {/if}
            </div>
        </div>

        <!-- Map -->
        <div class="card">
            <div class="card-header">
                <h2>Peta</h2>
                <p class="card-subtitle">
                    Klik di mana saja untuk pilih lokasi, atau drag marker
                    untuk adjust.
                </p>
            </div>
            <div class="card-body no-pad">
                <div bind:this={mapContainer} class="map-container"></div>
            </div>
        </div>

        <!-- Current Saved State -->
        {#if config}
            <div class="card saved-card">
                <div class="card-header">
                    <h2>Tersimpan di Server</h2>
                </div>
                <div class="card-body">
                    <div class="preview-row">
                        <span class="preview-label">Alamat</span>
                        <span class="preview-value">{config.address}</span>
                    </div>
                    <div class="preview-row">
                        <span class="preview-label">Latitude</span>
                        <span class="preview-value mono">{config.lat}</span>
                    </div>
                    <div class="preview-row">
                        <span class="preview-label">Longitude</span>
                        <span class="preview-value mono">{config.lng}</span>
                    </div>
                    <div class="preview-row">
                        <span class="preview-label">Update terakhir</span>
                        <span class="preview-value">
                            {new Date(config.updatedAt).toLocaleString('id-ID')}
                        </span>
                    </div>
                    {#if config.updatedBy}
                        <div class="preview-row">
                            <span class="preview-label">Diubah oleh</span>
                            <span class="preview-value"
                                >{config.updatedBy}</span
                            >
                        </div>
                    {/if}
                </div>
            </div>
        {/if}
    </div>
{/if}

{#if toastVisible}
    <div class="toast toast--{toastType}" role="status" aria-live="polite">
        {toastMessage}
    </div>
{/if}

<style>
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 16px;
        margin-bottom: 20px;
    }
    .page-header h1 {
        font-size: 24px;
        font-weight: 800;
        margin: 0;
        color: var(--color-text, #1a1a2e);
    }
    .page-subtitle {
        color: var(--color-text-secondary, #6b7280);
        font-size: 14px;
        margin: 4px 0 0;
        max-width: 560px;
    }
    .btn-refresh {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: var(--color-bg-card, white);
        color: var(--color-text);
        border: 1px solid var(--color-border, #e5e7eb);
        padding: 8px 14px;
        border-radius: var(--radius-md, 8px);
        cursor: pointer;
        font-weight: 600;
        font-size: 14px;
    }
    .btn-refresh:hover {
        background: var(--color-bg, #f9fafb);
    }

    .loading {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 16px;
        padding: 60px;
        color: var(--color-text-secondary, #6b7280);
    }
    .spinner {
        width: 32px;
        height: 32px;
        border: 3px solid var(--color-border, #e5e7eb);
        border-top-color: var(--color-primary, #6c63ff);
        border-radius: 50%;
        animation: spin 1s linear infinite;
    }
    @keyframes spin {
        to {
            transform: rotate(360deg);
        }
    }

    .settings-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 20px;
        align-items: start;
    }
    .saved-card {
        grid-column: 1 / -1;
    }
    @media (max-width: 900px) {
        .settings-grid {
            grid-template-columns: 1fr;
        }
    }

    .card {
        background: var(--color-bg-card, white);
        border: 1px solid var(--color-border, #e5e7eb);
        border-radius: var(--radius-lg, 16px);
        overflow: hidden;
    }
    .card-header {
        padding: 20px 24px 8px;
        border-bottom: 1px solid var(--color-border, #e5e7eb);
    }
    .card-header h2 {
        font-size: 18px;
        font-weight: 700;
        margin: 0 0 4px;
    }
    .card-subtitle {
        font-size: 12px;
        color: var(--color-text-secondary, #6b7280);
        margin: 0 0 16px;
    }
    .card-body {
        padding: 20px 24px 24px;
    }
    .card-body.no-pad {
        padding: 0;
    }

    .form-group {
        margin-bottom: 16px;
    }
    label {
        display: block;
        font-weight: 600;
        font-size: 13px;
        margin-bottom: 6px;
        color: var(--color-text);
    }
    textarea,
    input[type='text'] {
        width: 100%;
        padding: 10px 14px;
        border: 1px solid var(--color-border, #e5e7eb);
        border-radius: var(--radius-md, 8px);
        font-size: 14px;
        background: var(--color-bg-card, white);
        color: var(--color-text);
        box-sizing: border-box;
        font-family: inherit;
        transition:
            border-color 0.15s,
            box-shadow 0.15s;
        resize: vertical;
    }
    textarea:focus,
    input[type='text']:focus {
        outline: none;
        border-color: var(--color-primary, #6c63ff);
        box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.1);
    }
    .form-hint {
        font-size: 11px;
        color: var(--color-text-secondary, #6b7280);
        margin: 6px 0 0;
    }
    .form-hint.center {
        text-align: center;
    }

    .action-row {
        display: flex;
        gap: 8px;
        justify-content: flex-end;
    }
    .btn-secondary,
    .btn-save,
    .btn-save-map {
        padding: 10px 18px;
        border-radius: var(--radius-md, 8px);
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.15s;
    }
    .btn-secondary {
        background: var(--color-bg-card, white);
        color: var(--color-text);
        border: 1px solid var(--color-border, #e5e7eb);
    }
    .btn-secondary:hover:not(:disabled) {
        background: var(--color-bg, #f9fafb);
    }
    .btn-save {
        background: var(--color-primary, #6c63ff);
        color: white;
        border: none;
    }
    .btn-save:hover:not(:disabled) {
        background: var(--color-primary-hover, #5a52d5);
    }
    .btn-save-map {
        background: #43a047;
        color: white;
        border: none;
        width: 100%;
    }
    .btn-save-map:hover:not(:disabled) {
        background: #388e3c;
    }
    .btn-secondary:disabled,
    .btn-save:disabled,
    .btn-save-map:disabled {
        opacity: 0.6;
        cursor: not-allowed;
    }

    .divider {
        display: flex;
        align-items: center;
        text-align: center;
        margin: 20px 0;
        color: var(--color-text-secondary, #6b7280);
        font-size: 12px;
        font-weight: 600;
    }
    .divider::before,
    .divider::after {
        content: '';
        flex: 1;
        border-top: 1px solid var(--color-border, #e5e7eb);
    }
    .divider span {
        padding: 0 12px;
    }

    .coord-display {
        margin-top: 16px;
        padding: 12px;
        background: rgba(108, 99, 255, 0.06);
        border-radius: var(--radius-md, 8px);
        font-size: 13px;
        display: flex;
        flex-direction: column;
        gap: 4px;
    }
    .coord-display code {
        background: var(--color-bg-card, white);
        padding: 4px 8px;
        border-radius: 4px;
        font-family: 'SF Mono', Menlo, Monaco, monospace;
        font-size: 12px;
        align-self: flex-start;
    }

    .map-container {
        width: 100%;
        height: 420px;
    }

    .preview-row {
        display: flex;
        justify-content: space-between;
        gap: 12px;
        padding: 8px 0;
        border-bottom: 1px solid var(--color-border, #f3f4f6);
        font-size: 13px;
    }
    .preview-row:last-child {
        border-bottom: none;
    }
    .preview-label {
        color: var(--color-text-secondary, #6b7280);
        flex-shrink: 0;
        font-weight: 500;
    }
    .preview-value {
        font-weight: 600;
        text-align: right;
        word-break: break-word;
    }
    .preview-value.mono {
        font-family: 'SF Mono', Menlo, Monaco, monospace;
    }

    .toast {
        position: fixed;
        top: 24px;
        right: 24px;
        padding: 14px 20px;
        border-radius: var(--radius-md, 8px);
        font-size: 14px;
        font-weight: 600;
        z-index: 1000;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
        animation: toastSlide 0.25s ease-out;
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