const fs = require('fs');

async function delay(delay) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve(true);
        }, delay);
    });
}

(async () => {
    fs.writeFileSync('../hardware-controller/pipe.bin', '123', 'utf8');
    await delay(2500);
    fs.writeFileSync('../hardware-controller/pipe.bin', '456', 'utf8');
})()
