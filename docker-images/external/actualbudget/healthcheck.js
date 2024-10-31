(async () => {
    const response = await fetch('http://localhost:5006', {
        method: 'HEAD',
    });

    if (!response.ok) {
        throw new Error(`Healthcheck response error ${response.status}`);
    }
})();
