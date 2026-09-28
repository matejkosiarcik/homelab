import type { Options as ExecaOptions } from 'execa';
import { execa as baseExeca } from 'execa';
import getos from 'getos';
import _ from 'lodash';

// eslint-disable no-console

async function getOperatingSystem(): Promise<getos.Os> {
    return await new Promise((resolve, reject) => {
        getos((error, operatingSystem) => {
            if (error) {
                reject(error);
                return;
            }

            resolve(operatingSystem);
        });
    });
}

async function execa(command: string[]): Promise<void> {
    const osInfo = await getOperatingSystem();

    const execaEnvOptions: Record<string, string> = {};
    if (osInfo.os === 'linux' && ['Debian', 'Ubuntu'].includes(osInfo.dist)) {
        execaEnvOptions['DEBCONF_NOWARNINGS'] = 'yes';
        execaEnvOptions['DEBCONF_TERSE'] = 'yes';
        execaEnvOptions['DEBIAN_FRONTEND'] = 'noninteractive';
    }

    const execaOptions: ExecaOptions = {
        all: true,
        env: execaEnvOptions,
        timeout: 2 * 60_000, // 2 minutes
    };
    await baseExeca(command[0], command.slice(1), execaOptions);
}

async function installBrowsers() {
    if (process.env['INSTALL_BROWSERS'] === 'no') {
        console.log('Skipping browser installation.');
        return;
    }

    const browsers = ['chromium', 'firefox', 'webkit'];
    console.log(`Installing browsers: ${browsers.join(', ')}.`);

    // Install browsers system dependencies (apt packages, etc)
    for (const browser of browsers) {
        console.log(`Installing system dependencies for ${browser}...`);
        await execa(['playwright', 'install-deps', browser]);
    }

    // Install browsers
    for (const browser of browsers) {
        console.log(`Installing ${browser}...`);
        await execa(['playwright', 'install', browser]);
    }

    console.log('Success.');
}

void (async () => {
    await installBrowsers();
})();
