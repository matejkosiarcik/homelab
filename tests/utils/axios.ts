import https from 'node:https';
import { default as baseAxios, type CreateAxiosDefaults, type AxiosInstance } from 'axios';

export function createAxios(axiosConfig?: CreateAxiosDefaults | undefined): AxiosInstance {
    const axios = baseAxios.create({
        timeout: 2500,
        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
        maxRedirects: 999,
        validateStatus: () => true,
        ...axiosConfig,
    });

    return axios;
}

export const axios = createAxios();
export default axios;
