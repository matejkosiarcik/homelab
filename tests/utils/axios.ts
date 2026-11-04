import http, { type ClientRequest } from 'node:http';
import https from 'node:https';
import { isIP } from 'node:net';
import { performance } from 'node:perf_hooks';
import { default as baseAxios, type CreateAxiosDefaults, type AxiosInstance, type AxiosRequestConfig, AxiosError, isAxiosError, AxiosResponse } from 'axios';
import _ from 'lodash';
import { AxiosHarStore, type AxiosHarTimings } from './har-store';
import { Log } from './log';
import { capitalize, formatDuration } from './utils';

type CustomAxiosRequestConfig = AxiosRequestConfig & {
    startedDate?: Date | undefined;
};

const axiosHarTiming = Symbol('axiosHarTiming');
const instrumentedAxiosAgents = new WeakSet<object>();

type AgentRequestOptions = {
    hostname?: string | undefined;
    protocol?: string | undefined;
};

type InstrumentedAgent = {
    addRequest?: ((request: ClientRequest, ...args: unknown[]) => void) | undefined;
};

type TimedClientRequest = ClientRequest & {
    [axiosHarTiming]?: AxiosRequestTiming | undefined;
    _currentRequest?: TimedClientRequest | undefined;
};

class AxiosRequestTiming {
    private readonly _startedAt = performance.now();
    private _connectedAt: number | undefined;
    private _dnsEndedAt: number | undefined;
    private _dnsDoesNotApply = false;
    private _requestFinishedAt: number | undefined;
    private _responseEndedAt: number | undefined;
    private _responseStartedAt: number | undefined;
    private _secureConnectedAt: number | undefined;
    private _socketAssignedAt: number | undefined;
    private _socketReused = false;
    private _tlsDoesNotApply = false;

    public attach(request: TimedClientRequest, options: AgentRequestOptions | undefined): void {
        this._dnsDoesNotApply = options?.hostname ? isIP(options.hostname) !== 0 : false;
        this._tlsDoesNotApply = options?.protocol === 'http:';

        request.once('socket', (socket) => {
            this._socketAssignedAt = performance.now();
            this._socketReused = !socket.connecting;

            if (this._socketReused) {
                return;
            }

            socket.once('lookup', () => {
                this._dnsEndedAt = performance.now();
            });
            socket.once('connect', () => {
                this._connectedAt = performance.now();
            });
            socket.once('secureConnect', () => {
                this._secureConnectedAt = performance.now();
            });
        });
        request.once('finish', () => {
            this._requestFinishedAt = performance.now();
        });
        request.once('response', (response) => {
            this._responseStartedAt = performance.now();
            response.once('end', () => {
                this._responseEndedAt = performance.now();
            });
        });
    }

    public getHarTimings(): AxiosHarTimings {
        const socketAssignedAt = this._socketAssignedAt;
        if (socketAssignedAt === undefined) {
            return {};
        }

        const timings: AxiosHarTimings = {
            blocked: this.getDuration(this._startedAt, socketAssignedAt),
        };

        if (this._socketReused) {
            timings.connect = -1;
            timings.dns = -1;
            timings.ssl = -1;
        } else {
            if (this._dnsEndedAt !== undefined) {
                timings.dns = this.getDuration(socketAssignedAt, this._dnsEndedAt);
            } else if (this._dnsDoesNotApply) {
                timings.dns = -1;
            }

            if (this._connectedAt !== undefined) {
                timings.connect = this.getDuration(this._dnsEndedAt ?? socketAssignedAt, this._secureConnectedAt ?? this._connectedAt);
            }

            if (this._secureConnectedAt !== undefined && this._connectedAt !== undefined) {
                timings.ssl = this.getDuration(this._connectedAt, this._secureConnectedAt);
            } else if (this._tlsDoesNotApply) {
                timings.ssl = -1;
            }
        }

        const connectionReadyAt = this._secureConnectedAt ?? this._connectedAt ?? socketAssignedAt;
        if (this._requestFinishedAt !== undefined) {
            const requestFinishedAt = Math.max(connectionReadyAt, this._requestFinishedAt);
            timings.send = this.getDuration(connectionReadyAt, requestFinishedAt);

            if (this._responseStartedAt !== undefined) {
                timings.wait = this.getDuration(requestFinishedAt, this._responseStartedAt);
            }
        }

        if (this._responseStartedAt !== undefined && this._responseEndedAt !== undefined) {
            timings.receive = this.getDuration(this._responseStartedAt, this._responseEndedAt);
        }

        return timings;
    }

