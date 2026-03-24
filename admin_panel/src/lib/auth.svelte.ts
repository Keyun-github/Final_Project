import { goto } from '$app/navigation';

// ---- Types ----
interface User {
    username: string;
    role: string;
}

interface AuthState {
    isAuthenticated: boolean;
    user: User | null;
}

// ---- Reactive State (Svelte 5 Runes) ----
let authState = $state<AuthState>({
    isAuthenticated: false,
    user: null
});

// ---- Hardcoded Credentials ----
const VALID_USERNAME = 'admin';
const VALID_PASSWORD = 'admin';

// ---- Public API ----

export function getAuth(): AuthState {
    return authState;
}

export function login(username: string, password: string): { success: boolean; message: string } {
    if (username === VALID_USERNAME && password === VALID_PASSWORD) {
        authState.isAuthenticated = true;
        authState.user = { username, role: 'Administrator' };
        return { success: true, message: 'Login successful' };
    }
    return { success: false, message: 'Invalid username or password' };
}

export function logout(): void {
    authState.isAuthenticated = false;
    authState.user = null;
    goto('/');
}

export function requireAuth(): boolean {
    if (!authState.isAuthenticated) {
        goto('/');
        return false;
    }
    return true;
}
