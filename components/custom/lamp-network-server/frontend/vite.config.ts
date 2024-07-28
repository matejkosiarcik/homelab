import path from 'node:path';
import { fileURLToPath, URL } from 'node:url';
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

const directory = path.join(fileURLToPath(new URL('.', import.meta.url)));

export default defineConfig({
    plugins: [
        vue(),
    ],
    build: {
        rollupOptions: {
            input: path.join(directory, 'index.html'),
        },
        outDir: path.join(directory, '..', 'dist', 'frontend'),
    },
});