    private getDuration(startedAt: number, endedAt: number): number {
        return Math.max(0, endedAt - startedAt);
    }
}

function instrumentAxiosAgent(agent: unknown): void {
    if (!agent || typeof agent !== 'object' || instrumentedAxiosAgents.has(agent)) {
        return;
    }

    const instrumentedAgent = agent as InstrumentedAgent;
    const addRequest = instrumentedAgent.addRequest;
    if (!addRequest) {
        return;
    }

    instrumentedAgent.addRequest = (request, ...args) => {
        const timing = new AxiosRequestTiming();
        const timedRequest = request as TimedClientRequest;
        timedRequest[axiosHarTiming] = timing;
        timing.attach(timedRequest, args[0] as AgentRequestOptions | undefined);
        addRequest.call(agent, request, ...args);
    };
    instrumentedAxiosAgents.add(agent);
}

export function createAxios(axiosConfig?: CreateAxiosDefaults | undefined): AxiosInstance {
    const axios = baseAxios.create({
        httpAgent: http.globalAgent,
        timeout: 2500,
        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
        maxRedirects: 999,
        validateStatus: () => true,
        ...axiosConfig,
    });

    instrumentAxiosAgent(axios.defaults.httpAgent);
    instrumentAxiosAgent(axios.defaults.httpsAgent);

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
            const request = response.config as CustomAxiosRequestConfig;
            const startedDate = request.startedDate ?? null;
            const totalTime = startedDate ? endedDate.getTime() - startedDate!.getTime() : -1;

            response.headers['X-Test-Response-Date'] = endedDate.toISOString();
            response.headers['X-Test-Response-Duration'] = totalTime.toString();

            const httpVersion = getAxiosResponseHttpVersion(response);

            AxiosHarStore.shared.addEntry({
                request: {
                    body: getAxiosRequestRawText(request),
                    headers: getAxiosRequestHeaders(request),
                    httpVersion: httpVersion,
                    method: request.method ?? 'N/A',
                    url: request.url ?? 'N/A',
                    startDate: startedDate,
                },
                response: {
                    body: await getAxiosResponseRawText(response),
                    error: null,
                    headers: getAxiosResponseHeaders(response),
                    httpVersion: httpVersion,
                    status: response.status,
                    statusText: response.statusText,
                    endDate: endedDate,
                    timings: getAxiosResponseTimings(response),
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

                const httpVersion = getAxiosResponseHttpVersion(error);

                AxiosHarStore.shared.addEntry({
                    request: {
                        body: getAxiosRequestRawText(request),
                        headers: getAxiosRequestHeaders(request),
                        httpVersion: httpVersion,
                        method: request.method ?? 'N/A',
                        url: request.url ?? 'N/A',
                        startDate: startedDate,
                    },
                    response: {
                        body: await getAxiosResponseRawText(error),
                        error: null,
                        headers: getAxiosResponseHeaders(error),
                        httpVersion: httpVersion,
                        status: error.status ?? 0,
                        statusText: 'N/A',
                        endDate: endedDate,
                        timings: getAxiosResponseTimings(error),
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
 * Get the protocol version used by Axios's Node HTTP adapter
 */
export function getAxiosResponseHttpVersion(responseOrError: AxiosError | AxiosResponse): string {
    const response = isAxiosError(responseOrError) ? responseOrError.response : responseOrError;
    const request = response?.request as {
        res?: { httpVersion?: string | undefined } | undefined;
        session?: unknown;
    } | undefined;

    if (request?.res?.httpVersion) {
        return `HTTP/${request.res.httpVersion}`;
    }

    if (request?.session) {
        return 'HTTP/2.0';
    }

    return 'Unknown';
}

/**
 * Get HAR timing phases observed by the Node HTTP agent.
 */
export function getAxiosResponseTimings(responseOrError: AxiosError | AxiosResponse): AxiosHarTimings {
    const response = isAxiosError(responseOrError) ? responseOrError.response : responseOrError;
    const request = (response?.request ?? (isAxiosError(responseOrError) ? responseOrError.request : undefined)) as TimedClientRequest | undefined;
    const timing = request?.[axiosHarTiming] ?? request?._currentRequest?.[axiosHarTiming];

    return timing?.getHarTimings() ?? {};
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
