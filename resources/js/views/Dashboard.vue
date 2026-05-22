<template>
  <div class="min-h-screen bg-gray-100 text-gray-900">
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-6xl mx-auto px-4 py-4 flex justify-between items-center">
        <span class="text-xl font-bold text-indigo-600">Wallet Dashboard</span>
        <div class="flex items-center space-x-4">
          <span class="text-sm text-gray-600 font-medium">Olá, {{ walletStore.user?.name }}</span>
          <router-link to="/historico" class="text-sm text-indigo-600 hover:underline">Histórico Completo</router-link>
          <button @click="handleLogout" class="text-sm text-red-600 hover:underline font-medium">Sair</button>
        </div>
      </div>
    </nav>

    <div class="max-w-6xl mx-auto px-4 py-8 grid grid-cols-1 md:grid-cols-3 gap-6">
      
      <div class="bg-white p-6 rounded-lg shadow-sm border flex flex-col justify-between">
        <span class="text-sm font-semibold text-gray-500 uppercase">Saldo Atual</span>
        <span class="text-3xl font-bold text-gray-800 mt-2">R$ {{ formatCurrency(walletStore.balance) }}</span>
      </div>

      <div class="bg-white p-6 rounded-lg shadow-sm border flex flex-col justify-between">
        <span class="text-sm font-semibold text-green-600 uppercase">Entradas (Mês Atual)</span>
        <span class="text-2xl font-bold text-green-600 mt-2">+ R$ {{ formatCurrency(walletStore.metrics.total_deposited_month) }}</span>
      </div>

      <div class="bg-white p-6 rounded-lg shadow-sm border flex flex-col justify-between">
        <span class="text-sm font-semibold text-red-600 uppercase">Saídas (Mês Atual)</span>
        <span class="text-2xl font-bold text-red-600 mt-2">- R$ {{ formatCurrency(walletStore.metrics.total_withdrawn_month) }}</span>
      </div>

      <div class="md:col-span-2 bg-white p-6 rounded-lg shadow-sm border grid grid-cols-1 md:grid-cols-2 gap-6">
        
        <div class="border-b md:border-b-0 md:border-r md:pr-6 pb-6 md:pb-0">
          <h3 class="text-lg font-bold text-gray-800 mb-4">Efetuar Depósito</h3>
          <form @submit.prevent="executeDeposit" class="space-y-3">
            <input v-model.number="amountDeposit" type="number" step="0.01" min="0.01" placeholder="Valor (R$)" required class="w-full rounded-md border-gray-300 shadow-sm p-2 bg-gray-50 border focus:ring-indigo-500 focus:border-indigo-500" />
            <button type="submit" class="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-md shadow-sm text-sm">Depositar</button>
          </form>
        </div>

        <div>
          <h3 class="text-lg font-bold text-gray-800 mb-4">Efetuar Saque</h3>
          <form @submit.prevent="executeWithdraw" class="space-y-3">
            <input v-model.number="amountWithdraw" type="number" step="0.01" min="0.01" placeholder="Valor (R$)" required class="w-full rounded-md border-gray-300 shadow-sm p-2 bg-gray-50 border focus:ring-indigo-500 focus:border-indigo-500" />
            <button type="submit" class="w-full bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded-md shadow-sm text-sm">Sacar</button>
          </form>
        </div>

      </div>

      <div class="bg-white p-6 rounded-lg shadow-sm border">
        <h3 class="text-lg font-bold text-gray-800 mb-4">Últimas Movimentações</h3>
        <div v-if="walletStore.latestTransactions.length === 0" class="text-sm text-gray-500 py-4 text-center">
          Nenhuma transação registrada.
        </div>
        <ul v-else class="divide-y divide-gray-100">
          <li v-for="tx in walletStore.latestTransactions" :key="tx.id" class="py-3 flex justify-between items-center">
            <div>
              <p class="text-sm font-semibold" :class="tx.type === 'credit' ? 'text-green-600' : 'text-red-600'">
                {{ tx.type === 'credit' ? 'Depósito' : 'Saque' }}
              </p>
              <p class="text-xs text-gray-400">{{ formatDate(tx.created_at) }}</p>
            </div>
            <span class="text-sm font-bold" :class="tx.type === 'credit' ? 'text-green-600' : 'text-red-600'">
              {{ tx.type === 'credit' ? '+' : '-' }} R$ {{ formatCurrency(tx.amount) }}
            </span>
          </li>
        </ul>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { useWalletStore } from '../stores/walletStore';
import { useRouter } from 'vue-router';
import { useFormatters } from '../composables/useFormatters';

const walletStore = useWalletStore();
const router = useRouter();
const { formatCurrency, formatDate } = useFormatters();

const amountDeposit = ref('');
const amountWithdraw = ref('');

onMounted(() => {
  walletStore.fetchDashboard();
});

const executeDeposit = async () => {
  try {
    const res = await walletStore.deposit(amountDeposit.value);
    walletStore.addToast(res.message, 'success');
    amountDeposit.value = '';
  } catch (err) {
    const errorMsg = err.response?.data?.error || 'Erro no depósito.';
    walletStore.addToast(errorMsg, 'error');
  }
};

/**
 * Executa saque com validação redundante de saldo no frontend
 * para melhor UX (validação no backend garante integridade).
 */
const executeWithdraw = async () => {
  
  if (amountWithdraw.value > walletStore.balance) {
    walletStore.addToast('Saldo insuficiente para realizar esta operação.', 'error');
    return;
  }

  try {
    const res = await walletStore.withdraw(amountWithdraw.value);
    walletStore.addToast(res.message, 'success');
    amountWithdraw.value = '';
  } catch (err) {
    const errorMsg = err.response?.data?.error || 'Erro no saque.';
    walletStore.addToast(errorMsg, 'error');
  }
};

const handleLogout = async () => {
  await walletStore.logout();
  router.push('/login');
};
</script>