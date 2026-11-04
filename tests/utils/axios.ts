import https from 'node:https';
import { default as baseAxios } from 'axios';

export const axios = baseAxios.create({
    timeout: 2500,
    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
    maxRedirects: 999,
    validateStatus: () => true,
});
