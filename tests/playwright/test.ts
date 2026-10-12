import fs from 'node:fs';
import fsx from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { faker } from '@faker-js/faker';
import { test as baseTest } from '@playwright/test';
import { expect as baseExpect } from '#/playwright/expect.ts';
import { extendBrowser, extendContext, extendPage, testArtifactDirectory } from '#/playwright/utils.ts';
import type { OverridenBrowser, OverridenContext, OverridenPage } from '#/types/playwright.d.ts';

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

            // Attach test start date
            const startDate = new Date();
            baseTest.info().annotations.push({ description: startDate.toISOString(), type: 'datetime-start' });

            await use();

            // Attach test end date
            const endDate = new Date();
            baseTest.info().annotations.push({ description: endDate.toISOString(), type: 'datetime-end' });

            const testId = baseTest.info().testId
            baseTest.info().annotations.push({ description: testId, type: 'test-id' });

            const testLocation = {
                file: baseTest.info().file.replace(process.cwd(), '.'),
                line: baseTest.info().line,
                column: baseTest.info().column,
            }
            baseTest.info().annotations.push({ description: `${testLocation.file}:${testLocation.line}:${testLocation.column}`, type: 'test-location' });

            const parallelIndex = baseTest.info().parallelIndex;
            baseTest.info().annotations.push({ description: parallelIndex.toFixed(0), type: 'parallel-index' });

            const workerIndex = baseTest.info().workerIndex;
            baseTest.info().annotations.push({ description: workerIndex.toFixed(0), type: 'worker-index' });

            const repeatEachIndex = baseTest.info().repeatEachIndex;
            baseTest.info().annotations.push({ description: repeatEachIndex.toFixed(0), type: 'repeat-index' });

            const retryIndex = baseTest.info().retry;
            baseTest.info().annotations.push({ description: retryIndex.toFixed(0), type: 'retry-index' });
            const retryAttachmentLabel = retryIndex > 0 ? ` - retry ${retryIndex}` : '';

            const tmpDirectory = await fsx.mkdtemp(path.join(os.tmpdir(), 'test-attachments-'));
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
            baseTest.info().annotations.push({ description: pageDirectories.length.toFixed(0), type: 'pages-count' });

            function attachmenName(options: { prefix: string, page: number, extension: string }): string {
                const pageLabel = ` - page${pageDirectories.length > 1 ? ` ${(options.page + 1).toFixed(0)}` : ''}`;
                return `${options.prefix}${pageLabel}${retryAttachmentLabel}.${options.extension}`;
            }

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

                        const newFile = path.join(tmpDirectory, attachmenName({ prefix: 'Console logs', page: index, extension: 'txt' }));
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(path.basename(newFile), { contentType: 'text/plain', body: await fsx.readFile(newFile, 'utf8') });
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

                        const newFile = path.join(tmpDirectory, attachmenName({ prefix: 'Errors', page: index, extension: 'txt' }));
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(path.basename(newFile), { contentType: 'text/plain', body: await fsx.readFile(newFile, 'utf8') });
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

                        const newFile = path.join(tmpDirectory, attachmenName({ prefix: 'HAR', page: index, extension: 'json' }));
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(path.basename(newFile), { contentType: 'application/json', path: newFile });
                        } finally {
                            await fsx.rm(newFile, { force: true });
                        }
                    }
                })();
            } catch (error) {
                errors.push(error);
            }

            /**
             * Attach recorded videos from each page to test report
             */
            try {
                await (async () => {
                    for (const [index, directory] of pageDirectories.entries()) {
                        const filePath = ['webm', 'mp4'].map((extension) => path.join(directory, `video.${extension}`)).find((filePath) => fs.existsSync(filePath))!;
                        if (!filePath) {
                            continue;
                        }
                        const fileExtension = path.extname(filePath).slice(1);

                        const stats = await fsx.stat(filePath);
                        if (stats.size <= 0) {
                            continue;
                        }

                        const newFile = path.join(tmpDirectory, attachmenName({ prefix: 'Video', page: index, extension: fileExtension }));
                        try {
                            await fsx.copyFile(filePath, newFile);
                            await baseTest.info().attach(path.basename(newFile), { contentType: `video/${fileExtension}`, path: newFile });
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
                    const newFile = path.join(tmpDirectory, filename);
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
                await fsx.rm(tmpDirectory, { force: true, recursive: true });
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
