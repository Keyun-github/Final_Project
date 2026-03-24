<script lang="ts">
    // ---- Employee Management ----
    interface Employee {
        id: number;
        name: string;
        telp: string;
        username: string;
        password: string;
        active: boolean;
    }

    let employees = $state<Employee[]>([
        {
            id: 1,
            name: "Budi Santoso",
            telp: "081234567890",
            username: "budi",
            password: "budi123",
            active: true,
        },
        {
            id: 2,
            name: "Siti Nurhaliza",
            telp: "082345678901",
            username: "siti",
            password: "siti123",
            active: true,
        },
        {
            id: 3,
            name: "Ahmad Wijaya",
            telp: "083456789012",
            username: "ahmad",
            password: "ahmad123",
            active: false,
        },
        {
            id: 4,
            name: "Dewi Lestari",
            telp: "084567890123",
            username: "dewi",
            password: "dewi123",
            active: true,
        },
        {
            id: 5,
            name: "Rizky Pratama",
            telp: "085678901234",
            username: "rizky",
            password: "rizky123",
            active: true,
        },
    ]);

    let showModal = $state(false);
    let newName = $state("");
    let newTelp = $state("");
    let newUsername = $state("");
    let newPassword = $state("");
    let formError = $state("");

    function openModal() {
        newName = "";
        newTelp = "";
        newUsername = "";
        newPassword = "";
        formError = "";
        showModal = true;
    }

    function closeModal() {
        showModal = false;
    }

    function addEmployee() {
        if (!newName.trim()) {
            formError = "Name is required";
            return;
        }
        if (!newTelp.trim()) {
            formError = "Phone number is required";
            return;
        }
        if (!newUsername.trim()) {
            formError = "Username is required";
            return;
        }
        if (!newPassword.trim()) {
            formError = "Password is required";
            return;
        }

        const nextId =
            employees.length > 0
                ? Math.max(...employees.map((e) => e.id)) + 1
                : 1;
        employees = [
            ...employees,
            {
                id: nextId,
                name: newName.trim(),
                telp: newTelp.trim(),
                username: newUsername.trim(),
                password: newPassword.trim(),
                active: true,
            },
        ];
        closeModal();
    }

    function toggleActive(id: number) {
        employees = employees.map((e) =>
            e.id === id ? { ...e, active: !e.active } : e,
        );
    }
</script>

<!-- Top Actions -->
<div class="page-actions">
    <button class="btn-add" onclick={openModal} id="btn-add-employee">
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
        Add Employee
    </button>
</div>

<!-- Employee Table -->
<div class="table-container">
    <table class="employee-table">
        <thead>
            <tr>
                <th class="col-no">No</th>
                <th class="col-name">Name</th>
                <th class="col-telp">Telp Number</th>
                <th class="col-status">Status</th>
            </tr>
        </thead>
        <tbody>
            {#each employees as emp, i}
                <tr class:inactive={!emp.active}>
                    <td class="col-no">{i + 1}</td>
                    <td class="col-name">
                        <div class="employee-name">
                            <div
                                class="employee-avatar"
                                style="background: {emp.active
                                    ? 'var(--color-primary)'
                                    : 'var(--color-text-faint)'}"
                            >
                                {emp.name.charAt(0).toUpperCase()}
                            </div>
                            {emp.name}
                        </div>
                    </td>
                    <td class="col-telp">{emp.telp}</td>
                    <td class="col-status">
                        <button
                            class="toggle-btn"
                            class:active={emp.active}
                            onclick={() => toggleActive(emp.id)}
                            title={emp.active
                                ? "Click to deactivate"
                                : "Click to activate"}
                        >
                            <span class="toggle-track">
                                <span class="toggle-thumb"></span>
                            </span>
                            <span class="toggle-label"
                                >{emp.active ? "Active" : "Inactive"}</span
                            >
                        </button>
                    </td>
                </tr>
            {/each}
            {#if employees.length === 0}
                <tr>
                    <td colspan="4" class="empty-state">
                        No employees found. Click "Add Employee" to get started.
                    </td>
                </tr>
            {/if}
        </tbody>
    </table>
</div>

<!-- Add Employee Modal -->
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
                <h3>Add New Employee</h3>
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
                    addEmployee();
                }}
            >
                <div class="form-group">
                    <label for="emp-name">Full Name</label>
                    <input
                        id="emp-name"
                        type="text"
                        placeholder="Enter employee name"
                        bind:value={newName}
                    />
                </div>
                <div class="form-group">
                    <label for="emp-telp">Phone Number</label>
                    <input
                        id="emp-telp"
                        type="tel"
                        placeholder="e.g. 081234567890"
                        bind:value={newTelp}
                    />
                </div>
                <div class="form-group">
                    <label for="emp-user">Username</label>
                    <input
                        id="emp-user"
                        type="text"
                        placeholder="Enter username"
                        bind:value={newUsername}
                    />
                </div>
                <div class="form-group">
                    <label for="emp-pass">Password</label>
                    <input
                        id="emp-pass"
                        type="password"
                        placeholder="Enter password"
                        bind:value={newPassword}
                    />
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
                        id="btn-submit-employee">Save Employee</button
                    >
                </div>
            </form>
        </div>
    </div>
{/if}

