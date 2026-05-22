<template>
  <div class="antialiased min-h-screen bg-gray-100 text-gray-900">
    <router-view/>
    <ToastContainer />
  </div>
</template>

<script setup>
import ToastContainer from './components/ToastContainer.vue';
</script>