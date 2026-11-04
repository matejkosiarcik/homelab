import { URL } from 'node:url';
import { formatISO, parseISO } from 'date-fns';
import { Entry as HarEntry } from 'har-format';

export type AxiosHarTimings = {
    blocked?: number;
    connect?: number;
    dns?: number;
    receive?: number;
    send?: number;
    ssl?: number;
    wait?: number;
};

type AxiosHarStoreEntry = {
    request: {
        body: string;
        headers: Record<string, MaybeArray<string>>;
        httpVersion: string;
        method: string;
        url: string;
        startDate: Date | null,
    };
    response: {
        body: string;
        error: string | null;
        headers: Record<string, MaybeArray<string>>;
        httpVersion: string;
        status: number;
        statusText: string;
        endDate: Date | null;
        timings: AxiosHarTimings;
    };
};

/**
 * Store axios requests/responses and output HAR files for usage in test reports
 */
export class AxiosHarStore {
    private static _shared: AxiosHarStore | undefined;
    private readonly _entries: HarEntry[] = [];

    public constructor() {}

    public static get shared(): AxiosHarStore {
        if (!this._shared) {
            this._shared = new AxiosHarStore();
        }
        return this._shared;
    }

    public get entries(): HarEntry[] {
        return this._entries;
    }

    public clear(): void {
        this._entries.splice(0);
    }

    public addEntry(entry: AxiosHarStoreEntry): void {
        this._entries.push({
            cache: {},
            pageref: '',
            request: {
                bodySize: entry.request.body.length,
                cookies: (() => {
                    const cookies = Object.entries(entry.request.headers).find(([key]) => key === 'cookie')!;
                    if (!cookies) {
                        return [];
                    }
                    return [cookies[1]].flat().map((value) => ({
                        name: value.split('=')[0],
                        value: value.split('=')[1],
                    }));
                })(),
                headers:
                    Object.entries(entry.request.headers)
                        .map(([key, value]) => {
                            return [value].flat().map((value) => ({ name: key, value: value }));
                        })
                        .flat(),
                headersSize: -1,
                httpVersion: entry.request.httpVersion,
                method: entry.request.method.toUpperCase(),
                postData:
                    entry.request.body ?
                        {
                            mimeType: entry.request.headers['content-type'] ? [entry.request.headers['content-type']].flat()[0].split(';')[0] : 'x-unknown',
                            params: undefined,
                            text: entry.request.body,
                        }
                    : undefined,
                queryString:
                    Array.from(URL.parse(entry.request.url)?.searchParams.entries() ?? []).map(([key, value]) => ({
                        name: key,
                        value: value,
                    })),
                url: entry.request.url,
            },
            response: {
                _transferSize: -1,
                bodySize: entry.response.body.length,
                comment: entry.response.error || undefined,
                content: {
                    compression: 0,
                    mimeType: entry.response.headers['content-type'] ? [entry.response.headers['content-type']].flat()[0].split(';')[0] : 'x-unknown',
                    size: entry.response.body.length,
                    text: entry.response.body,
                },
                cookies: (() => {
                    const cookies = Object.entries(entry.response.headers).find(([key]) => key === 'set-cookie')!;
                    if (!cookies) {
                        return [];
                    }

                    return [cookies[1]].flat().map((value) => ({
                        expires: formatISO(
                            new Date(
                                value
                                    .split(';')
                                    .map((el) => el.trim())
                                    .filter((el) => /^Expires=/.test(el))
                                    .map((el) => el.replace(/^Expires=/, ''))[0] || parseISO('1970-01-01T00:00:00.000Z'),
                            ),
                        ),
                        httpOnly: value
                            .split(';')
                            .map((el) => el.trim())
                            .includes('HttpOnly'),
                        name: value.split(';')[0].split('=')[0],
                        path:
                            value
                                .split(';')
                                .map((el) => el.trim())
                                .filter((el) => /^Path=/.test(el))
                                .map((el) => el.replace(/^Path=/, ''))[0] || 'N/A',
                        sameSite:
                            value
                                .split(';')
                                .map((el) => el.trim())
                                .filter((el) => /^SameSite=/.test(el))
                                .map((el) => el.replace(/^SameSite=/, ''))[0] || 'None',
                        secure: value
                            .split(';')
                            .map((el) => el.trim())
                            .includes('Secure'),
                        value: value.split(';')[0].split('=')[1],
                    }));
                })(),
                headers:
                    Object.entries(entry.response.headers)
                        .map(([key, value]) => {
                            return [value].flat().map((value) => ({ name: key, value: value }));
                        })
                        .flat(),
                headersSize: -1,
                httpVersion: entry.response.httpVersion,
                redirectURL: '',
                status: entry.response.status,
                statusText: entry.response.statusText,
            },
            startedDateTime: entry.request.startDate ? formatISO(entry.request.startDate) : 'N/A',
            time: (entry.request.startDate && entry.response.endDate) ? (entry.response.endDate.getTime() - entry.request.startDate.getTime()) : -1,
            timings: {
                blocked: entry.response.timings.blocked ?? -1,
                connect: entry.response.timings.connect ?? -1,
                dns: entry.response.timings.dns ?? -1,
                receive: entry.response.timings.receive ?? -1,
                send: entry.response.timings.send ?? -1,
                ssl: entry.response.timings.ssl ?? -1,
                wait: entry.response.timings.wait ?? -1,
            },
        });
    }

    public getOutput(): string {
        const output = {
            log: {
                creator: {
                    name: 'Homelab Tests',
                    version: '0.0.0',
                },
                entries: this._entries,
                pages: [],
                version: '1.2',
            },
        };
        return JSON.stringify(output);
    }
}
