<script setup lang="ts">
import { ref } from 'vue';
import { getStatus, changeStatus } from './utils/api.ts';
import { useToast } from 'vue-toast-notification';

const button = ref(null);
const data = {
  status: ref(false),
  initialLoading: ref(true),
};
const $toast = useToast();

function setStatus(status: boolean) {
  data.status.value = status;
  document.title = `Lamp ${data.status.value ? 'ON ⚡️' : 'OFF ⏻'}`;
}

async function toggleButton() {
  const buttonElement = button.value as unknown as HTMLButtonElement;
  buttonElement.disabled = true;
  try {
    const newStatus = await changeStatus(!data.status.value);
    setStatus(newStatus);
  } catch {
    $toast.error('Could not change status', { position: 'top' });
  } finally {
    buttonElement.disabled = false;
  }
}

(async () => {
  const initialStatus = await getStatus();
  setStatus(initialStatus);

  // Initial load
  data.initialLoading.value = false;
  const buttonElement = button.value as unknown as HTMLButtonElement;
  buttonElement.disabled = false;
})();
</script>

<template>
  <main class="container">
    <p>
      {{
        data.initialLoading.value
          ? '&nbsp;'
          : data.status.value
          ? '⚡️ On ⚡️'
          : '💤 Off 💤'
      }}
    </p>
    <button
      class="toggle-button"
      :class="{ no_disabled: data.initialLoading.value }"
      @click="toggleButton"
      ref="button"
      disabled
    >
      {{
        data.initialLoading.value ? '&nbsp;' : data.status.value ? 'Off' : 'On'
      }}
    </button>
    <p>&nbsp;</p>
  </main>
</template>
