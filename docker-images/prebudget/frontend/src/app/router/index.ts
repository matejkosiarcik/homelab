import { createRouter, createWebHistory } from 'vue-router';

import { routes } from './routes';

export const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes,
    scrollBehavior: () => ({ top: 0 }),
});

router.afterEach((to) => {
    const title = to.meta['title'];
    document.title = typeof title === 'string' ? `PreBudget | ${title}` : 'PreBudget';
});
