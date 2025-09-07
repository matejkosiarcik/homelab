import typescript from '@rollup/plugin-typescript';

const files = {
    'homeassistant': ['backup.ts'],
    'omadacontroller': ['backup.ts'],
    'unificontroller': ['backup.ts'],
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
