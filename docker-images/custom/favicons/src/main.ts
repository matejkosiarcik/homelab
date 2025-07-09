import fs from 'node:fs';
import fsx from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import express, { Request, Response } from 'express';
import axios from 'axios';
import dotevn from 'dotenv';
import sharp from 'sharp';
import { execa } from 'execa';
import png2ico from 'png-to-ico';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const appType = (() => {
    if (!process.env['HOMELAB_APP_TYPE']) {
        console.error('HOMELAB_APP_TYPE is unset');
        process.exit(1);
    }
    return process.env['HOMELAB_APP_TYPE'];
})();

const appAddress = (() => {
    switch (appType) {
        case 'actualbudget': return 'http://app:5000';
        case 'certbot': return 'http://app:8080';
        case 'changedetection': return 'http://app:5000';
        case 'docker-cache-proxy': return 'http://app:5000';
        case 'gatus': return 'http://app:8080';
        case 'glances': return 'http://app:61208';
        case 'gotify': return 'http://app:80';
        case 'homepage': return 'http://app:3000';
        case 'jellyfin': return 'http://app:8096';
        case 'minio': return 'http://app:9001';
        case 'motioneye': return 'http://app:8765';
        case 'ntfy': return 'http://app:80';
        case 'ollama': return 'http://app:11434';
        case 'omada-controller': return 'http://app:8043';
        case 'open-webui': return 'http://app:8080';
        case 'openspeedtest': return 'http://app:3000';
        case 'pihole': return 'http://app:80';
        case 'prometheus': return 'http://app:9090';
        case 'smtp4dev': return 'http://app:80';
        case 'tvheadend': return 'http://app:9981';
        case 'unbound': return 'http://app:8080';
        case 'unifi-controller': return 'http://app:8443';
        case 'uptime-kuma': return 'http://app:3001';
        case 'vaultwarden': return 'http://app:80';
        default: throw new Error(`Unknown app type ${appType}`);
    }
})();

function getFaviconPath(type: 'ico' | 'png'): string {
    switch (appType) {
        case 'actualbudget':
        case 'changedetection':
        case 'homepage':
        case 'minio':
        case 'ollama':
        case 'omada-controller':
        case 'open-webui':
        case 'uptime-kuma':
            return type === 'ico' ? '/favicon.ico' : '/favicon-32x32.png';
        case 'certbot':
        case 'docker-cache-proxy':
        case 'motioneye':
        case 'prometheus':
        case 'gatus':
            return '/apple-touch-icon.png';
        case 'unbound':
            return type === 'ico' ? `@/homelab/icons/${appType}/favicon.ico` : `@/homelab/icons/${appType}/favicon.png`;
        case 'glances':
            return type === 'ico' ? '/static/favicon.ico' : (() => { /* TODO: Check glances favicon.png */ throw new Error('PLACEHOLDER') })();
        case 'gotify':
            return type === 'ico' ? (() => { /* TODO: Check gotify favicon.ico */ throw new Error('PLACEHOLDER') })() : '/static/favicon-32x32.png';
        case 'jellyfin':
            return type === 'ico' ? '/web/favicon.ico' : '/web/favicon.png';
        case 'ntfy':
            return type === 'ico' ? '/favicon.ico' : '/static/images/apple-touch-icon.png';
        case 'openspeedtest':
            return type === 'ico' ? '/favicon.ico' : '/assets/images/icons/favicon-32x32.png';
        case 'pihole':
            return type === 'ico' ? '/favicon.ico' : '/admin/img/favicons/favicon-32x32.png';
        case 'smtp4dev':
            return type === 'ico' ? '/favicon.ico' : '/logo.png';
        case 'tvheadend':
            return type === 'ico' ? '/favicon.ico' : '/static/img/logo.png';
        case 'unifi-controller':
            return type === 'ico' ? '/favicon.ico' : '/.proxy/icons/unifi-controller/favicon.png';
        case 'vaultwarden':
            return type === 'ico' ? '/favicon.ico' : '/images/favicon-32x32.png';
        default:
            throw new Error(`Unknown app type: ${appType}`);
    }
}

const fileCache: Record<string, Buffer> = {};

/**
 * Converts PNG to PNG
 * Usualy just passes the PNG as is
 * But if the source is too big, it downsizes it to 64x64 px
 */
async function convertPngToPng(pngImage: Buffer): Promise<Buffer> {
    const image = sharp(pngImage);
    const metadata = await image.metadata();
    let outputPng: Buffer;
    if (metadata.width > 64 || metadata.height > 64) {
        outputPng = await image.resize(64, 64, { fit: 'inside' }).png().toBuffer();
    } else {
        outputPng = pngImage;
    }

    return outputPng;
}

/**
 * Converts ICO to PNG
 * Usualy just passes the PNG as is
 * But if the source is too big, it downsizes it to 64x64 px
 */
