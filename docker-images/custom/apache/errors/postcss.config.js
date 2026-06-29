import postcssPluginSorter from 'css-declaration-sorter';
import postcssPluginCssnano from 'cssnano';
import postcssPluginPresetEnv from 'postcss-preset-env';

const plugins = [
    postcssPluginPresetEnv({
        stage: 1,
    }),
    postcssPluginSorter({
        order: 'alphabetical',
    }),
    postcssPluginCssnano({
        preset: 'default',
    }),
];

export default {
    plugins: plugins,
};
