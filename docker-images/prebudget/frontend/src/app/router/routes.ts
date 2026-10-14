import type { RouteRecordRaw } from 'vue-router';

export const routes: RouteRecordRaw[] = [
    {
        path: '/',
        name: 'home',
        redirect: { name: 'login' },
    },
    {
        path: '/login',
        children: [
        {
            path: '',
            name: 'login',
            component: () => import('@/pages/unlogged/login/LoginPage.vue'),
            meta: { title: 'Log in' },
        },
        ],
    },
    {
        path: '/dashboard',
        component: () => import('@/layouts/AppShell.vue'),
        children: [
        {
            path: '',
            name: 'dashboard',
            component: () => import('@/pages/logged/dashboard/DashboardPage.vue'),
            meta: { title: 'Dashboard' },
        },
        {
            path: 'transactions',
            name: 'transactions',
            component: () => import('@/pages/logged/transactions/TransactionsPage.vue'),
            meta: { title: 'Transactions' },
        },
        {
            path: 'rules',
            name: 'rules',
            component: () => import('@/pages/logged/rules/RulesPage.vue'),
            meta: { title: 'Rules' },
        },
        {
            path: 'import',
            name: 'import',
            component: () => import('@/pages/logged/import/ImportPage.vue'),
            meta: { title: 'Import' },
        },
        ],
    },
    {
        path: '/:pathMatch(.*)*',
        children: [
        {
            path: '',
            name: 'not-found',
            component: () => import('@/pages/unlogged/not-found/NotFoundPage.vue'),
            meta: { title: 'Page not found' },
        },
        ],
    },
];
