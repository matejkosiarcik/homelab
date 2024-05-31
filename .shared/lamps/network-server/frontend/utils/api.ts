type ApiStatus = {
    status: 'on' | 'off';
};

export async function getStatus(): Promise<boolean> {
    const response = await fetch('http://localhost:8080/api/status');
    const data = await response.json() as ApiStatus;
    return data.status === 'on';
}

export async function changeStatus(status: boolean): Promise<boolean> {
    const requestData = {
        status: status ? 'on' : 'off',
    };
    const response = await fetch('http://localhost:8080/api/status', {
        method: 'POST',
        body: JSON.stringify(requestData),
        headers: {
            'Content-Type': 'application/json',
        }
    });
    const data = await response.json() as ApiStatus;
    return data.status === 'on';
}
