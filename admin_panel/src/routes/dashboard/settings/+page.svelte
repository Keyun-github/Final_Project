<script lang="ts">
    import { onMount } from 'svelte';
    import {
        fetchStoreConfig,
        updateStoreConfig,
        type StoreConfig,
    } from '$lib/api';

    let config = $state<StoreConfig | null>(null);
    let address = $state('');
    let lat = $state('');
    let lng = $state('');
    let isLoading = $state(true);
    let isSaving = $state(false);
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
    });

    import { onDestroy } from 'svelte';
    onDestroy(() => {
        if (toastTimer) clearTimeout(toastTimer);
    });

    async function loadConfig() {
        try {
            isLoading = true;
            const data = await fetchStoreConfig();
            config = data;
            address = data.address;
            lat = String(data.lat);
            lng = String(data.lng);
        } catch (e) {
            console.error('Failed to load store config:', e);
            showToast('❌ Gagal memuat konfigurasi toko', 'error');
        } finally {
            isLoading = false;
        }
    }

    function handleLatLngChange() {
        const newLat = parseFloat(lat);
        const newLng = parseFloat(lng);
        // Validate range, show toast if invalid
        if (!isNaN(newLat) && (newLat < -90 || newLat > 90)) {
            showToast('❌ Latitude harus antara -90 dan 90', 'error');
        }
        if (!isNaN(newLng) && (newLng < -180 || newLng > 180)) {
            showToast('❌ Longitude harus antara -180 dan 180', 'error');
        }
    }

    async function saveConfig() {
        const cleanAddress = address.trim();
        const latNum = parseFloat(lat);
        const lngNum = parseFloat(lng);

        if (!cleanAddress) {
            showToast('❌ Alamat tidak boleh kosong', 'error');
            return;
        }
        if (isNaN(latNum) || latNum < -90 || latNum > 90) {
            showToast('❌ Latitude harus angka antara -90 dan 90', 'error');
            return;
        }
        if (isNaN(lngNum) || lngNum < -180 || lngNum > 180) {
            showToast('❌ Longitude harus angka antara -180 dan 180', 'error');
            return;
        }

        try {
            isSaving = true;
            const updated = await updateStoreConfig(cleanAddress, latNum, lngNum);
            config = updated;
            address = updated.address;
            lat = String(updated.lat);
            lng = String(updated.lng);
            showToast('✅ Lokasi toko berhasil disimpan', 'success');
        } catch (e: any) {
            console.error('Failed to save store config:', e);
            showToast(
                `❌ Gagal menyimpan: ${e?.message ?? 'unknown error'}`,
                'error',
            );
        } finally {
            isSaving = false;
        }
    }

    function getCurrentLocation() {
        // Try browser geolocation
        if (!('geolocation' in navigator)) {
            showToast('❌ Browser tidak mendukung geolocation', 'error');
            return;
        }
        navigator.geolocation.getCurrentPosition(
            (pos) => {
                lat = pos.coords.latitude.toFixed(7);
                lng = pos.coords.longitude.toFixed(7);
                showToast('✅ Lokasi GPS terbaca', 'success');
            },
            (err) => {
                showToast(`❌ Gagal baca GPS: ${err.message}`, 'error');
            },
        );
    }
</script>

<svelte:head>
    <title>Pengaturan Toko — Admin</title>
</svelte:head>

<div class="page-header">
    <div>
        <h1>Pengaturan Toko</h1>
        <p class="page-subtitle">
            Atur alamat & koordinat toko. Data ini dipakai oleh driver dan
            customer untuk menampilkan rute pickup.
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
        <!-- Form Card -->
        <div class="card">
            <div class="card-header">
                <h2>Lokasi Toko</h2>
                <p class="card-subtitle">
                    Koordinat ini jadi titik pickup default untuk semua
                    order.
                </p>
            </div>
            <div class="card-body">
                <div class="form-group">
                    <label for="store-address">Alamat Toko</label>
                    <input
                        id="store-address"
                        type="text"
                        bind:value={address}
                        placeholder="Jl. Contoh No. 123, Kota"
                    />
                    <p class="form-hint">
                        Tulis alamat lengkap seperti yang akan ditampilkan ke
                        customer.
                    </p>
                </div>
                <div class="form-row">
                    <div class="form-group flex-1">
                        <label for="store-lat">Latitude</label>
                        <input
                            id="store-lat"
                            type="text"
                            inputmode="decimal"
                            bind:value={lat}
                            oninput={handleLatLngChange}
                            placeholder="-7.2628478"
                        />
                    </div>
                    <div class="form-group flex-1">
                        <label for="store-lng">Longitude</label>
                        <input
                            id="store-lng"
                            type="text"
                            inputmode="decimal"
                            bind:value={lng}
                            oninput={handleLatLngChange}
                            placeholder="112.7336368"
                        />
                    </div>
                </div>
                <div class="form-actions">
                    <button
                        type="button"
                        class="btn-secondary"
                        onclick={getCurrentLocation}
                        disabled={isSaving}
                    >
                        📍 Pakai GPS Saya
                    </button>
                    <button
                        type="button"
                        class="btn-save"
                        onclick={saveConfig}
                        disabled={isSaving}
                    >
                        {isSaving ? 'Menyimpan...' : 'Simpan'}
                    </button>
                </div>
            </div>
        </div>

        <!-- Preview Card -->
        <div class="card">
            <div class="card-header">
                <h2>Preview</h2>
                <p class="card-subtitle">
                    Tampilan saat ini di backend (mobile apps akan refresh
                    otomatis saat mereka query berikutnya).
                </p>
            </div>
            <div class="card-body">
                {#if config}
                    <div class="preview-row">
                        <span class="preview-label">ID</span>
                        <span class="preview-value">{config.id}</span>
                    </div>
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
                {/if}
            </div>
        </div>
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
        grid-template-columns: 1.2fr 1fr;
        gap: 20px;
        align-items: start;
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

    .form-group {
        margin-bottom: 16px;
    }
    .form-row {
        display: flex;
        gap: 12px;
    }
    .flex-1 {
        flex: 1;
    }
    label {
        display: block;
        font-weight: 600;
        font-size: 13px;
        margin-bottom: 6px;
        color: var(--color-text);
    }
    input[type='text'] {
        width: 100%;
        padding: 10px 14px;
        border: 1px solid var(--color-border, #e5e7eb);
        border-radius: var(--radius-md, 8px);
        font-size: 14px;
        background: var(--color-bg-card, white);
        color: var(--color-text);
        box-sizing: border-box;
        transition:
            border-color 0.15s,
            box-shadow 0.15s;
    }
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
    .form-actions {
        display: flex;
        gap: 8px;
        justify-content: flex-end;
        margin-top: 8px;
    }
    .btn-secondary,
    .btn-save {
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
    .btn-secondary:disabled,
    .btn-save:disabled {
        opacity: 0.6;
        cursor: not-allowed;
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