<script lang="ts">
    import { onMount } from "svelte";
    import { page } from "$app/state";
    import { getAuth, logout, requireAuth } from "$lib/auth.svelte";

    const auth = getAuth();
    let currentTime = $state("");
    let greeting = $state("");
    let { children } = $props();

    onMount(() => {
        requireAuth();
        updateTime();
        const timer = setInterval(updateTime, 1000);
        return () => clearInterval(timer);
    });

    function updateTime() {
        const now = new Date();
        currentTime = now.toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
        });
        const hour = now.getHours();
        if (hour < 12) greeting = "Good Morning";
        else if (hour < 17) greeting = "Good Afternoon";
        else greeting = "Good Evening";
    }

    const menuItems = [
        { label: "Dashboard", icon: "dashboard", href: "/dashboard" },
        {
            label: "Add Employee",
            icon: "add-employee",
            href: "/dashboard/add-employee",
        },
        {
            label: "Locate Employee",
            icon: "locate-employee",
            href: "/dashboard/locate-employee",
        },
        { label: "Orders", icon: "orders", href: "/dashboard/orders" },
        { label: "Stock", icon: "stock", href: "/dashboard/stock" },
    ];

    function isActive(href: string): boolean {
        return page.url.pathname === href;
    }

    // Page title derived from current route
    function getPageTitle(): string {
        const path = page.url.pathname;
        const item = menuItems.find((m) => m.href === path);
        return item?.label ?? "Dashboard";
    }
</script>

<svelte:head>
    <title>{getPageTitle()} — Admin Panel</title>
</svelte:head>

