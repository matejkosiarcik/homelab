import { Notyf } from 'notyf';

const notyf = new Notyf();

async function copyText(text: string) {
    try {
        await navigator.clipboard.writeText(text);
        notyf.success({ message: 'Copied to clipboard', position: { x: 'right', y: 'top' } });
    } catch (error) {
        console.error(error);
        notyf.error({ message: `Could not copy ${text}`, position: { x: 'right', y: 'top' } });
    }
}

const copyTargets = new Map([
    ['Odroid H3', 'ssh homelab@server-odroid-h3.matejhome.com'],
    ['Odroid H4 Ultra', 'ssh homelab@server-odroid-h4-ultra.matejhome.com'],
    ['Raspberry Pi 4B 2G', 'ssh homelab@server-raspberry-pi-4b-2g.matejhome.com'],
    ['Raspberry Pi 4B 4G', 'ssh homelab@server-raspberry-pi-4b-4g.matejhome.com'],
    ['SMB (data)', 'smb://samba-data.matejhome.com'],
]);

document.addEventListener('click', (event) => {
    if (!(event.target instanceof Element)) {
        // No action
        return;
    }

    const linkElement = event.target.closest<HTMLAnchorElement>('a[href^="#copy-"]');
    if (!linkElement) {
        // No action
        return;
    }

    const serviceName = linkElement.closest<HTMLElement>('.service')?.dataset.name;
    const copyTargetAddress = copyTargets.get(serviceName ?? '');
    if (!copyTargetAddress) {
        // No action
        return;
    }

    event.preventDefault();
    void copyText(copyTargetAddress);
});
