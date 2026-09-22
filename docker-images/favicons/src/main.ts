import crypto from 'node:crypto';
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

type EnvMode = 'dev' | 'prod';

const envMode = (() => {
    if (!process.env['HOMELAB_ENV']) {
        console.error('HOMELAB_ENV is unset');
        process.exit(1);
    }
    return process.env['HOMELAB_ENV'] as EnvMode;
})();

const appType = (() => {
    if (!process.env['HOMELAB_APP_TYPE']) {
        console.error('HOMELAB_APP_TYPE is unset');
        process.exit(1);
    }
    return process.env['HOMELAB_APP_TYPE'];
})();

type UrlsConfig = {
    apps: {
        type: string,
        favicons: {
            default?: string;
        },
        urls: {
            env?: 'dev' | 'prod',
            path: string,
            target: string,
        }[],
    }[],
}

const urlsConfig = JSON.parse(fs.readFileSync('urls.json', 'utf8')) as UrlsConfig;
const fileCache = new Map<string, Buffer>();

function upstreamUrl(imagePath: string): string {
    const app = urlsConfig.apps.find((app) => app.type == appType)!;
    const faviconPath = app.favicons.default || imagePath;

    if (faviconPath.startsWith('@')) {
        return faviconPath;
    }

    const upstreamUrl =
        app?.urls
        .filter((el) => (el.env || undefined) === undefined || el.env == envMode) // Filter URLs for current ENV mode
        .filter((el) => el.path === faviconPath || (el.path.endsWith('/') && faviconPath.startsWith(el.path))) // Filter upstream based on the path
        .toSorted()
        .at(-1)!;
    if (!upstreamUrl) {
        throw new Error(`Unknown target for path ${imagePath}`);
    }

    const resolvedPath = faviconPath.replace(upstreamUrl.path, URL.parse(upstreamUrl.target)!.pathname);
    const url = upstreamUrl.target + resolvedPath;
    console.log(`Resolved favicon URL: ${url} for original path: ${imagePath}`);
    return url;
}

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
        outputPng = await image.png().toBuffer();
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

function hashImage(image: Buffer): string {
    return crypto.createHash('sha256').update(image).digest('hex').slice(-10);
}

async function convertImage(upstreamImage: Buffer, sourceImageType: 'ico' | 'png' | 'svg', targetImageType: 'ico' | 'png'): Promise<Buffer> {
    const upstreamImageHash = hashImage(upstreamImage);
    const imageKey = `${sourceImageType}-${upstreamImageHash}-${targetImageType}`;

    const cachedImage = fileCache.get(imageKey);
    if (cachedImage) {
        console.log(`Serving cached image: ${imageKey}`);
        return cachedImage;
    }

    const output = await (async () => {
        switch (sourceImageType) {
            case 'ico':
                return targetImageType === 'png' ? await convertIcoToPng(upstreamImage) : await convertIcoToIco(upstreamImage);
            case 'png':
                return targetImageType === 'png' ? await convertPngToPng(upstreamImage) : await convertPngToIco(upstreamImage);
            case 'svg':
                return targetImageType === 'png' ? await convertSvgToPng(upstreamImage) : await convertSvgToIco(upstreamImage);
            default:
                throw new Error(`Unknown source image type: ${sourceImageType}`);
        }
    })();

    console.log(`Saving converted image: ${imageKey}`);
    fileCache.set(imageKey, output);
    return output;
}

async function requestImage(imageUrl: string): Promise<Buffer> {
    if (imageUrl.startsWith('@')) {
        return await fsx.readFile(imageUrl.replace(/^@/, ''));
    }

    const imagePath = URL.parse(imageUrl)!.pathname;
    const imageMime = `image/${path.extname(imagePath).slice(1)}`; // TODO: Make this generic with a mime library

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

    const axiosResponse = await axios.get(imageUrl, {
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
        throw new Error(`Upstream unavailable: ${axiosResponse}`);
    }
    if (axiosResponse.status !== 200) {
        throw new Error(`Upstream returned status ${axiosResponse.status} for ${imageUrl}`);
    }
    const contentType = axiosResponse.headers['Content-Type'] || axiosResponse.headers['content-type'];
    if (contentType !== imageMime) {
        throw new Error(`Upstream returned mismatched image type ${contentType} for ${imageUrl}, expected ${imageMime}`);
    }

    return Buffer.from(axiosResponse.data);
}

async function getFavicon(imagePath: string): Promise<Buffer> {
    const outputImageType = path.extname(imagePath).slice(1) as 'ico' | 'png';

    switch (outputImageType) {
        case 'ico':
        case 'png':
            break;
        default:
            throw new Error(`Unknown image type ${imagePath}`);
    }

    const upstreamImageUrl = upstreamUrl(imagePath);
    const upstreamImage = await requestImage(upstreamImageUrl);
    const outputImage = await convertImage(upstreamImage, path.extname(URL.parse(upstreamImageUrl)!.pathname).slice(1) as 'ico' | 'png' | 'svg', outputImageType);
    return outputImage;
}

const app = express();

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

app.get('/favicon.ico', async (request: Request, response: Response) => {
    try {
        const image = await getFavicon(request.path);
        response.status(200);
        response.setHeader('Content-Type', 'image/x-icon');
        response.send(image);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

app.get('/favicon.png', async (request: Request, response: Response) => {
    try {
        const image = await getFavicon(request.path);
        response.status(200);
        response.setHeader('Content-Type', 'image/png');
        response.send(image);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
