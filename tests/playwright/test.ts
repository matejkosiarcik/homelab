import fs from 'node:fs';
import fsx from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { test as baseTest } from '@playwright/test';
import { expect as baseExpect } from './expect.ts';
import { extendBrowser, extendContext, extendPage, testArtifactDirectory } from './utils.ts';
import { OverridenBrowser, OverridenContext, OverridenPage } from '../types/playwright.ts';
import { faker } from '@faker-js/faker';

const customExpect = baseExpect;

const customTest = baseTest.extend<{
    // Test fixtures
    _mainTestFixture: void;
}, {
    // Worker fixtures
    _mainWorkerFixture: void;
}>({
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

    _mainTestFixture: [
        async ({ browser }, use) => {
            const errors: (Error | unknown)[] = [];

            /**
             * Preseed faker with random or predefined seed and attach it to test report
             * This is useful for reproducing the exact data when tracing flaky problems
             */
            const fakerSeed = (() => {
                if (process.env['FAKER_SEED']) {
                    const fakerSeed = Number.parseInt(process.env['FAKER_SEED'], 10);
                    if (Number.isNaN(fakerSeed)) {
                        throw new Error(`Invalid FAKER_SEED env value: ${process.env['FAKER_SEED']}`);
                    }
                    return faker.seed(fakerSeed);
                }
                return faker.seed();
            })();
            baseTest.info().annotations.push({ description: `${fakerSeed}`, type: 'faker-seed' });

            // Attach test end date
            const startDate = new Date();
            baseTest.info().annotations.push({ description: startDate.toISOString(), type: 'datetime-start' });

            await use();

            // Attach test end date
            const endDate = new Date();
            baseTest.info().annotations.push({ description: endDate.toISOString(), type: 'datetime-end' });

            const testId = baseTest.info().testId
            const retryIndex = baseTest.info().retry;
            const retryAttachmentLabel = retryIndex ? ` - retry ${retryIndex}` : '';
            const tmpDir = await fsx.mkdtemp(path.join(os.tmpdir(), 'test-attachments-'));

            const testDirectory = testArtifactDirectory();
            const pageDirectories = await (async () => {
                    if (!fs.existsSync(testDirectory)) {
                        return [];
                    }

                    const pageDirectories = (await fsx.readdir(testDirectory, { withFileTypes: true }))
                        .filter((entry) => entry.isDirectory() && /^page\-.+$/.test(entry.name))
                        .map((dir) => path.resolve(path.join(dir.parentPath, dir.name)))
                        .toSorted((lhs, rhs) => path.basename(lhs).localeCompare(path.basename(rhs)));
                    return pageDirectories;
            })();

            /**
             * Close all pages opened in this test
             */
            try {
                const pages = browser
                    .contexts()
                    .flatMap((context) => context.pages())
                    .filter((page) => (page as OverridenPage)._testid === testId)
                    .filter((page) => page.isClosed() === false);
                for (const page of pages) {
                    await page.close();
                }
            } catch (error) {
                errors.push(error);
            }

            /**
             * Close all contexts opened in this test
             */
            try {
                const contexts = browser
                    .contexts()
                    .filter((context) => (context as OverridenContext)._testid === testId)
                    .filter((context) => context.isClosed() === false);
                for (const context of contexts) {
                    await context.close();
                }
            } catch (error) {
                errors.push(error);
            }

            /**
             * Attach captured console logs from each page to test report
             */
            try {
                await (async () => {
                    for (const [index, directory] of pageDirectories.entries()) {
                        const filePath = path.join(directory, 'console.txt');
                        if (!fs.existsSync(filePath)) {
                            continue;
                        }

                        const stats = await fsx.stat(filePath);
                        if (stats.size <= 0) {
                            continue;
                        }

                        const filename = pageDirectories.length > 1 ? `Console logs - page ${index + 1}${retryAttachmentLabel}.txt` : `Console logs - page${retryAttachmentLabel}.txt`;
                        const newFile = path.join(tmpDir, filename);
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(filename, { contentType: 'text/plain', body: await fsx.readFile(newFile, 'utf8') });
                        } finally {
                            await fsx.rm(newFile, { force: true });
                        }
                    }
                })();
            } catch (error) {
                errors.push(error);
            }

            /**
             * Attach captured errors from each page to test report
             */
            try {
                await (async () => {
                    for (const [index, directory] of pageDirectories.entries()) {
                        const filePath = path.join(directory, 'errors.txt');
                        if (!fs.existsSync(filePath)) {
                            continue;
                        }

                        const stats = await fsx.stat(filePath);
                        if (stats.size <= 0) {
                            continue;
                        }

                        const filename = pageDirectories.length > 1 ? `Errors - page ${index + 1}${retryAttachmentLabel}.txt` : `Errors - page${retryAttachmentLabel}.txt`;
                        const newFile = path.join(tmpDir, filename);
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(filename, { contentType: 'text/plain', body: await fsx.readFile(newFile, 'utf8') });
                        } finally {
                            await fsx.rm(newFile, { force: true });
                        }
                    }
                })();
            } catch (error) {
                errors.push(error);
            }

            /**
             * Attach captured HARs from each page to test report
             */
            try {
                await (async () => {
                    for (const [index, directory] of pageDirectories.entries()) {
                        const filePath = path.join(directory, 'har.json');
                        if (!fs.existsSync(filePath)) {
                            continue;
                        }

                        const stats = await fsx.stat(filePath);
                        if (stats.size <= 0) {
                            continue;
                        }

                        const filename = pageDirectories.length > 1 ? `HAR - page ${index + 1}${retryAttachmentLabel}.json` : `HAR - page${retryAttachmentLabel}.json`;
                        const newFile = path.join(tmpDir, filename);
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(filename, { contentType: 'application/json', path: newFile });
                        } finally {
                            await fsx.rm(newFile, { force: true });
                        }
                    }
                })();
            } catch (error) {
                errors.push(error);
            }

            /**
             * Attach logger logs to test report
             */
            try {
                await (async () => {
                    const filePath = path.join(testDirectory, 'log.txt');
                    if (!fs.existsSync(filePath)) {
                        return;
                    }

                    const stats = await fsx.stat(filePath);
                    if (stats.size <= 0) {
                        return;
                    }

                    const filename = `Logs${retryAttachmentLabel}.txt`;
                    const newFile = path.join(tmpDir, filename);
                    try {
                        await fsx.copyFile(filePath, newFile);
                        await baseTest.info().attach(filename, { contentType: 'text/plain', body: await fsx.readFile(newFile, 'utf8') });
                    } finally {
                        await fsx.rm(newFile, { force: true });
                    }
                })();
            } catch (error) {
                errors.push(error);
            }

            /**
             * Remove temporary directory
             */
            try {
                await fsx.rm(tmpDir, { force: true, recursive: true });
            } catch (error) {
                errors.push(error);
            }

            if (errors.length > 0) {
                throw new AggregateError(errors, `Main test fixture got ${errors.length} error${errors.length > 1 ? 's' : ''}`);
            }

        },
        { auto: true, scope: 'test' },
    ],

    _mainWorkerFixture: [
        async ({}, use) => {
            await use();
        },
        { auto: true, scope: 'worker' },
    ],
});

customTest.expect = customExpect;

export const test = customTest;
export const expect = customExpect;
