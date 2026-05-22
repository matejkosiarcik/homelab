import process from 'node:process';

async function main() {
    const response = await fetch('http://localhost:5006', {
        method: 'HEAD',
    });

    if (!response.ok) {
        throw new Error(`Response error ${response.status}`);
    }
}

(async () => {
    try {
        await main();
    } catch (error) {
        console.error(`Healthcheck error: ${error}`);
        process.exit(1);
    }
})();
