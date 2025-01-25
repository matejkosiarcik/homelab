import events from 'node:events';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import dotenv from 'dotenv';
import type { PlaywrightTestConfig, Project, ReporterDescription } from '@playwright/test';
import { defineConfig } from '@playwright/test';

// Increase limit (default is 10) to not run into "MaxListenersExceededWarning"
events.EventEmitter.defaultMaxListeners = 100;

// Load env files
if (fs.existsSync('.env')) {
    dotenv.config({ path: '.env' });
}

// Test reporters
const reporters: ReporterDescription[] = [
    ['list'],
    [
        'html',
        {
            open: 'never',
            outputFolder: path.join('test-report', 'html'),
        },
    ],
];

// Test projects
const projects: Project[] = [
    {
        name: 'tests',
    },
];

// Final config
const config: PlaywrightTestConfig = {
    forbidOnly: false,
    fullyParallel: true,
    globalTimeout: 55 * 60_000,
    outputDir: path.join('test-report', 'artifacts'),
    projects: projects,
    reporter: reporters,
    reportSlowTests: null,
    retries: 0,
    testDir: path.join('projects', 'tests'),
    timeout: 2 * 60_000,
    workers: os.cpus().length,
    use: {
        baseURL: 'https://example.com',
        headless: true,
        viewport: {
            width: 1280,
            height: 720,
        },
        video: 'off',
        screenshot: 'only-on-failure',
        trace: 'off',
        actionTimeout: 1000,
        navigationTimeout: 20_000,
        contextOptions: {
            strictSelectors: true,
            ignoreHTTPSErrors: true,
        },
        ignoreHTTPSErrors: true,
    },
};

export default defineConfig(config);
