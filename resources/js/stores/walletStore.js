import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import api from '../services/api';

export const useWalletStore = defineStore('wallet', () => {
    const user = ref(JSON.parse(localStorage.getItem('user')) || null);
    const token = ref(localStorage.getItem('token') || null);
    const balance = ref(0);
    const latestTransactions = ref([]);
    const metrics = ref({ total_deposited_month: 0, total_withdrawn_month: 0 });

    const isAuthenticated = computed(() => !!token.value);

    async function login(credentials) {
        const response = await api.post('/login', credentials);
        token.value = response.data.access_token;
        user.value = response.data.user;
        localStorage.setItem('token', token.value);
        localStorage.setItem('user', JSON.stringify(user.value));
    }

    async function register(userData) {
        const response = await api.post('/register', userData);
        token.value = response.data.access_token;
        user.value = response.data.user;
        localStorage.setItem('token', token.value);
        localStorage.setItem('user', JSON.stringify(user.value));
    }

    async function logout() {
        try {
            await api.post('/logout');
        } catch (error) {
            // Backend pode retornar erro se token inválido, mas limpamos localmente mesmo assim
            console.error('Erro ao notificar servidor do logout:', error);
        } finally {
            token.value = null;
            user.value = null;
            balance.value = 0;
            latestTransactions.value = [];
            metrics.value = { total_deposited_month: 0, total_withdrawn_month: 0 };
            localStorage.removeItem('token');
            localStorage.removeItem('user');
        }
    }

    async function fetchDashboard() {
        const response = await api.get('/dashboard');
        balance.value = response.data.balance;
        latestTransactions.value = response.data.latest_transactions;
        metrics.value = response.data.metrics;
    }

    /**
     * Response já contém novo saldo; fetchDashboard() removido por redundância.
     * O servidor garante consistência via transações, então um update é suficiente.
     */
    async function deposit(amount) {
        const response = await api.post('/wallet/deposit', { amount });
        balance.value = response.data.balance;
        await fetchDashboard(); // Atualiza transações e métricas imediatamente
        return response.data;
    }

    /**
     * Similar ao deposit: response contém novo saldo.
     * Transações são recarregadas na próxima navegação ou fetch explícito.
     */
    async function withdraw(amount) {
        const response = await api.post('/wallet/withdraw', { amount });
        balance.value = response.data.balance;
        await fetchDashboard(); // Atualiza transações e métricas imediatamente
        return response.data;
    }

    return {
        user,
        token,
        balance,
        latestTransactions,
        metrics,
        isAuthenticated,
        login,
        register,
        logout,
        fetchDashboard,
        deposit,
        withdraw
    };
});