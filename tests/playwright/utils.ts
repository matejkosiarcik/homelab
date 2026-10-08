import path from 'node:path';
import { test as baseTest, Browser, BrowserContext, Page } from '@playwright/test';
import { OverridenBrowser, OverridenContext, OverridenPage } from '../types/playwright';

/**
 * Return current test directory for storing temporary artifacts
 */
export function testArtifactDirectory(): string {
    const testInfo = baseTest.info();
    const testName = testInfo.titlePath.filter((el) => !!el).join(' ').replaceAll(/[^a-zA-Z0-9]+/g, '-');
    return path.join('tmp', testInfo.project.name, `test-name-${testName}---test-id-${testInfo.testId}---try-${testInfo.retry + 1}---worker-${testInfo.workerIndex}`);
}

export async function extendPage(_page: Page): Promise<OverridenPage> {
    const page = (_page as OverridenPage);

    // Abort when the page is already overriden
    if (page._overridden) {
        return page;
    }

    // Set defaults
    page._overridden ??= true;
    page._default ??= false;

    // await setupPageConsoleCapture(page);
    // await setupPageErrorCapture(page);
    // await setupPageHarCapture(page);

    return page;
}

export async function extendContext(_context: BrowserContext): Promise<OverridenContext> {
    const context = (_context as OverridenContext);
    await new Promise((resolve, _) => { resolve(true) }); // Placeholder to avoid ESLint error

    // Abort when the context is already overriden
    if (context._overridden) {
        return context;
    }

    // Set defaults
    context._overridden ??= true;
    context._default ??= false;

    // Make sure all opened pages in this context are automatically extended
    context._newPage = context.newPage;
    context.newPage = async function (...args) {
        const page = await this._newPage(...args);
        await extendPage(page);
        return page;
    };

    return context;
}

export async function extendBrowser(_browser: Browser): Promise<OverridenBrowser> {
    const browser = (_browser as OverridenBrowser);
    await new Promise((resolve, _) => { resolve(true) }); // Placeholder to avoid ESLint error

    // Abort when the browser is already overriden
    if (browser._overridden) {
        return browser;
    }

    // Set defaults
    browser._overridden ??= true;
    browser._default ??= false;

    // Make sure all opened pages in this browser are automatically extended
    browser._newPage = browser.newPage;
    browser.newPage = async function (..._args) {
        const args = (_args as Parameters<Browser['newPage']>)[0] ?? {};
        const page = await this._newPage(args);
        await extendPage(page);
        return page;
    };

    // Make sure all opened contexts in this browser are automatically extended
    browser._newContext = browser.newContext;
    browser.newContext = async function (..._args) {
        const args = (_args as Parameters<Browser['newContext']>)[0] ?? {};
        const context = await this._newContext(args);
        await extendContext(context);
        return context;
    };

    return browser;
}
