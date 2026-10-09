import fs from 'node:fs';
import fsx from 'node:fs/promises';
import path from 'node:path';
import { test as baseTest, Browser, BrowserContext, Page } from '@playwright/test';
import { OverridenBrowser, OverridenContext, OverridenPage } from '../types/playwright';

/**
 * Return current test directory for storing temporary artifacts
 */
export function testArtifactDirectory(): string {
    const testInfo = baseTest.info();
    const testName = testInfo.titlePath.filter((el) => !!el).join(' ').replaceAll(/[^a-zA-Z0-9]+/g, '-');
    return path.join('tmp', testInfo.project.name, `test---name-${testName}---id-${testInfo.testId}---try-${testInfo.retry + 1}---worker-${testInfo.workerIndex}`);
}

export function pageArtifactDirectory(page: OverridenPage): string {
    const pageDirectoryName = `page---date-${page._openedAt.date.toISOString().replaceAll(/[:.]/g, '-')}---hrtime-${page._openedAt.hrtime.toString(10)}`;
    return path.join(testArtifactDirectory(), pageDirectoryName);
}

export async function extendPage(_page: Page): Promise<OverridenPage> {
    const page = (_page as OverridenPage);

    // Abort when the page is already overridden
    if (page._overridden) {
        return page;
    }

    // Set defaults
    page._overridden ??= true;
    page._default ??= false;
    page._openedAt ??= { date: new Date(), hrtime: process.hrtime.bigint() };

    await setupPageConsoleCapture(page);
    await setupPageErrorCapture(page);
    await setupPageHarCapture(page);

    return page;
}

export async function extendContext(_context: BrowserContext): Promise<OverridenContext> {
    const context = (_context as OverridenContext);
    await new Promise((resolve, _) => { resolve(true) }); // Placeholder to avoid ESLint error

    // Abort when the context is already overridden
    if (context._overridden) {
        return context;
    }

    // Set defaults
    context._overridden ??= true;
    context._default ??= false;
    context._openedAt ??= { date: new Date(), hrtime: process.hrtime.bigint() };

    // Make sure all opened pages in this context are automatically extended
    context._newPageOriginal = context.newPage;
    context.newPage = async function (...args) {
        const page = await this._newPageOriginal(...args);
        await extendPage(page);
        return page;
    };

    return context;
}

export async function extendBrowser(_browser: Browser): Promise<OverridenBrowser> {
    const browser = (_browser as OverridenBrowser);
    await new Promise((resolve, _) => { resolve(true) }); // Placeholder to avoid ESLint error

    // Abort when the browser is already overridden
    if (browser._overridden) {
        return browser;
    }

    // Set defaults
    browser._overridden ??= true;
    browser._default ??= false;
    browser._openedAt ??= { date: new Date(), hrtime: process.hrtime.bigint() };

    // Make sure all opened pages in this browser are automatically extended
    browser._newPageOriginal = browser.newPage;
    browser.newPage = async function (..._args) {
        const args = (_args as Parameters<Browser['newPage']>)[0] ?? {};
        const page = await this._newPageOriginal(args);
        await extendPage(page);
        return page;
    };

    // Make sure all opened contexts in this browser are automatically extended
    browser._newContextOriginal = browser.newContext;
    browser.newContext = async function (..._args) {
        const args = (_args as Parameters<Browser['newContext']>)[0] ?? {};
        const context = await this._newContextOriginal(args);
        await extendContext(context);
        return context;
    };

    return browser;
}

/**
 * Forward page console logs into an attachment file
 */
async function setupPageConsoleCapture(page: OverridenPage): Promise<void> {
    const outputFile = path.join(pageArtifactDirectory(page), 'console.txt');

    // Precreate empty output file
    await fsx.mkdir(path.dirname(outputFile), { recursive: true });
    await fsx.writeFile(outputFile, '', 'utf8');

    // Forward each console.[log/error/etc...] into output file
    page.on('console', async (message) => {
        const date = new Date().toISOString();
        const location = `${message.location().url || 'N/A'}:${message.location().line ?? '?'}:${message.location().column ?? '?'}`;
        const output = message.text()
            .trim()
            .split('\n')
            .map((line) => `${date} console.${message.type()} from ${location} at ${page.url()} | ${line.trim()}\n`)
            .join('\n');
        await fsx.appendFile(outputFile, output, 'utf8');
    });
}

/**
 * Forward page errors into an attachment file
 */
async function setupPageErrorCapture(page: OverridenPage): Promise<void> {
    const outputFile = path.join(pageArtifactDirectory(page), 'errors.txt');

    // Precreate empty output file
    await fsx.mkdir(path.dirname(outputFile), { recursive: true });
    await fsx.writeFile(outputFile, '', 'utf8');

    // Forward errors into output file
    page.on('pageerror', (error) => {
        const date = new Date().toISOString();
        let output = `${date} error-${error.name} as ${page.url()}:`;

        const message = (error.message || 'N/A')
            .trim()
            .split('\n')
            .map((line) => ` | ${line.trim()}`)
            .join('\n');
        output += `\n | Message:\n${message}`;

        if (error.cause) {
            const cause = `${error.cause}`
                .trim()
                .split('\n')
                .map((line) => ` | ${line.trim()}`)
                .join('\n');
            output += `\n | Cause:\n${cause}`;
        }

        if (error.stack) {
            const stack = `${error.stack}`
                .trim()
                .split('\n')
                .map((line) => ` | ${line.trim()}`)
                .join('\n');
            output += `\n | Stack:\n${stack}`;
        }

        fs.appendFileSync(outputFile, output, 'utf8');
    });

    // Forward crashes into output file
    page.on('crash', (page) => {
        const date = new Date().toISOString();
        const output = `${date} crash at ${page.url()}`;
        fs.appendFileSync(outputFile, output, 'utf8');
    });
}

/**
 * Save HAR into an attachment file
 */
async function setupPageHarCapture(page: OverridenPage): Promise<void> {
    const outputFile = path.join(pageArtifactDirectory(page), 'har.json');

    // Precreate empty output file
    await fsx.mkdir(path.dirname(outputFile), { recursive: true });
    await fsx.writeFile(outputFile, '', 'utf8');

    // Capture HAR directly into output file
    await page.routeFromHAR(outputFile, {
        update: true,
        updateContent: 'embed',
        updateMode: 'full',
    });
}
