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
        case 'docker-cache': return ''; // http://app:80
        case 'docker-stats': return ''; // http://app:9487
        case 'donetick': return 'http://app:2021';
        case 'dozzle': return 'http://app:8080';
        case 'gatus': return 'http://app:8080';
        case 'git-cache': return ''; // http://app:8080
        // case 'glances': return 'http://app:61208';
        case 'gotify': return 'http://app:80';
        case 'grafana': return 'http://app:3000';
        // case 'groceries': return 'http://app-frontend:8100';
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
        case 'novnc': return 'http://app:6080';
        case 'ollama': return ''; // http://app:11434
        case 'omadacontroller': return envMode === 'prod' ? 'https://app:80' : 'https://app:8443';
        case 'openwebui': return 'http://app:8080';
        case 'openspeedtest': return 'http://app:3000';
        case 'pihole': return 'http://app:80';
        case 'pihole-blackhole': return 'http://app:80';
        case 'planka': return 'http://app:1337';
        case 'prometheus': return 'http://app:9090';
        case 'renovatebot': return '' // http://app:8080
        case 'reportportal': return 'http://app-ui:8080';
        case 'samba': return '';
        case 'smtp4dev': return 'http://app:5000';
        case 'speedtesttracker': return 'https://app:80';
        case 'tvheadend': return 'http://app:9981';
        case 'unbound': return ''; // http://app:8080
        case 'unificontroller': return 'https://app:8443';
        case 'uptimekuma': return 'http://app:3001';
        case 'vaultwarden': return 'http://app:80';
        case 'vikunja': return 'http://app:3456';
        default: throw new Error(`Unknown app type ${appType}`);
    }
})();

function getFaviconPath(): string {
    switch (appType) {
        case 'actualbudget': return '/apple-touch-icon.png'; // ICO - '/favicon.ico'
        case 'adventurelog': return '/favicon.png'; // Checked
        case 'certbot': return `@/homelab/icons/${appType}.png`;
        case 'changedetection': return '/static/favicons/apple-touch-icon.png'; // ICO - '/static/favicons/favicon-32x32.png'
        case 'dawarich': return '/assets/favicon/apple-touch-icon.png'; // ICO - '/assets/favicon/favicon.ico'
        case 'docker-cache': return `@/homelab/icons/${appType}.png`;
        case 'docker-stats': return `@/homelab/icons/${appType}.png`;
        case 'donetick': return '/apple-touch-icon.png'; // ICO - '/favicon-32x32.png'
        case 'dozzle': return '/favicon.png'; // ICO - '/favicon.ico'
        case 'gatus': return '/apple-touch-icon.png'; // ICO - '/favicon.ico'
        case 'git-cache': return `@/homelab/icons/${appType}.png`;
        // case 'glances': return '/static/favicon.ico';
        case 'gotify': return '/static/favicon-196x196.png'; // ICO - '/static/favicon-32x32.png'
        case 'grafana': return '/public/img/grafana_icon.svg'; // ICO - '/public/img/fav32.png'
        // case 'groceries': return '/assets/icon/favicon.svg'; // Checked
        case 'healthchecks': return '/static/img/favicon.svg'; // Checked
        case 'homeassistant': return '/static/icons/favicon-192x192.png'; // ICO - '/static/icons/favicon.ico'
        case 'homepage': return '/apple-touch-icon.png'; // ICO - '/favicon-32x32.png'
        case 'jellyfin': return '/web/favicon.ico'; // Checked
        case 'kiwix': return '/skin/favicon/apple-touch-icon.png'; // ICO - '/skin/favicon/favicon-32x32.png'
        case 'koffan': return '/static/icon-192.png'; // ICO - '/favicon.ico'
        case 'libretranslate': return '/static/favicon.ico'; // Checked
        case 'minio': return '/apple-icon-180x180.png'; // ICO - '/favicon.ico'
        case 'motioneye': return '/static/img/motioneye-logo.svg'; // Checked
        case 'nodeexporter': return `@/homelab/icons/${appType}.png`;
        case 'novnc': return '/app/images/icons/novnc-ios-180.png'; // ICO - '/app/images/icons/novnc.ico'
        case 'npm-cache': return `@/homelab/icons/${appType}.png`;
        case 'ntfy': return '/static/images/apple-touch-icon.png'; // ICO - '/static/images/favicon.ico'
        case 'ollama': return `@/homelab/icons/${appType}.png`;
        case 'omadacontroller': return '/favicon.ico'; // Checked
        case 'openwebui': return '/static/favicon.svg'; // ICO -  '/static/favicon.ico'
        case 'openspeedtest': return '/assets/images/icons/apple-touch-icon.png'; // ICO - '/assets/images/icons/favicon-32x32.png'
        case 'pihole': return '/admin/img/favicons/apple-touch-icon.png'; // ICO - '/admin/img/favicons/favicon-32x32.png'
        case 'planka': return '/logo192.png'; // ICO - '/favicon.ico'
        case 'prometheus': return '/favicon.svg'; // Checked
        case 'renovatebot': return `@/homelab/icons/${appType}.png`;
        case 'reportportal': return '/ui/favicon.ico'; // Checked
        case 'samba': return `@/homelab/icons/${appType}.png`;
        case 'smtp4dev': return '/favicon.png'; // ICO - '/favicon.ico'
        case 'speedtesttracker': return '/img/speedtest-tracker-icon.png'; // ICO - '/favicon.ico'
        case 'tvheadend': return '/static/img/logo.png'; // ICO - '/favicon.ico'
        case 'unbound': return `@/homelab/icons/${appType}.png`;
        case 'unificontroller': return '/manage/angular/favicon-192.png'; // ICO - '/manage/angular/favicon.ico'
        case 'uptimekuma': return '/icon.svg'; // ICO - '/favicon.ico'
        case 'vaultwarden': return '/images/apple-touch-icon.png'; // ICO - '/images/favicon-32x32.png'
        case 'vikunja': return '/images/icons/apple-touch-icon-180x180.png'; // ICO - '/favicon.ico'
        default: throw new Error(`Unknown app type: ${appType}`);
    }
}

const fileCache: Record<string, Buffer> = {};

/**
 * Extract largest Image component from an ICO image
 * The output is usually a PNG, but can be other formats, depending what was inside the ICO
 */
async function extractLargestPngFromIco(icoImage: Buffer): Promise<Buffer> {
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

        const image = sharp(biggestPng);
        return image.png().toBuffer();
    } finally {
        await fsx.rm(tmpDir, { recursive: true, force: true });
    }
}

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
    const pngBuffer = await extractLargestPngFromIco(icoImage);
    return await convertPngToPng(pngBuffer);
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

async function convertIcoToIco(icoImage: Buffer): Promise<Buffer> {
    const pngBuffer = await extractLargestPngFromIco(icoImage);
    return convertPngToIco(pngBuffer);
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
                return targetType === 'png' ? await convertIcoToPng(source) : await convertIcoToIco(source);
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
        const faviconPath = getFaviconPath();
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
        const faviconPath = getFaviconPath();
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
