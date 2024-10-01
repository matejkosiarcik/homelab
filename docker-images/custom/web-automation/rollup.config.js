import typescript from '@rollup/plugin-typescript';

const files = {
    'home-assistant': ['backup.ts'],
    'omada-controller': ['backup.ts'],
    'unifi-controller': ['backup.ts'],
};

const exportArray = Object.entries(files).map(([directory, files]) => ({
    input: files.map((file) => `src/${directory}/${file}`),
    output: {
        dir: `dist/${directory}`,
        format: 'esm',
    },
    plugins: [typescript()],
}));

export default exportArray;
