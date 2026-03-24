<script lang="ts">
    import { goto } from "$app/navigation";
    import { getAuth, login } from "$lib/auth.svelte";
    import { onMount } from "svelte";

    let username = $state("");
    let password = $state("");
    let errorMessage = $state("");
    let isLoading = $state(false);
    let showPassword = $state(false);

    const auth = getAuth();

    onMount(() => {
        if (auth.isAuthenticated) {
            goto("/dashboard");
        }
    });

    async function handleLogin(e: Event) {
        e.preventDefault();
        errorMessage = "";

        if (!username.trim() || !password.trim()) {
            errorMessage = "Please fill in all fields";
            return;
        }

        isLoading = true;

        // Small artificial delay so user sees the loading state
        await new Promise((r) => setTimeout(r, 600));

        const result = login(username, password);

        if (result.success) {
            goto("/dashboard");
        } else {
            errorMessage = result.message;
            isLoading = false;
        }
    }
</script>

<svelte:head>
    <title>Admin Login — Panel</title>
    <meta name="description" content="Admin panel login page" />
</svelte:head>

<div class="login-page">
    <!-- Background decorations -->
    <div class="bg-orb bg-orb--1"></div>
    <div class="bg-orb bg-orb--2"></div>
    <div class="bg-orb bg-orb--3"></div>

    <div class="login-container">
        <!-- Logo / Brand -->
        <div class="brand">
            <div class="brand-icon">
                <svg width="40" height="40" viewBox="0 0 40 40" fill="none">
                    <rect
                        width="40"
                        height="40"
                        rx="12"
                        fill="url(#logoGrad)"
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
                            id="logoGrad"
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
            <h1 class="brand-title">Admin Panel</h1>
            <p class="brand-subtitle">Sign in to your account</p>
        </div>

        <!-- Login Card -->
        <form class="login-card" onsubmit={handleLogin}>
            <!-- Username -->
            <div class="input-group">
                <label for="username" class="input-label">Username</label>
                <div class="input-wrapper">
                    <svg
                        class="input-icon"
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                    >
                        <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
                        <circle cx="12" cy="7" r="4" />
                    </svg>
                    <input
                        id="username"
                        type="text"
                        placeholder="Enter your username"
                        bind:value={username}
                        autocomplete="username"
                        disabled={isLoading}
                    />
                </div>
            </div>

            <!-- Password -->
            <div class="input-group">
                <label for="password" class="input-label">Password</label>
                <div class="input-wrapper">
                    <svg
                        class="input-icon"
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                    >
                        <rect
                            x="3"
                            y="11"
                            width="18"
                            height="11"
                            rx="2"
                            ry="2"
                        />
                        <path d="M7 11V7a5 5 0 0110 0v4" />
                    </svg>
                    <input
                        id="password"
                        type={showPassword ? "text" : "password"}
                        placeholder="Enter your password"
                        bind:value={password}
                        autocomplete="current-password"
                        disabled={isLoading}
                    />
                    <button
                        type="button"
                        class="toggle-password"
                        onclick={() => (showPassword = !showPassword)}
                        aria-label={showPassword
                            ? "Hide password"
                            : "Show password"}
                    >
                        {#if showPassword}
                            <svg
                                width="18"
                                height="18"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                            >
                                <path
                                    d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94"
                                />
                                <path
                                    d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19"
                                />
                                <line x1="1" y1="1" x2="23" y2="23" />
                            </svg>
                        {:else}
                            <svg
                                width="18"
                                height="18"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                            >
                                <path
                                    d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"
                                />
                                <circle cx="12" cy="12" r="3" />
                            </svg>
                        {/if}
                    </button>
                </div>
            </div>

            <!-- Error Message -->
            {#if errorMessage}
                <div class="error-message" role="alert">
                    <svg
                        width="16"
                        height="16"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                    >
                        <circle cx="12" cy="12" r="10" />
                        <line x1="15" y1="9" x2="9" y2="15" />
                        <line x1="9" y1="9" x2="15" y2="15" />
                    </svg>
                    {errorMessage}
                </div>
            {/if}

            <!-- Submit -->
            <button
                type="submit"
                class="btn-login"
                disabled={isLoading}
                id="login-button"
            >
                {#if isLoading}
                    <span class="spinner"></span>
                    Signing in...
                {:else}
                    Sign In
                {/if}
            </button>
        </form>

        <p class="footer-text">© 2026 Admin Panel. All rights reserved.</p>
    </div>
</div>

<style>
    /* ===== Login Page ===== */
    .login-page {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        position: relative;
        overflow: hidden;
        background: var(--color-bg);
    }

    /* Animated background orbs */
    .bg-orb {
        position: absolute;
        border-radius: 50%;
        filter: blur(80px);
        opacity: 0.5;
        pointer-events: none;
        animation: float 8s ease-in-out infinite;
    }

    .bg-orb--1 {
        width: 400px;
        height: 400px;
        background: rgba(108, 99, 255, 0.15);
        top: -100px;
        left: -100px;
        animation-delay: 0s;
    }

    .bg-orb--2 {
        width: 300px;
        height: 300px;
        background: rgba(0, 212, 170, 0.1);
        bottom: -50px;
        right: -50px;
        animation-delay: -3s;
    }

    .bg-orb--3 {
        width: 200px;
        height: 200px;
        background: rgba(108, 99, 255, 0.1);
        top: 50%;
        right: 20%;
        animation-delay: -5s;
    }

    @keyframes float {
        0%,
        100% {
            transform: translateY(0px) scale(1);
        }
        50% {
            transform: translateY(-30px) scale(1.05);
        }
    }

    /* Container */
    .login-container {
        position: relative;
        z-index: 1;
        width: 100%;
        max-width: 420px;
        padding: 24px;
        animation: fadeIn 0.6s ease;
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
            transform: translateY(20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    /* Brand */
    .brand {
        text-align: center;
        margin-bottom: 36px;
    }

    .brand-icon {
        display: inline-flex;
        margin-bottom: 16px;
        animation: pulse 3s ease-in-out infinite;
    }

    @keyframes pulse {
        0%,
        100% {
            filter: drop-shadow(0 0 8px var(--color-primary-glow));
        }
        50% {
            filter: drop-shadow(0 0 20px var(--color-primary-glow));
        }
    }

    .brand-title {
        font-size: 1.75rem;
        font-weight: 700;
        background: var(--gradient-primary);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        letter-spacing: -0.02em;
    }

    .brand-subtitle {
        color: var(--color-text-muted);
        font-size: 0.9rem;
        margin-top: 4px;
    }

    /* Card */
    .login-card {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        padding: 32px;
        backdrop-filter: blur(20px);
        box-shadow: var(--shadow-lg);
    }

    /* Input Groups */
    .input-group {
        margin-bottom: 20px;
    }

    .input-label {
        display: block;
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--color-text-muted);
        margin-bottom: 8px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .input-wrapper {
        position: relative;
        display: flex;
        align-items: center;
    }

    .input-icon {
        position: absolute;
        left: 14px;
        color: var(--color-text-faint);
        transition: color var(--transition-fast);
        pointer-events: none;
    }

    .input-wrapper input {
        width: 100%;
        padding: 14px 14px 14px 44px;
        background: var(--color-bg-input);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-md);
        color: var(--color-text);
        font-size: 0.95rem;
        transition:
            border-color var(--transition-fast),
            box-shadow var(--transition-fast);
    }

    .input-wrapper input::placeholder {
        color: var(--color-text-faint);
    }

    .input-wrapper input:focus {
        border-color: var(--color-border-focus);
        box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.15);
    }

    .input-wrapper:focus-within .input-icon {
        color: var(--color-primary);
    }

    .input-wrapper input:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }

    /* Toggle Password */
    .toggle-password {
        position: absolute;
        right: 12px;
        background: transparent;
        color: var(--color-text-faint);
        padding: 4px;
        display: flex;
        align-items: center;
        transition: color var(--transition-fast);
    }

    .toggle-password:hover {
        color: var(--color-text);
    }

    /* Error Message */
    .error-message {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 12px 16px;
        background: rgba(255, 77, 106, 0.08);
        border: 1px solid rgba(255, 77, 106, 0.2);
        border-radius: var(--radius-sm);
        color: var(--color-danger);
        font-size: 0.85rem;
        margin-bottom: 20px;
        animation: shake 0.4s ease;
    }

    @keyframes shake {
        0%,
        100% {
            transform: translateX(0);
        }
        25% {
            transform: translateX(-6px);
        }
        75% {
            transform: translateX(6px);
        }
    }

    /* Login Button */
    .btn-login {
        width: 100%;
        padding: 14px;
        background: var(--gradient-primary);
        color: white;
        font-size: 1rem;
        font-weight: 600;
        border-radius: var(--radius-md);
        transition:
            transform var(--transition-fast),
            box-shadow var(--transition-fast),
            opacity var(--transition-fast);
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        margin-top: 8px;
    }

    .btn-login:hover:not(:disabled) {
        transform: translateY(-1px);
        box-shadow: var(--shadow-glow);
    }

    .btn-login:active:not(:disabled) {
        transform: translateY(0);
    }

    .btn-login:disabled {
        opacity: 0.7;
        cursor: not-allowed;
    }

    /* Spinner */
    .spinner {
        width: 18px;
        height: 18px;
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-top-color: white;
        border-radius: 50%;
        animation: spin 0.6s linear infinite;
    }

    @keyframes spin {
        to {
            transform: rotate(360deg);
        }
    }

    /* Footer */
    .footer-text {
        text-align: center;
        color: var(--color-text-faint);
        font-size: 0.75rem;
        margin-top: 24px;
    }

    /* Responsive */
    @media (max-width: 480px) {
        .login-container {
            padding: 16px;
        }
        .login-card {
            padding: 24px;
        }
    }
</style>
