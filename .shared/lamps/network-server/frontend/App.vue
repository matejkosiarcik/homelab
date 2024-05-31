<script setup lang="ts">
import { ref } from 'vue';
import { getStatus, changeStatus } from './utils/api.ts';

const data = {
    status: ref(false),
};

function setStatus(status: boolean) {
    data.status.value = status;
    document.title = `${data.status.value ? '⚡️' : '⏻'} Lamp ${data.status.value ? 'on ⚡️' : 'off ⏻'}`;
}

async function toggleButton() {
    const newStatus = await changeStatus(!data.status.value);
    setStatus(newStatus);
}

(async () => {
    const initialStatus = await getStatus();
    setStatus(initialStatus);
})();
</script>

<template>
    <main class="container">
        <p>{{ data.status.value ? '⚡️ On ⚡️' : '💤 Off 💤' }}</p>
        <button class="toggle-button" @click="toggleButton">
            {{ data.status.value ? 'Off' : 'On' }}
        </button>
        <p>&nbsp;</p>
    </main>
</template>
