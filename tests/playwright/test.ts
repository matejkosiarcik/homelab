import { test as baseTest } from '@playwright/test';
import { expect as baseExpect } from './expect.ts';
import { extendBrowser, extendContext, extendPage } from './utils.ts';
import { OverridenBrowser, OverridenContext, OverridenPage } from '../types/playwright.ts';

const customExpect = baseExpect;

const customTest = baseTest.extend<{}, {}>({
    browser: async ({ browser }, use) => {
        (browser as OverridenBrowser)._default = true;
        await extendBrowser(browser);
        await use(browser);
    },

    context: async ({ context }, use) => {
        (context as OverridenContext)._default = true;
        await extendContext(context);
        await use(context);
    },

    page: async ({ page }, use) => {
        (page as OverridenPage)._default = true;
        await extendPage(page);
        await use(page);
    },
});

customTest.expect = customExpect;

export const test = customTest;
export const expect = customExpect;
