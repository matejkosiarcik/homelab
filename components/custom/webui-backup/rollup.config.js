import typescript from '@rollup/plugin-typescript';

export default {
    input: [
        'src/omada-controller.ts',
        'src/pihole.ts',
        'src/unifi-controller.ts',
        'src/uptime-kuma.ts',
    ],
    output: {
        dir: 'dist',
        format: 'esm',
    },
    plugins: [typescript()],
};
