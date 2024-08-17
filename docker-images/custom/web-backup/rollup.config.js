import typescript from '@rollup/plugin-typescript';

export default [
    {
        input: [
            'src/backup/omada-controller.ts',
            'src/backup/pihole.ts',
            'src/backup/unifi-controller.ts',
            'src/backup/uptime-kuma.ts',
        ],
        output: {
            dir: 'dist/backup',
            format: 'esm',
        },
        plugins: [typescript()],
    }
];
