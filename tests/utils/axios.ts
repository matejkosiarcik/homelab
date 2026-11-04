import https from 'node:https';
import { default as baseAxios, type CreateAxiosDefaults, type AxiosInstance, type AxiosRequestConfig, AxiosError, isAxiosError } from 'axios';
import { Log } from './log';
import { formatDuration } from './utils';

type CustomAxiosRequestConfig = AxiosRequestConfig & {
    startedDate: Date | undefined;
};

export function createAxios(axiosConfig?: CreateAxiosDefaults | undefined): AxiosInstance {
    const axios = baseAxios.create({
        timeout: 2500,
        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
        maxRedirects: 999,
        validateStatus: () => true,
        ...axiosConfig,
    });

    axios.interceptors.request.use(
        async (request) => {
            const startedDate = new Date();
            (request as CustomAxiosRequestConfig).startedDate = startedDate;
            request.headers.set('X-Test-Request-Date', startedDate.toISOString());
            return request;
        },
        (error) => error,
    );

    axios.interceptors.response.use(
        async (response) => {
            const endedDate = new Date();
            const request = (response.config satisfies AxiosRequestConfig) as CustomAxiosRequestConfig;
            const startedDate = request.startedDate ?? null;
            const totalTime = startedDate ? endedDate.getTime() - startedDate!.getTime() : -1;

            response.headers['X-Test-Response-Date'] = endedDate.toISOString();
            response.headers['X-Test-Response-Time'] = totalTime.toString();

            return response;
        },
        async (_error) => {
            const endedDate = new Date();

            if (isAxiosError(_error)) {
                const error = _error as AxiosError;
                const request = error.config as CustomAxiosRequestConfig;
                const startedDate = request.startedDate ?? null;
                const totalTime = startedDate ? endedDate.getTime() - startedDate!.getTime() : -1;
                Log.error(`Axios request failed: ${error.message}\n- ${error.stack}\n- Started: ${startedDate?.toISOString()}\n- Ended: ${endedDate.toISOString()}\n- Total time: ${formatDuration(totalTime)}\n- Request: ${JSON.stringify(request, null, 2).replaceAll(/^/gm, '-- ')}\n- Response: ${JSON.stringify(error.response, null, 2).replaceAll(/^/gm, '-- ')}`);
            } else if (_error instanceof Error) {
                const error = _error as Error;
                Log.error(`Axios request failed: ${error.message}\n${error.stack}`);
            } else {
                const error = _error as unknown;
                Log.error(`Axios request failed: ${error}`);
            }

            return _error;
        },
    );

    return axios;
}

export const axios = createAxios();
export default axios;
