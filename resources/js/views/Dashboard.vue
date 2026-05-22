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
          <div v-if="feedback.deposit.msg" :class="feedback.deposit.type === 'success' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="p-2 mb-3 rounded text-sm">
            {{ feedback.deposit.msg }}
          </div>
          <form @submit.prevent="executeDeposit" class="space-y-3">
            <input v-model.number="amountDeposit" type="number" step="0.01" min="0.01" placeholder="Valor (R$)" required class="w-full rounded-md border-gray-300 shadow-sm p-2 bg-gray-50 border focus:ring-indigo-500 focus:border-indigo-500" />
            <button type="submit" class="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-md shadow-sm text-sm">Depositar</button>
          </form>
        </div>

        <div>
          <h3 class="text-lg font-bold text-gray-800 mb-4">Efetuar Saque</h3>
          <div v-if="feedback.withdraw.msg" :class="feedback.withdraw.type === 'success' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="p-2 mb-3 rounded text-sm">
            {{ feedback.withdraw.msg }}
          </div>
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

const feedback = reactive({
  deposit: { msg: '', type: '' },
  withdraw: { msg: '', type: '' }
});

onMounted(() => {
  walletStore.fetchDashboard();
});

const clearFeedback = () => {
  feedback.deposit = { msg: '', type: '' };
  feedback.withdraw = { msg: '', type: '' };
};

/**
 * Executa depósito e atualiza feedback do usuário.
 * Limpa o input após sucesso.
 */
const executeDeposit = async () => {
  clearFeedback();
  try {
    const res = await walletStore.deposit(amountDeposit.value);
    feedback.deposit = { msg: res.message, type: 'success' };
    amountDeposit.value = '';
  } catch (err) {
    feedback.deposit = { 
      msg: err.response?.data?.error || 'Erro no depósito.', 
      type: 'error' 
    };
  }
};

/**
 * Executa saque com validação redundante de saldo no frontend
 * para melhor UX (validação no backend garante integridade).
 */
const executeWithdraw = async () => {
  clearFeedback();
  
  if (amountWithdraw.value > walletStore.balance) {
    feedback.withdraw = { 
      msg: 'Saldo insuficiente para realizar esta operação.', 
      type: 'error' 
    };
    return;
  }

  try {
    const res = await walletStore.withdraw(amountWithdraw.value);
    feedback.withdraw = { msg: res.message, type: 'success' };
    amountWithdraw.value = '';
  } catch (err) {
    feedback.withdraw = { 
      msg: err.response?.data?.error || 'Erro no saque.', 
      type: 'error' 
    };
  }
};

const handleLogout = async () => {
  await walletStore.logout();
  router.push('/login');
};
</script>