import path from 'node:path';
import { test as baseTest } from '@playwright/test';

/**
 * Return current test directory for storing temporary artifacts
 */
export function testArtifactDirectory(): string {
    const testInfo = baseTest.info();
    const testName = testInfo.titlePath.filter((el) => !!el).join(' ').replaceAll(/[^a-zA-Z0-9]+/g, '-');
    return path.join('tmp', testInfo.project.name, `test-name-${testName}---test-id-${testInfo.testId}---try-${testInfo.retry + 1}---worker-${testInfo.workerIndex}`);
}