<style>
    /* ===== Page Actions ===== */
    .page-actions {
        margin-bottom: 24px;
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
    }

    .btn-add:hover {
        transform: translateY(-1px);
        box-shadow: var(--shadow-glow);
    }

    /* ===== Table ===== */
    .table-container {
        background: var(--color-bg-card);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        overflow: hidden;
    }

    .employee-table {
        width: 100%;
        border-collapse: collapse;
    }

    .employee-table thead {
        background: rgba(108, 99, 255, 0.05);
    }

    .employee-table th {
        padding: 14px 20px;
        font-size: 0.75rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        text-align: left;
        border-bottom: 1px solid var(--color-border);
    }

    .employee-table td {
        padding: 16px 20px;
        font-size: 0.9rem;
        border-bottom: 1px solid var(--color-border);
        color: var(--color-text);
    }

    .employee-table tr:last-child td {
        border-bottom: none;
    }

    .employee-table tbody tr {
        transition: background var(--transition-fast);
    }

    .employee-table tbody tr:hover {
        background: rgba(108, 99, 255, 0.03);
    }

    .employee-table tbody tr.inactive {
        opacity: 0.55;
    }

    .col-no {
        width: 60px;
        text-align: center !important;
    }
    .col-status {
        width: 160px;
    }

    .employee-name {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .employee-avatar {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.8rem;
        color: white;
        flex-shrink: 0;
    }

    .empty-state {
        text-align: center !important;
        padding: 48px 20px !important;
        color: var(--color-text-faint) !important;
        font-style: italic;
    }

    /* ===== Toggle Button ===== */
    .toggle-btn {
        display: flex;
        align-items: center;
        gap: 10px;
        background: transparent;
        cursor: pointer;
        padding: 4px;
    }

    .toggle-track {
        width: 40px;
        height: 22px;
        border-radius: 20px;
        background: var(--color-text-faint);
        position: relative;
        transition: background var(--transition-fast);
        flex-shrink: 0;
    }

    .toggle-btn.active .toggle-track {
        background: var(--color-success);
    }

    .toggle-thumb {
        width: 16px;
        height: 16px;
        border-radius: 50%;
        background: white;
        position: absolute;
        top: 3px;
        left: 3px;
        transition: transform var(--transition-fast);
    }

    .toggle-btn.active .toggle-thumb {
        transform: translateX(18px);
    }

    .toggle-label {
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--color-text-muted);
    }

    .toggle-btn.active .toggle-label {
        color: var(--color-success);
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
        max-width: 460px;
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
        margin-bottom: 18px;
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

    .form-group input {
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

    .form-group input::placeholder {
        color: var(--color-text-faint);
    }

    .form-group input:focus {
        border-color: var(--color-border-focus);
        box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.15);
    }

    .form-error {
        padding: 10px 14px;
        background: rgba(255, 77, 106, 0.08);
        border: 1px solid rgba(255, 77, 106, 0.2);
        border-radius: var(--radius-sm);
        color: var(--color-danger);
        font-size: 0.8rem;
        margin-bottom: 18px;
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

    @media (max-width: 480px) {
        .modal {
            margin: 16px;
        }
        .employee-table th:nth-child(3),
        .employee-table td:nth-child(3) {
            display: none;
        }
    }
</style>
