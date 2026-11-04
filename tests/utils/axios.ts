import https from 'node:https';
import { default as baseAxios, type CreateAxiosDefaults, type AxiosInstance, type AxiosRequestConfig, AxiosError, isAxiosError, AxiosResponse } from 'axios';
import _ from 'lodash';
import { AxiosHarStore } from './har-store';
import { Log } from './log';
import { capitalize, formatDuration } from './utils';

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
            response.headers['X-Test-Response-Duration'] = totalTime.toString();

            AxiosHarStore.shared.addEntry({
                request: {
                    body: getAxiosRequestRawText(request),
                    headers: getAxiosRequestHeaders(request),
                    method: request.method ?? 'N/A',
                    url: request.url ?? 'N/A',
                    startDate: startedDate,
                },
                response: {
                    body: await getAxiosResponseRawText(response),
                    error: null,
                    headers: getAxiosResponseHeaders(response),
                    status: response.status,
                    statusText: response.statusText,
                    endDate: endedDate,
                },
            });

            return response;
        },
        async (_error) => {
            const endedDate = new Date();

            if (isAxiosError(_error)) {
                const error = _error as AxiosError;
                const request = error.config as CustomAxiosRequestConfig;
                const startedDate = request.startedDate ?? null;
                const totalTime = startedDate ? endedDate.getTime() - startedDate!.getTime() : -1;

                AxiosHarStore.shared.addEntry({
                    request: {
                        body: getAxiosRequestRawText(request),
                        headers: getAxiosRequestHeaders(request),
                        method: request.method ?? 'N/A',
                        url: request.url ?? 'N/A',
                        startDate: startedDate,
                    },
                    response: {
                        body: await getAxiosResponseRawText(error),
                        error: null,
                        headers: getAxiosResponseHeaders(error),
                        status: error.status ?? 0,
                        statusText: 'N/A',
                        endDate: endedDate,
                    },
                });

                Log.error(`Axios request failed: ${error.message?.replaceAll(/^/gm, '- ')}\n- ${error.stack?.replaceAll(/^/gm, '- ')}\n- Started: ${startedDate?.toISOString()}\n- Ended: ${endedDate.toISOString()}\n- Total time: ${formatDuration(totalTime)}\n- Request URL: ${URL.parse(request.url ?? '', request.baseURL ?? '')}\n- Response Status: ${error.response?.status}`);
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

/**
 * Get request headers
 */
export function getAxiosRequestHeaders(request: AxiosRequestConfig): Record<string, MaybeArray<string>> {
    const headers = request.headers ?? {};
    return Object.keys(headers)
        .filter((key) => key)
        .filter((key) => headers[key])
        .filter((key) => [headers[key]].flat()[0])
        .reduce(
            (output, _key) => {
                const key = capitalize(_key);
                const values = output[key] ?? [];
                values.push(headers[_key]);
                output[key] = values;
                return output;
            },
            {} as Record<string, Array<string>>,
        );
}

/**
 * Get request body text (raw)
 */
export function getAxiosRequestRawText(request: AxiosRequestConfig): string {
    if (!request.data) {
        return '';
    } else if (typeof request.data === 'string') {
        return request.data;
    }

    try {
        return JSON.stringify(request.data);
    } catch {
        return `${request.data}`;
    }
}

/**
 * Get response headers
 */
export function getAxiosResponseHeaders(responseOrError: AxiosError | AxiosResponse): Record<string, MaybeArray<string>> {
    const response = isAxiosError(responseOrError) ? responseOrError.response : responseOrError;
    if (!response) {
        return {};
    }

    const headers = response.headers;
    return Object.keys(headers)
        .filter((key) => key)
        .filter((key) => headers[key])
        .filter((key) => [headers[key]].flat()[0])
        .reduce(
            (output, _key) => {
                const key = capitalize(_key);
                const values = output[key] ?? [];
                values.push(headers[_key]);
                output[key] = values;
                return output;
            },
            {} as Record<string, Array<string>>,
        );
}

/**
 * Get response body text (raw)
 */
export async function getAxiosResponseRawText(responseOrError: AxiosError | AxiosResponse): Promise<string> {
    const response = isAxiosError(responseOrError) ? responseOrError.response : responseOrError;

    if (!response || !response.data) {
        return '';
    } else if (typeof response.data === 'string') {
        return response.data;
    }

    try {
        return JSON.stringify(response.data);
    } catch {
        return `${response.data}`;
    }
}