async function convertIcoToPng(icoImage: Buffer): Promise<Buffer> {
    const tmpDir = await fsx.mkdtemp(path.join(os.tmpdir(), 'favicons-'));
    try {
        const tmpIco = path.join(tmpDir, 'favicon.ico');
        await fsx.writeFile(tmpIco, icoImage);

        await execa('convert', [tmpIco, path.join(tmpDir, 'favicon-%wx%h.png')]);

        // Find the biggest PNG
        const files = await fsx.readdir(tmpDir, { withFileTypes: true });
        const convertedPngs = files.filter(el => el.isFile() && el.name.startsWith('favicon-') && el.name.endsWith('.png'));
        let maxSize = 0;
        let biggestPngFile = '';
        for (const file of convertedPngs) {
            const match = file.name.match(/^favicon\-(\d+)x(\d+)\.png$/);
            if (!match) {
                continue;
            }
            const size = parseInt(match[1]) * parseInt(match[2]);
            if (size > maxSize) {
                maxSize = size;
                biggestPngFile = file.name;
            }
        }

        if (!biggestPngFile) {
            throw new Error('No PNG extracted from ICO');
        }

        let biggestPng = await fsx.readFile(path.join(tmpDir, biggestPngFile));
        return await convertPngToPng(biggestPng);
    } finally {
        await fsx.rm(tmpDir, { recursive: true, force: true });
    }
}

async function convertPngToIco(pngImage: Buffer): Promise<Buffer> {
    // Convert PNG to predefined sizes
    const sizes = [48, 16];
    const pngs: Buffer[] = [];
    const image = sharp(pngImage);
    const metadata = await image.metadata();
    for (const size of sizes) {
        if (metadata.width < size || metadata.height < size) { continue; }
        pngs.push(await image.resize(size, size, { fit: 'inside' }).png().toBuffer());
    }

    if (pngs.length === 0) {
        // Falback in case the source PNG is too small for predefined sizes
        pngs.push(pngImage);
    }

    return await png2ico(pngs);
}

async function convertSvgToPng(svgImage: Buffer): Promise<Buffer> {
    return await sharp(svgImage).resize(64, 64).png().toBuffer();
}

async function convertSvgToIco(svgImage: Buffer): Promise<Buffer> {
    const png = await convertSvgToPng(svgImage);
    const output = await convertPngToIco(png);
    return output;
}

async function convertImage(source: Buffer, sourceType: 'ico' | 'png' | 'svg', targetType: 'ico' | 'png'): Promise<Buffer> {
    if (Object.keys(fileCache).includes(targetType)) {
        return fileCache[targetType];
    }

    const output = await (async () => {
        switch (sourceType) {
            case 'ico':
                return targetType === 'png' ? await convertIcoToPng(source) : source;
            case 'png':
                return targetType === 'png' ? await convertPngToPng(source) : await convertPngToIco(source);
            case 'svg':
                return targetType === 'png' ? await convertSvgToPng(source) : await convertSvgToIco(source);
            default:
                throw new Error(`Unknown source image type: ${sourceType}`);
        }
    })();

    fileCache[targetType] = output;
    return output;
}

const app = express();

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

app.get('/favicon-new.ico', async (_: Request, response: Response) => {
    try {
        const faviconPath = getFaviconPath('ico');
        const originalFavicon = await downloadFavicon(faviconPath);
        const outputFavicon = await convertImage(originalFavicon, path.extname(faviconPath).slice(1) as 'ico' | 'png' | 'svg', 'ico');
        response.status(200);
        response.setHeader('Content-Type', 'image/x-icon');
        response.send(outputFavicon);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

app.get('/favicon-new.png', async (_: Request, response: Response) => {
    try {
        const faviconPath = getFaviconPath('png');
        const originalFavicon = await downloadFavicon(faviconPath);
        const outputFavicon = await convertImage(originalFavicon, path.extname(faviconPath).slice(1) as 'ico' | 'png' | 'svg', 'png');
        response.status(200);
        response.setHeader('Content-Type', 'image/png');
        response.send(outputFavicon);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

async function downloadFavicon(path: string): Promise<Buffer> {
    const headers: Record<string, string> = {};
    switch (appType) {
        case 'homepage':
        case 'smtp4dev': {
            headers['Authorization'] = `Basic ${Buffer.from(`admin:${process.env['ADMIN_PASSWORD']}`).toString('base64')}`;
            break;
        }
        default: {
            break;
        }
    }
    const axiosResponse = await axios.get(`${appAddress}${path}`, {
        headers: headers,
        maxRedirects: 99,
        responseType: 'arraybuffer',
        timeout: 1000,
        validateStatus: () => true,
    });

    if (axiosResponse.status === 0) {
        throw new Error('Upstream error, no response.');
    }
    if (axiosResponse.status !== 200) {
        throw new Error(`Upstream error ${axiosResponse.status}.`);
    }

    return Buffer.from(axiosResponse.data);
}

app.listen(8080, () => {
    console.log('Server started.');
});
