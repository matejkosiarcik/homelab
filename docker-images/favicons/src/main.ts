import fs from 'node:fs';
import fsx from 'node:fs/promises';
import https from 'node:https';
import os from 'node:os';
import path from 'node:path';
import axios from 'axios';
import dotevn from 'dotenv';
import { execa } from 'execa';
import express, { type Request, type Response } from 'express';
import png2ico from 'png-to-ico';
import sharp from 'sharp';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const envMode = `${process.env['HOMELAB_ENV']}` as 'dev' | 'prod';
const appType = (() => {
    if (!process.env['HOMELAB_APP_TYPE']) {
        console.error('HOMELAB_APP_TYPE is unset');
        process.exit(1);
    }
    return process.env['HOMELAB_APP_TYPE'];
})();

const appAddress = (() => {
    switch (appType) {
        case 'actualbudget': return 'http://app:5006';
        case 'adventurelog': return 'http://app-frontend:3000';
        case 'certbot': return 'http://app:8080';
        case 'changedetection': return 'http://app:5000';
        case 'dawarich': return 'http://app:3000';
        case 'docker-cache': return ''; // http://app
        case 'docker-stats': return ''; // http://app:9487
        case 'donetick': return 'http://app:2021';
        case 'dozzle': return 'http://app:8080';
        case 'filebrowser': return 'http://app';
        case 'gatus': return 'http://app:8080';
        case 'git-cache': return ''; // http://app:8080
        // case 'glances': return 'http://app:61208';
        case 'gotify': return 'http://app:80';
        case 'grafana': return 'http://app:3000';
        case 'groceries': return 'http://app-frontend:8100';
        case 'healthchecks': return 'http://app:8000';
        case 'homeassistant': return 'http://app:8123';
        case 'homepage': return 'http://app:3000';
        case 'jellyfin': return 'http://app:8096';
        case 'kiwix': return 'http://app:8080';
        case 'koffan': return 'http://app:8080';
        case 'libretranslate': return 'http://app:5000';
        case 'minio': return 'http://app:9001';
        case 'motioneye': return 'http://app:8765';
        case 'nodeexporter': return ''; // http://app:9100
        case 'npm-cache': return ''; // http://app:8080
        case 'ntfy': return 'http://app:80';
        case 'ollama': return ''; // http://app:11434
        case 'omadacontroller': return envMode === 'prod' ? 'https://app' : 'https://app:8443';
        case 'openwebui': return 'http://app:8080';
        case 'openspeedtest': return 'http://app:3000';
        case 'pihole': return 'http://app:80';
        case 'planka': return 'http://app:1337';
        case 'prometheus': return 'http://app:9090';
        case 'renovatebot': return '' // http://app:8080
        case 'reportportal': return 'http://app-ui:8080';
        case 'samba': return '';
        case 'smtp4dev': return 'http://app:5000';
        case 'speedtesttracker': return 'https://app';
        case 'tvheadend': return 'http://app:9981';
        case 'unbound': return ''; // http://app:8080
        case 'unificontroller': return 'https://app:8443';
        case 'uptimekuma': return 'http://app:3001';
        case 'vaultwarden': return 'http://app:80';
        case 'vikunja': return 'http://app:3456';
        default: throw new Error(`Unknown app type ${appType}`);
    }
})();

function getFaviconPath(imageType: 'ico' | 'png'): string {
    switch (appType) {
        case 'actualbudget': return imageType === 'ico' ? '/favicon.ico' : '/apple-touch-icon.png';
        case 'adventurelog': return '/favicon.png'; // Checked
        case 'certbot': return `@/homelab/icons/${appType}.png`;
        case 'changedetection': return imageType === 'ico' ? '/static/favicons/favicon-32x32.png' : '/static/favicons/apple-touch-icon.png';
        case 'dawarich': return imageType === 'ico' ? '/assets/favicon/favicon.ico' : '/assets/favicon/apple-touch-icon.png';
        case 'docker-cache': return `@/homelab/icons/${appType}.png`;
        case 'docker-stats': return `@/homelab/icons/${appType}.png`;
        case 'donetick': return imageType === 'ico' ? '/favicon-32x32.png' : '/apple-touch-icon.png';
        case 'dozzle': return imageType === 'ico' ? '/favicon.ico' : '/favicon.png';
        case 'filebrowser': return '/static/img/icons/favicon.svg'; // Checked
        case 'gatus': return imageType === 'ico' ? '/favicon.ico' : '/apple-touch-icon.png';
        case 'git-cache': return `@/homelab/icons/${appType}.png`;
        // case 'glances': return '/static/favicon.ico';
        case 'gotify': return imageType === 'ico' ? '/static/favicon-32x32.png' : '/static/favicon-196x196.png';
        case 'grafana': return imageType === 'ico' ? '/public/img/fav32.png' : '/public/img/grafana_icon.svg';
        case 'groceries': return '/assets/icon/favicon.svg'; // Checked
        case 'healthchecks': return '/static/img/favicon.svg'; // Checked
        case 'homeassistant': return imageType === 'ico' ? '/static/icons/favicon.ico' : '/static/icons/favicon-192x192.png';
        case 'homepage': return imageType === 'ico' ? '/favicon-32x32.png' : '/apple-touch-icon.png';
        case 'jellyfin': return '/web/favicon.ico'; // Checked
        case 'kiwix': return imageType === 'ico' ? '/skin/favicon/favicon-32x32.png' : '/skin/favicon/apple-touch-icon.png';
        case 'koffan': return imageType === 'ico' ? '/favicon.ico' : '/static/icon-192.png';
        case 'libretranslate': return '/static/favicon.ico'; // Checked
        case 'minio': return imageType === 'ico' ? '/favicon.ico' : '/apple-icon-180x180.png';
        case 'motioneye': return '/static/img/motioneye-logo.svg'; // Checked
        case 'nodeexporter': return `@/homelab/icons/${appType}.png`;
        case 'npm-cache': return `@/homelab/icons/${appType}.png`;
        case 'ntfy': return imageType === 'ico' ? '/static/images/favicon.ico' : '/static/images/apple-touch-icon.png';
        case 'ollama': return `@/homelab/icons/${appType}.png`;
        case 'omadacontroller': return '/favicon.ico'; // Checked
        case 'openwebui': return imageType === 'ico' ? '/static/favicon.ico' : '/static/favicon.svg';
        case 'openspeedtest': return imageType === 'ico' ? '/assets/images/icons/favicon-32x32.png' : '/assets/images/icons/apple-touch-icon.png';
        case 'pihole': return imageType === 'ico' ? '/admin/img/favicons/favicon-32x32.png' : '/admin/img/favicons/apple-touch-icon.png';
        case 'planka': return imageType === 'ico' ? '/favicon.ico' : '/logo192.png';
        case 'prometheus': return '/favicon.svg'; // Checked
        case 'renovatebot': return `@/homelab/icons/${appType}.png`;
        case 'reportportal': return '/ui/favicon.ico'; // Checked
        case 'samba': return `@/homelab/icons/${appType}.png`;
        case 'smtp4dev': return imageType === 'ico' ? '/favicon.ico' : '/favicon.png';
        case 'speedtesttracker': return imageType === 'ico' ? '/favicon.ico' : '/img/speedtest-tracker-icon.png';
        case 'tvheadend': return imageType === 'ico' ? '/favicon.ico' : '/static/img/logo.png';
        case 'unbound': return `@/homelab/icons/${appType}.png`;
        case 'unificontroller': return imageType === 'ico' ? '/manage/angular/favicon.ico' : '/manage/angular/favicon-192.png';
        case 'uptimekuma': return imageType === 'ico' ? '/favicon.ico' : '/icon.svg';
        case 'vaultwarden': return imageType === 'ico' ? '/images/favicon-32x32.png' : '/images/apple-touch-icon.png';
        case 'vikunja': return imageType === 'ico' ? '/favicon.ico' : '/images/icons/apple-touch-icon-180x180.png';
        default: throw new Error(`Unknown app type: ${appType}`);
    }
}

