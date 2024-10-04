import { Notyf } from 'notyf';

const notyf = new Notyf();

async function copyUrl(url: string) {
    try {
        await navigator.clipboard.writeText(url);
        notyf.success({ message: 'URL copied', position: { x: 'right', y: 'top' } });
    } catch (error) {
        console.error(error);
        notyf.error({ message: `Could not copy URL ${url}`, position: { x: 'right', y: 'top' } });
    }
}

(window as any).copyUrl = copyUrl;
