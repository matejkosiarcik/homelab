import typescript from '@rollup/plugin-typescript';

export default {
    input: 'backend/main.ts',
    output: {
        dir: 'dist/backend',
        format: 'esm',
    },
    plugins: [typescript()],
};
