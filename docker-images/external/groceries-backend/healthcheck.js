(async () => {
    const response = await fetch('http://localhost:3333', {
        method: 'HEAD',
    });

    if (response.ok || (response.status >= 200 && response.status < 500)) {
        return;
    }

    throw new Error(`Healthcheck response error ${response.status}`);
})();
