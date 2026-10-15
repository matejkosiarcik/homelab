<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter();

function logIn() {
  // TODO: Actually perform login here
  // TODO: Also handle errors and show them to the user
  void router.push({ name: 'dashboard' });
}
</script>

<template>
  <main id="login-page" class="page container">
    <form class="login-form" @submit.prevent="logIn">
      <h1>Log in</h1>

      <label>
        <span>Username</span>
        <input type="text" name="username" autocomplete="username" required />
      </label>

      <label>
        <span>Password</span>
        <input type="password" name="password" autocomplete="current-password" required />
      </label>

      <button type="submit">Log in</button>
    </form>
  </main>
</template>

<style scoped>
#login-page {
  display: grid;
  place-items: center;
}

.login-form {
  display: grid;
  width: min(100%, 20rem);
  gap: 1rem;
}

label {
  display: grid;
  gap: 0.25rem;
}
</style>
