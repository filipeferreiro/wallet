<template>
  <div class="min-h-screen bg-gray-100 text-gray-900 pb-12">
    <nav class="bg-white shadow-sm border-b mb-8">
      <div class="max-w-6xl mx-auto px-4 py-4 flex justify-between items-center">
        <router-link to="/" class="text-xl font-bold text-indigo-600 hover:opacity-80">← Voltar ao Dashboard</router-link>
        <span class="text-sm text-gray-500 font-medium">Extrato Completo</span>
      </div>
    </nav>

    <div class="max-w-6xl mx-auto px-4">
      <div class="bg-white p-4 rounded-lg shadow-sm border mb-6 flex flex-wrap gap-4 items-end">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase mb-1">Tipo</label>
          <select v-model="filters.type" class="rounded-md border-gray-300 shadow-sm p-2 bg-gray-50 border text-sm focus:ring-indigo-500 focus:border-indigo-500">
            <option value="">Todos</option>
            <option value="credit">Crédito (Depósitos)</option>
            <option value="debit">Débito (Saques)</option>
          </select>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase mb-1">Data Inicial</label>
          <input v-model="filters.start_date" type="date" class="rounded-md border-gray-300 shadow-sm p-2 bg-gray-50 border text-sm focus:ring-indigo-500 focus:border-indigo-500" />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase mb-1">Data Final</label>
          <input v-model="filters.end_date" type="date" class="rounded-md border-gray-300 shadow-sm p-2 bg-gray-50 border text-sm focus:ring-indigo-500 focus:border-indigo-500" />
        </div>
        <div class="flex gap-2">
          <button @click="loadHistory(1)" class="bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2 px-4 rounded-md text-sm shadow-sm">Filtrar</button>
          <button @click="clearFilters" class="bg-gray-200 hover:bg-gray-300 text-gray-700 font-medium py-2 px-4 rounded-md text-sm">Limpar</button>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow-sm border overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200 text-left">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Data/Hora</th>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Tipo</th>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Valor</th>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Saldo Após</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-if="historyData.data.length === 0">
              <td colspan="4" class="px-6 py-8 text-center text-sm text-gray-500">Nenhuma movimentação encontrada para os filtros aplicados.</td>
            </tr>
            <tr v-for="tx in historyData.data" :key="tx.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 text-sm text-gray-600">{{ formatDate(tx.created_at) }}</td>
              <td class="px-6 py-4 text-sm font-semibold" :class="tx.type === 'credit' ? 'text-green-600' : 'text-red-600'">
                {{ tx.type === 'credit' ? 'Crédito (Depósito)' : 'Débito (Saque)' }}
              </td>
              <td class="px-6 py-4 text-sm font-bold" :class="tx.type === 'credit' ? 'text-green-600' : 'text-red-600'">
                {{ tx.type === 'credit' ? '+' : '-' }} R$ {{ formatCurrency(tx.amount) }}
              </td>
              <td class="px-6 py-4 text-sm text-gray-700 font-medium">R$ {{ formatCurrency(tx.balance_after) }}</td>
            </tr>
          </tbody>
        </table>

        <div v-if="historyData.last_page > 1" class="bg-gray-50 px-6 py-4 flex items-center justify-between border-t">
          <button :disabled="historyData.current_page === 1" @click="loadHistory(historyData.current_page - 1)" class="px-3 py-1 bg-white border rounded text-sm disabled:opacity-50 font-medium">Anterior</button>
          <span class="text-sm text-gray-600">Página {{ historyData.current_page }} de {{ historyData.last_page }}</span>
          <button :disabled="historyData.current_page === historyData.last_page" @click="loadHistory(historyData.current_page + 1)" class="px-3 py-1 bg-white border rounded text-sm disabled:opacity-50 font-medium">Próxima</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, onMounted } from 'vue';
import api from '../services/api';

const filters = reactive({ type: '', start_date: '', end_date: '' });
const historyData = reactive({ data: [], current_page: 1, last_page: 1 });

const loadHistory = async (page = 1) => {
  try {
    const response = await api.get('/wallet/history', {
      params: { page, ...filters }
    });
    historyData.data = response.data.data;
    historyData.current_page = response.data.current_page;
    historyData.last_page = response.data.last_page;
  } catch (err) {
    console.error('Erro ao buscar histórico', err);
  }
};

const clearFilters = () => {
  filters.type = '';
  filters.start_date = '';
  filters.end_date = '';
  loadHistory(1);
};

onMounted(() => loadHistory(1));

const formatCurrency = (val) => Number(val).toFixed(2).replace('.', ',');
const formatDate = (dateStr) => new Date(dateStr).toLocaleString('pt-BR');
</script>