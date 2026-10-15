<template>
  <main id="not-found-page" class="page container">
    <div class="centered-wrapper">
      <h1>404</h1>
      <h2>Not Found</h2>
      <RouterLink :to="{ name: 'home' }" class="button">Go home</RouterLink>
    </div>
  </main>
</template>

<style scoped>
#not-found-page {
  display: grid;
  place-items: center;
}

.centered-wrapper {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.container {
  text-align: center;
}
</style>
