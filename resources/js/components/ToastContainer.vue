<template>
  <div class="fixed top-4 right-4 z-50 flex flex-col space-y-3 w-full max-w-sm pointer-events-none">
    <transition-group 
      enter-active-class="transform ease-out duration-300 transition"
      enter-from-class="translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
      enter-to-class="translate-y-0 opacity-100 sm:translate-x-0"
      leave-active-class="transition ease-in duration-200"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div 
        v-for="toast in walletStore.toasts" 
        :key="toast.id"
        :class="[
          toast.type === 'success' ? 'bg-green-600' : 'bg-red-600',
          'pointer-events-auto flex items-center p-4 rounded-lg shadow-xl text-white border border-white/10'
        ]"
      >
        <span class="mr-3 flex-shrink-0">
          <svg v-if="toast.type === 'success'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </span>
        <div class="text-sm font-medium pr-2 break-words">
          {{ toast.message }}
        </div>
      </div>
    </transition-group>
  </div>
</template>

<script setup>
import { useWalletStore } from '../stores/walletStore'; // ajuste o nível de pastas (../) se necessário para chegar em stores/
const walletStore = useWalletStore();
</script>