<script setup lang="ts">
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const router = useRouter();
const route = useRoute();

const pageId = computed(() => `${String(route.name)}-page`);

function logOut() {
  void router.push({ name: 'home' });
}
</script>

<template>
  <header class="app-header container">
    <nav>
      <RouterLink :to="{ name: 'dashboard' }" class="button">Dashboard</RouterLink>
      <RouterLink :to="{ name: 'transactions' }" class="button">Transactions</RouterLink>
      <RouterLink :to="{ name: 'rules' }" class="button">Rules</RouterLink>
      <RouterLink :to="{ name: 'import' }" class="button">Import</RouterLink>
    </nav>
    <button type="button" @click="logOut">Log out</button>
  </header>

  <div :id="pageId" class="page container">
    <RouterView />
  </div>
</template>

<style scoped>
.app-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  justify-content: space-between;
  flex-wrap: wrap;
}

nav {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}
</style>
