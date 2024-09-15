import typescript from '@rollup/plugin-typescript';

export default [
    {
        input: [
            'src/docker-cache-proxy/admin-setup.ts',
        ],
        output: {
            dir: 'dist/docker-cache-proxy',
            format: 'esm',
        },
        plugins: [typescript()],
    },
    {
        input: [
            'src/home-assistant/backup.ts',
        ],
        output: {
            dir: 'dist/home-assistant',
            format: 'esm',
        },
        plugins: [typescript()],
    },
    {
        input: [
            'src/omada-controller/backup.ts',
        ],
        output: {
            dir: 'dist/omada-controller',
            format: 'esm',
        },
        plugins: [typescript()],
    },
    {
        input: [
            'src/pihole/backup.ts',
            'src/pihole/update-gravity.ts',
        ],
        output: {
            dir: 'dist/pihole',
            format: 'esm',
        },
        plugins: [typescript()],
    },
    {
        input: [
            'src/speedtest-tracker/admin-setup.ts',
            'src/speedtest-tracker/export.ts',
        ],
        output: {
            dir: 'dist/speedtest-tracker',
            format: 'esm',
        },
        plugins: [typescript()],
    },
    {
        input: [
            'src/unifi-controller/backup.ts',
        ],
        output: {
            dir: 'dist/unifi-controller',
            format: 'esm',
        },
        plugins: [typescript()],
    },
    {
        input: [
            'src/uptime-kuma/admin-setup.ts',
            'src/uptime-kuma/backup.ts',
        ],
        output: {
            dir: 'dist/uptime-kuma',
            format: 'esm',
        },
        plugins: [typescript()],
    },
];
