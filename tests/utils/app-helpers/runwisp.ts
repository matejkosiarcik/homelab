import { pbkdf2 } from 'node:crypto';
import { promisify } from 'node:util';
import { expect } from '#/playwright/test.ts';
import { axios } from '#/utils/utils.ts';

export interface RunWispSession {
    readonly readOnly: boolean;
    readonly token: string;
}

export async function createRunWispSession(url: string, password: string): Promise<RunWispSession> {
    const pbkdf2Async = promisify(pbkdf2);

    const challenge = await axios.get<{ nonce: string }>(`${url}/api/auth/challenge`);
    expect(challenge.status, 'Challenge response status').toStrictEqual(200);
    expect(challenge.data.nonce, 'Challenge nonce').toBeTruthy();

    const response = (await pbkdf2Async(password, challenge.data.nonce, 600_000, 32, 'sha256')).toString('hex');
    const login = await axios.post<RunWispSession>(`${url}/api/auth/login`, {
        nonce: challenge.data.nonce,
        response: response,
    });
    expect(login.status, 'Login response status').toStrictEqual(200);
    expect(login.data.token, 'Session token').toBeTruthy();

    return login.data;
}
