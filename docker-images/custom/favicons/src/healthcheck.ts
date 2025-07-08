import axios from 'axios';

(async () => {
    const response = await axios.get('http://localhost:8080/.health', {
        validateStatus: () => true,
    });
    if (response.status !== 200) {
        console.error(`Healthcheck error -> ${response.status}: ${response.data}`);
        process.exit(1);
    }
})();