{#if auth.isAuthenticated}
    <div class="dashboard-layout">
        <!-- Sidebar -->
        <aside class="sidebar">
            <div class="sidebar-brand">
                <div class="sidebar-logo">
                    <svg width="32" height="32" viewBox="0 0 40 40" fill="none">
                        <rect
                            width="40"
                            height="40"
                            rx="12"
                            fill="url(#sideLogoGrad)"
                        />
                        <path
                            d="M12 20L18 14L26 22L20 28L12 20Z"
                            fill="white"
                            fill-opacity="0.9"
                        />
                        <path
                            d="M20 12L28 20L26 22L18 14L20 12Z"
                            fill="white"
                            fill-opacity="0.6"
                        />
                        <defs>
                            <linearGradient
                                id="sideLogoGrad"
                                x1="0"
                                y1="0"
                                x2="40"
                                y2="40"
                            >
                                <stop stop-color="#6c63ff" />
                                <stop offset="1" stop-color="#4ecdc4" />
                            </linearGradient>
                        </defs>
                    </svg>
                </div>
                <span class="sidebar-title">Admin</span>
            </div>

            <nav class="sidebar-nav">
                {#each menuItems as item}
                    <a
                        class="nav-item"
                        class:active={isActive(item.href)}
                        href={item.href}
                        id="nav-{item.icon}"
                    >
                        <span class="nav-icon">
                            {#if item.icon === "dashboard"}
                                <svg
                                    width="20"
                                    height="20"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    ><rect
                                        x="3"
                                        y="3"
                                        width="7"
                                        height="7"
                                        rx="1.5"
                                    /><rect
                                        x="14"
                                        y="3"
                                        width="7"
                                        height="7"
                                        rx="1.5"
                                    /><rect
                                        x="3"
                                        y="14"
                                        width="7"
                                        height="7"
                                        rx="1.5"
                                    /><rect
                                        x="14"
                                        y="14"
                                        width="7"
                                        height="7"
                                        rx="1.5"
                                    /></svg
                                >
                            {:else if item.icon === "add-employee"}
                                <svg
                                    width="20"
                                    height="20"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    ><path
                                        d="M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"
                                    /><circle cx="8.5" cy="7" r="4" /><line
                                        x1="20"
                                        y1="8"
                                        x2="20"
                                        y2="14"
                                    /><line
                                        x1="23"
                                        y1="11"
                                        x2="17"
                                        y2="11"
                                    /></svg
                                >
                            {:else if item.icon === "locate-employee"}
                                <svg
                                    width="20"
                                    height="20"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    ><circle cx="11" cy="11" r="8" /><line
                                        x1="21"
                                        y1="21"
                                        x2="16.65"
                                        y2="16.65"
                                    /><circle cx="11" cy="8" r="2" /><path
                                        d="M7 14s1-2 4-2 4 2 4 2"
                                    /></svg
                                >
                            {:else if item.icon === "orders"}
                                <svg
                                    width="20"
                                    height="20"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    ><path
                                        d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"
                                    /><line x1="3" y1="6" x2="21" y2="6" /><path
                                        d="M16 10a4 4 0 01-8 0"
                                    /></svg
                                >
                            {:else if item.icon === "stock"}
                                <svg
                                    width="20"
                                    height="20"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    ><path
                                        d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"
                                    /><polyline
                                        points="3.27 6.96 12 12.01 20.73 6.96"
                                    /><line
                                        x1="12"
                                        y1="22.08"
                                        x2="12"
                                        y2="12"
                                    /></svg
                                >
                            {/if}
                        </span>
                        <span class="nav-label">{item.label}</span>
                    </a>
                {/each}
            </nav>

            <div class="sidebar-footer">
                <button class="logout-btn" onclick={logout} id="logout-button">
                    <svg
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                    >
                        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
                        <polyline points="16 17 21 12 16 7" />
                        <line x1="21" y1="12" x2="9" y2="12" />
                    </svg>
                    Logout
                </button>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="main-content">
            <header class="topbar">
                <div class="topbar-left">
                    <h2 class="page-title">{getPageTitle()}</h2>
                    <p class="page-subtitle">
                        {greeting},
                        <strong>{auth.user?.username ?? "Admin"}</strong>
                    </p>
                </div>
                <div class="topbar-right">
                    <span class="clock">{currentTime}</span>
                    <div class="avatar" title={auth.user?.username}>
                        {auth.user?.username?.charAt(0).toUpperCase() ?? "A"}
                    </div>
                </div>
            </header>

            {@render children()}
        </main>
    </div>
{/if}

<style>
    .dashboard-layout {
        display: flex;
        min-height: 100vh;
        animation: fadeIn 0.4s ease;
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
        }
        to {
            opacity: 1;
        }
    }

    /* ===== Sidebar ===== */
    .sidebar {
        width: 260px;
        background: var(--color-bg-sidebar);
        border-right: 1px solid var(--color-border);
        display: flex;
        flex-direction: column;
        position: fixed;
        top: 0;
        left: 0;
        bottom: 0;
        z-index: 50;
    }

    .sidebar-brand {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 24px 20px;
        border-bottom: 1px solid var(--color-border);
    }

    .sidebar-logo {
        display: flex;
    }

    .sidebar-title {
        font-size: 1.2rem;
        font-weight: 700;
        background: var(--gradient-primary);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
    }

    .sidebar-nav {
        flex: 1;
        padding: 16px 12px;
        display: flex;
        flex-direction: column;
        gap: 4px;
        overflow-y: auto;
    }

    .nav-item {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 12px 16px;
        border-radius: var(--radius-md);
        color: var(--color-text-muted);
        background: transparent;
        font-size: 0.9rem;
        font-weight: 500;
        transition: all var(--transition-fast);
        text-decoration: none;
    }

    .nav-item:hover {
        background: rgba(108, 99, 255, 0.06);
        color: var(--color-text);
    }

    .nav-item.active {
        background: rgba(108, 99, 255, 0.1);
        color: var(--color-primary);
    }

    .nav-icon {
        display: flex;
        align-items: center;
    }

    .sidebar-footer {
        padding: 16px 12px;
        border-top: 1px solid var(--color-border);
    }

    .logout-btn {
        display: flex;
        align-items: center;
        gap: 10px;
        width: 100%;
        padding: 12px 16px;
        border-radius: var(--radius-md);
        color: var(--color-danger);
        background: rgba(255, 77, 106, 0.06);
        font-size: 0.9rem;
        font-weight: 500;
        transition: all var(--transition-fast);
    }

    .logout-btn:hover {
        background: rgba(255, 77, 106, 0.12);
    }

    /* ===== Main Content ===== */
    .main-content {
        flex: 1;
        margin-left: 260px;
        padding: 28px 32px;
        background: var(--color-bg);
        background-image: var(--gradient-bg);
        min-height: 100vh;
    }

    .topbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 32px;
    }

    .page-title {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--color-text);
    }

    .page-subtitle {
        font-size: 0.85rem;
        color: var(--color-text-muted);
        margin-top: 2px;
    }

    .topbar-right {
        display: flex;
        align-items: center;
        gap: 16px;
    }

    .clock {
        font-size: 0.85rem;
        color: var(--color-text-muted);
        font-variant-numeric: tabular-nums;
    }

    .avatar {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: var(--gradient-primary);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 1rem;
        color: white;
    }

    @media (max-width: 768px) {
        .sidebar {
            display: none;
        }
        .main-content {
            margin-left: 0;
            padding: 20px 16px;
        }
    }
</style>
