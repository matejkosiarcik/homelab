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

document.addEventListener('click', (event) => {
    if (!(event.target instanceof Element)) {
        // No custom action
        return;
    }

    const linkElement = event.target.closest<HTMLAnchorElement>('a[href^="#copy://"]');
    if (!linkElement) {
        // No custom action
        return;
    }

    const targetAddress = linkElement.getAttribute('href')?.replace('#copy://', '');
    if (!targetAddress) {
        // No custom action
        return;
    }

    // Copy target to clipboard
    event.preventDefault();
    void copyText(targetAddress);
});
