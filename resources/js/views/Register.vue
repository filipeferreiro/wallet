<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100 px-4">
    <div class="max-w-md w-full bg-white rounded-lg shadow-md p-8">
      <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">Criar Conta Fintech</h2>
      
      <div v-if="errorMsg" class="mb-4 p-3 bg-red-100 text-red-700 rounded-md text-sm">
        {{ errorMsg }}
      </div>

      <form @submit.prevent="handleRegister" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">Nome</label>
          <input v-model="form.name" type="text" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 bg-gray-50 p-2 border" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">E-mail</label>
          <input v-model="form.email" type="email" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 bg-gray-50 p-2 border" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">Senha</label>
          <input v-model="form.password" type="password" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 bg-gray-50 p-2 border" />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">Confirmar Senha</label>
          <input v-model="form.password_confirmation" type="password" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 bg-gray-50 p-2 border" />
        </div>

        <button type="submit" :disabled="loading" class="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50">
          {{ loading ? 'Registrando...' : 'Registrar' }}
        </button>
      </form>

      <p class="mt-4 text-center text-sm text-gray-600">
        Já tem uma conta? <router-link to="/login" class="text-indigo-600 hover:text-indigo-500 font-medium">Faça login</router-link>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { useWalletStore } from '../stores/walletStore';
import { useRouter } from 'vue-router';

const walletStore = useWalletStore();
const router = useRouter();

const form = reactive({ name: '', email: '', password: '', password_confirmation: '' });
const loading = ref(false);
const errorMsg = ref('');

const handleRegister = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    await walletStore.register(form);
    router.push('/');
  } catch (err) {
    errorMsg.value = err.response?.data?.message || 'Erro ao registrar usuário.';
  } finally {
    loading.value = false;
  }
};
</script>