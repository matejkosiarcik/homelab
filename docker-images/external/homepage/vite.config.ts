import path from 'node:path';
import { fileURLToPath, URL } from 'node:url';
import { defineConfig } from 'vite';

const directory = path.join(fileURLToPath(new URL('.', import.meta.url)));

export default defineConfig({
    build: {
        rollupOptions: {
            input: path.join(directory, 'src', 'main.ts'),
            output: {
                dir: path.join(directory, 'dist'),
                entryFileNames: 'main.js',
            }
        },
    },
});
