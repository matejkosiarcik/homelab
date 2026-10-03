import fsx from 'node:fs/promises';

async function globalSetup(): Promise<void> {
	await Promise.all(['tmp', 'test-report'].map((dir) => fsx.rm(dir, { force: true, recursive: true })));
	await Promise.all(['tmp'].map((dir) => fsx.mkdir(dir, { recursive: true })));
}

export default globalSetup;
