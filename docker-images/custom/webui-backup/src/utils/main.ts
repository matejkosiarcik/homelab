import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import { chromium, type Page } from 'playwright';
import { getBackupDir, getErrorAttachmentDir, getIsHeadless, getTargetUrl } from "./utils.ts";

export async function runAutomation(callback: (page: Page) => Promise<void>, options: { date: string }) {
    const setup = {
        backupDir: await getBackupDir(),
        errorDir: await getErrorAttachmentDir(),
        isHeadless: getIsHeadless(),
        baseUrl: getTargetUrl(),
    };

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'homelab-'));

    const browser = await chromium.launch({ headless: setup.isHeadless });
    try {
        const page = await browser.newPage({ baseURL: setup.baseUrl, strictSelectors: true, ignoreHTTPSErrors: true, recordVideo: { dir: tmpDir } });
        page.setDefaultNavigationTimeout(10_000);
        page.setDefaultTimeout(1000);

        try {
            await callback(page);
        } catch (error) {
            await page.screenshot({ fullPage: false, path: path.join(setup.errorDir, `${options.date}-viewport.png`) });
            await page.screenshot({ fullPage: true, path: path.join(setup.errorDir, `${options.date}-fullpage.png`) });
            throw error;
        } finally {
            await page.close();
        }
    } catch (error) {
        const files = await fs.readdir(tmpDir, { withFileTypes: true, recursive: false });
        const videoFiles = files.filter((el) => /\.webm$/.test(el.name)).map((el) => path.join(el.parentPath, el.name));
        for (const [index, videoFile] of videoFiles.entries()) {
            await fs.copyFile(videoFile, path.join(setup.errorDir, `${options.date}${index > 0 ? `-${index + 1}` : ''}.webm`));
        }
        throw error;
    } finally {
        await browser.close();
        await fs.rm(tmpDir, { force: true, recursive: true });
    }
}
