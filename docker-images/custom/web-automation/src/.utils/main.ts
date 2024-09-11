import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { chromium, type Page } from 'playwright';
import { getAppName, getBrowserPath, getErrorAttachmentDir, getIsHeadless, getTargetUrl } from './utils.ts';

export async function runAutomation<T>(callback: (page: Page) => Promise<T>, _options: { date: string }): Promise<T> {
    const options = {
        ..._options,
        errorDir: await getErrorAttachmentDir(),
        isHeadless: getIsHeadless(),
        baseUrl: getTargetUrl(),
        browserPath: getBrowserPath(),
    };

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'homelab-'));

    const browser = await chromium.launch({ executablePath: options.browserPath, headless: options.isHeadless });
    let isBrowserOpen = true;
    try {
        const page = await browser.newPage({ baseURL: options.baseUrl, strictSelectors: true, ignoreHTTPSErrors: true, recordVideo: { dir: tmpDir } });
        if (['omada-controller', 'unifi-controller'].includes(getAppName())) {
            page.setDefaultNavigationTimeout(15_000);
            page.setDefaultTimeout(5000);
        } else if (['pihole'].includes(getAppName())) {
            page.setDefaultNavigationTimeout(15_000);
            page.setDefaultTimeout(4000);
        } else {
            page.setDefaultNavigationTimeout(10_000);
            page.setDefaultTimeout(2000);
        }

        try {
            return await callback(page);
        } catch (error) {
            await page.screenshot({ fullPage: false, path: path.join(options.errorDir, `${options.date}-viewport.png`), timeout: 10_000 });
            await page.screenshot({ fullPage: true, path: path.join(options.errorDir, `${options.date}-fullpage.png`), timeout: 10_000 });
            throw error;
        } finally {
            await page.close();
        }
    } catch (error) {
        await browser.close();
        isBrowserOpen = false;
        const files = await fs.readdir(tmpDir, { withFileTypes: true, recursive: false });
        const videoFiles = files.filter((el) => /\.webm$/.test(el.name)).map((el) => path.join(el.parentPath, el.name));
        for (const [index, videoFile] of videoFiles.entries()) {
            await fs.copyFile(videoFile, path.join(options.errorDir, `${options.date}${index > 0 ? `-${index + 1}` : ''}.webm`));
        }
        throw error;
    } finally {
        if (isBrowserOpen) {
            await browser.close();
        }
        await fs.rm(tmpDir, { force: true, recursive: true });
    }
}