const fileCache: Record<string, Buffer> = {};

/**
 * Converts PNG to PNG
 * Usually just passes the PNG as is
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
 * Usually just passes the PNG as is
 * But if the source is too big, it downsizes it to 64x64 px
 */
async function convertIcoToPng(icoImage: Buffer): Promise<Buffer> {
    const tmpDir = await fsx.mkdtemp(path.join(os.tmpdir(), 'favicons-'));
    try {
        const tmpIco = path.join(tmpDir, 'favicon.ico');
        await fsx.writeFile(tmpIco, icoImage);

        await execa('convert', [tmpIco, path.join(tmpDir, 'favicon.png')]);

        // Find the biggest PNG
        const files = await fsx.readdir(tmpDir, { withFileTypes: true, recursive: false });
        const convertedPngs = files.filter(el => el.isFile() && el.name.endsWith('.png'));
        let maxSize = 0;
        let biggestPngFile = '';
        for (const file of convertedPngs) {
            const buffer = await fsx.readFile(path.join(tmpDir, file.name));
            const meta = await sharp(buffer).metadata();
            if (meta.width * meta.height > maxSize) {
                maxSize = meta.width * meta.height;
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
    const sizes = [32, 16];
    const pngs: Buffer[] = [];
    const image = sharp(pngImage);
    const metadata = await image.metadata();
    for (const size of sizes) {
        if (metadata.width < size || metadata.height < size) { continue; }
        pngs.push(await image.resize(size, size, { fit: 'inside' }).png().toBuffer());
    }

    if (pngs.length === 0) {
        // Fallback in case the source PNG is too small for predefined sizes
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

app.get('/favicon.ico', async (_: Request, response: Response) => {
    try {
        const faviconPath = getFaviconPath('ico');
        const originalFavicon = await loadFavicon(faviconPath);
        const outputFavicon = await convertImage(originalFavicon, path.extname(faviconPath).slice(1) as 'ico' | 'png' | 'svg', 'ico');
        response.status(200);
        response.setHeader('Content-Type', 'image/x-icon');
        response.send(outputFavicon);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

app.get('/favicon.png', async (_: Request, response: Response) => {
    try {
        const faviconPath = getFaviconPath('png');
        const originalFavicon = await loadFavicon(faviconPath);
        const outputFavicon = await convertImage(originalFavicon, path.extname(faviconPath).slice(1) as 'ico' | 'png' | 'svg', 'png');
        response.status(200);
        response.setHeader('Content-Type', 'image/png');
        response.send(outputFavicon);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

async function loadFavicon(iconPath: string): Promise<Buffer> {
    if (iconPath.startsWith('@')) {
        return await fsx.readFile(iconPath.replace(/^@/, ''));
    }

    const headers: Record<string, string> = {};
    switch (appType) {
        case 'homepage':
        case 'prometheus':
        case 'smtp4dev': {
            headers['Authorization'] = `Basic ${Buffer.from(`homelab-viewer:${process.env['FAVICON_PASSWORD']}`).toString('base64')}`;
            break;
        }
        default: {
            break;
        }
    }
    const axiosResponse = await axios.get(`${appAddress}${iconPath}`, {
        headers: headers,
        maxRedirects: 99,
        responseType: 'arraybuffer',
        timeout: 1000,
        validateStatus: () => true,
        httpsAgent: new https.Agent({
            rejectUnauthorized: false
        }),
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

process.on('SIGTERM', () => {
    process.exit(0);
});
