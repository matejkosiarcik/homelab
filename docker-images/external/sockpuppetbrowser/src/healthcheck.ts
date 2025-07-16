import WebSocket from 'ws';

async function delay(ms: number): Promise<void> {
    return new Promise((resolve) => {
        setTimeout(() => resolve(), ms);
    });
}

(async () => {
    const url = 'ws://localhost:3000';
    const ws = new WebSocket(url);
    await delay(100);
    const wsState = ws.readyState;
    ws.close();

    if (wsState === 1) {
        return;
    }

    console.error(`WebSocket did not connect -> ${wsState}`);
    process.exit(1);
})();
