type ApiStatus = {
    status: 'on' | 'off';
};

const isDev = (import.meta as any).env?.PROD !== true;
const backendUrl = isDev ? 'http://localhost:8081/api/status' : `https://${window.location.host}/api/status`;

export async function getStatus(): Promise<boolean> {
    const response = await fetch(backendUrl);
    const data = await response.json() as ApiStatus;
    return data.status === 'on';
}

export async function changeStatus(status: boolean): Promise<boolean> {
    const requestData = {
        status: status ? 'on' : 'off',
    };
    const response = await fetch(backendUrl, {
        method: 'POST',
        body: JSON.stringify(requestData),
        headers: {
            'Content-Type': 'application/json',
        }
    });
    const data = await response.json() as ApiStatus;
    return data.status === 'on';
}
