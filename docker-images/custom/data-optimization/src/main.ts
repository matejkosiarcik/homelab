import crypto from 'node:crypto';
import fs from 'node:fs';
import fsx from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import dotevn from 'dotenv';
import { execa } from 'execa';
import winston from 'winston';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const snapshotsDirectory = path.resolve(process.env['SNAPSHOTS_DIR'] || '/source-data');
let sourceDirectory = '/placeholder';
const targetDirectory = path.resolve(process.env['TARGET_DIR'] || '/target-data');
const cacheDirectory = path.resolve(process.env['CACHE_DIR'] || '/cache-data');

console.log('Snapshots directory:', snapshotsDirectory);
console.log('Target directory:', targetDirectory);
console.log('Cache directory:', cacheDirectory);

if (!fs.existsSync(path.dirname(snapshotsDirectory))) {
    console.error(`Snapshots directory not found: ${snapshotsDirectory}`);
    process.exit(1);
}
if (!fs.existsSync(path.dirname(targetDirectory))) {
    fs.mkdirSync(path.dirname(targetDirectory), { recursive: true });
}
if (!fs.existsSync(path.dirname(cacheDirectory))) {
    fs.mkdirSync(path.dirname(cacheDirectory), { recursive: true });
}

const log = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
        winston.format.printf(({ timestamp, level, message }) => `${message ?? ''}`.trim().split('\n').map((line) => `${timestamp} ${level.toUpperCase()}: ${line}`).join('\n')),
    ),
    transports: [
        new winston.transports.Console({
            stderrLevels: Object.keys(winston.config.npm.levels),
        }),
    ],
});

function hashFile(filepath: string): Promise<string> {
    return new Promise((resolve, reject) => {
        const hash = crypto.createHash('sha256');
        const stream = fs.createReadStream(filepath);
        stream.on('data', chunk => hash.update(chunk));
        stream.on('end', () => resolve(hash.digest('hex')));
        stream.on('error', () => reject());
    });
}

async function getFileType(file: string): Promise<string> {
    const execaProcess = await execa('file', ['--mime-type', path.join(sourceDirectory, file)], {
        all: true,
        timeout: 30_000,
    });
    if (execaProcess.exitCode !== 0) {
        throw new Error(`Could not get filetype from ${path.join(sourceDirectory, file)}. Got error ${execaProcess.exitCode}: ${execaProcess.all}`);
    }
    const output = execaProcess.all.replace(/^.+: /, '').toLowerCase();
    return output;
}

async function atomicCopyFile(source: string, target: string) {
    const tmpdir = await fsx.mkdtemp(path.join(os.tmpdir(), 'homelab-'));
    try {
        const tmpfile = path.join(tmpdir, 'file.bin');
        await fsx.copyFile(source, tmpfile);
        await fsx.rename(tmpfile, target);
    } finally {
        await fsx.rm(tmpdir, { force: true, recursive: true });
    }
}

async function runCommand(command: string[], output?: string | undefined) {
    const subprocess = await execa(command[0], command.slice(1), {
        all: true,
        timeout: 3_600_000, // 1 hour
        stdout: output ? { file: output } : 'pipe',
        stderr: 'pipe',
        stdin: 'pipe',
        detached: true,
    });
    if (subprocess.exitCode !== 0) {
        throw new Error(`Command "${command.join(' ')}" ${subprocess.timedOut ? 'timed out' : `exited with code ${subprocess.exitCode}`}:\n${subprocess.all}`);
    }
}

function ensureExtension(filepath: string, extension: string): string {
    return `${filepath}${path.basename(filepath).replace(/^.*\./, '') === extension ? '' : `.${extension}`}`;
}

async function processFile(relativeFilepath: string) {
    console.error(); // Just print blank line between files

    const fileHash = await hashFile(path.join(sourceDirectory, relativeFilepath));
    const cachedFilepath = path.join(cacheDirectory, fileHash.substring(0, 2), `${fileHash}.bin`);
    const sourceFilepath = path.join(sourceDirectory, relativeFilepath);
    const defaultTargetFilepath = path.join(targetDirectory, relativeFilepath);

    if ([/Private.*\.zip/, '.DS_Store', 'Icon\r'].some((el) => typeof el === 'string' ? el === path.basename(relativeFilepath) : el.test(path.basename(relativeFilepath)))) {
        log.info(`Skipping file ${relativeFilepath.replace(/\s/g, ' ')}`);
        return;
    }

    await fsx.mkdir(path.dirname(cachedFilepath), { recursive: true });
    await fsx.mkdir(path.dirname(defaultTargetFilepath), { recursive: true });

    const fileType = await getFileType(relativeFilepath);
    const [fileType1, fileType2] = fileType.split(';')[0].trim().split('/');
    log.debug(`Detected ${relativeFilepath} as ${fileType1}/${fileType2}`);
    const originalExtension = path.basename(relativeFilepath).replace(/^.*\./, '');

    /**
     * Determine actual filetype
     * Here we merge multiple mimetypes into a single type
     * And resolve any misdirections, eg. when some audio formats identify as video, we force them as audio instead
     */
    const actualFileType = (() => {
        switch (fileType1) {
            case 'image': {
                switch (fileType2) {
                    case 'avif':
                    case 'bmp':
                    case 'heic':
                    case 'heif':
                    case 'jp2':
                    case 'jpeg':
                    case 'png':
                    case 'webp': {
                        return 'image';
                    }
                    case 'apng':
                    case 'gif': {
                        return 'image-animation';
                    }
                    default: {
                        break;
                    }
                }
                break;
            }
            case 'video': {
                switch (fileType2) {
                    case '3gpp': // .3gp
                    case '3gpp2': // .3gp2
                    case 'quicktime': // .mov
                    case 'webm':
                    case 'x-matroska': // .mkv
                    case 'x-msvideo': { // .avi
                        return 'video';
                    }
                    case 'mp4': {
                        if (['alac', 'm4a'].includes(originalExtension)) {
                            return 'audio';
                        } else {
                            return 'video';
                        }
                    }
                }
                break;
            }
            case 'audio': {
                switch (fileType2) {
                    case '3gpp': // .3gp
                    case '3gpp2': // .3gp2
                    case 'flac':
                    case 'mpeg': // .mp3
                    case 'x-hx-aac-adts': { // .aac
                        return 'audio';
                    }
                    default: {
                        break;
                    }
                }
                break;
            }
            case 'application': {
                switch (fileType2) {
                    case 'msword': // .doc
                    case 'vnd.openxmlformats-officedocument.wordprocessingml.document': // .docx
                    case 'vnd.ms-powerpoint': // .ppt
                    case 'vnd.openxmlformats-officedocument.presentationml.presentation': // .pptx
                    case 'vnd.ms-excel': // .xls
                    case 'vnd.openxmlformats-officedocument.spreadsheetml.sheet': // .xlsx
                    case 'vnd.oasis.opendocument.text': // .odt
                    case 'vnd.oasis.opendocument.presentation': // .odp
                    case 'vnd.oasis.opendocument.spreadsheet': { // .ods
                        return 'document-office';
                    }
                    case 'json': {
                        return 'text-json';
                    }
                    case 'octet-stream': {
                        return 'binary';
                    }
                    case 'pdf': {
                        return 'document-pdf';
                    }
                    case 'xml': {
                        return 'text-xml';
                    }
                    default: {
                        break;
                    }
                }
                break;
            }
            case 'text': {
                switch (fileType2) {
                    case 'csv': {
                        return 'text';
                    }
                    case 'plain': {
                        if (['yml', 'yaml'].includes(originalExtension)) {
                            return 'text-yaml';
                        } else {
                            return 'text';
                        }
                    }
                    case 'xml': {
                        return 'text-xml';
                    }
                    default: {
                        break;
                    }
                }
                break;
            }
            default: {
                break;
            }
        }
        return '';
    })();
    log.info(`Detected ${relativeFilepath.replace(/\s/g, ' ')} as ${fileType1}/${fileType2} - ${actualFileType}`);

    const potentialTargetFilepath = (() => {
        let filename = (() => {
            switch (actualFileType) {
                case 'audio': {
                    return ensureExtension(path.basename(relativeFilepath), 'opus');
                }
                case 'binary': {
                    return path.basename(relativeFilepath);
                }
                case 'document-office': {
                    return ensureExtension(path.basename(relativeFilepath), 'pdf');
                }
                case 'document-pdf': {
                    return ensureExtension(path.basename(relativeFilepath), 'pdf');
                }
                case 'image': {
                    return ensureExtension(path.basename(relativeFilepath), 'avif');
                }
                case 'image-animation': {
                    return ensureExtension(path.basename(relativeFilepath), 'avif');
                }
                case 'video': {
                    return ensureExtension(path.basename(relativeFilepath), 'mkv');
                }
                case 'text': {
                    return path.basename(relativeFilepath);
                }
                case 'text-json': {
                    return path.basename(relativeFilepath);
                }
                case 'text-xml': {
                    return path.basename(relativeFilepath);
                }
                case 'text-yaml': {
                    return path.basename(relativeFilepath);
                }
                default: {
                    return path.basename(relativeFilepath);
                }
            }
        })();
        return path.join(path.dirname(defaultTargetFilepath), filename);
    })();

    let outputFilename = path.basename(potentialTargetFilepath);

    if (fs.existsSync(cachedFilepath)) {
        log.info(`Copying file ${relativeFilepath} from cache as ${path.basename(potentialTargetFilepath)}`);
        await atomicCopyFile(cachedFilepath, potentialTargetFilepath);
        return;
    }

    async function fallbackCopy() {
        outputFilename = path.basename(defaultTargetFilepath);
        await atomicCopyFile(sourceFilepath, defaultTargetFilepath);
    }

    async function convertFile(callback: (temporaryDirectory: string) => Promise<string>) {
        const temporaryDirectory = await fsx.mkdtemp(path.join(os.tmpdir(), 'homelab-'));
        try {
            const convertedFilepath = path.join(temporaryDirectory, await callback(temporaryDirectory));
            const [sourceFileStat, convertedFileStat] = await Promise.all([
                fsx.stat(sourceFilepath),
                fsx.stat(convertedFilepath),
            ]);

            // Compare sizes and only use converted file if it's smaller
            if (convertedFileStat.size < sourceFileStat.size) {
                await atomicCopyFile(convertedFilepath, cachedFilepath);
                await atomicCopyFile(convertedFilepath, potentialTargetFilepath);
            } else {
                log.warn(`File ${relativeFilepath} was not optimized, but enlarged`);
                await fallbackCopy();
            }
        } catch (error) {
            log.error(`There was error optimizing ${relativeFilepath.replace(/\s/g, ' ')}: (${actualFileType}) ${error}`);
            await fallbackCopy();
        } finally {
            await fsx.rm(temporaryDirectory, { force: true, recursive: true });
        }
    }

    log.info(`Optimizing ${relativeFilepath.replace(/\s/g, ' ')} (${actualFileType})`);
    switch (actualFileType) {
        case 'audio': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.opus');
                await runCommand([
                    'ffmpeg',
                    '-i', sourceFilepath,
                    '-c:a', 'libopus',
                    '-b:a', '96k',
                    '-threads', '1', // Restrict to a single thread
                    outputFile,
                ]);
                return path.basename(outputFile);
            });
            break;
        }
        case 'binary': {
            await fallbackCopy();
            break;
        }
        case 'document-office': {
            await convertFile(async (temporaryDirectory) => {
                await fsx.mkdir(path.join(temporaryDirectory, 'tmpdir1'), { recursive: true });
                const tmpFile1 = path.join(temporaryDirectory, 'tmpdir1', `${path.basename(relativeFilepath).replace(/\..+$/, '')}.pdf`);
                await runCommand([
                    'soffice',
                    '--headless',
                    '--convert-to',
                    'pdf',
                    '--outdir', temporaryDirectory,
                    sourceFilepath,
                ]);
                await fsx.mkdir(path.join(temporaryDirectory, 'tmpdir2'), { recursive: true });
                const tmpFile2 = path.join(temporaryDirectory, 'tmpdir2', 'file.pdf');
                await runCommand([
                    'gs',
                    '-sDEVICE=pdfwrite',
                    '-dBATCH',
                    '-dNOPAUSE',
                    '-dPDFSETTINGS=/screen',
                    '-dSAFER',
                    '-dRemoveAllMetadata=true',
                    '-dCompressPages=true',
                    '-dCompatibilityLevel=1.7',
                    '-dDownsampleColorImages=true', '-dColorImageResolution=24',
                    '-dDownsampleGrayImages=true', '-dGrayImageResolution=24',
                    '-dDownsampleMonoImages=true', '-dMonoImageResolution=24',
                    '-dJPEGQ=40',
                    '-dAutoFilterColorImages=false',
                    '-dColorImageFilter=/DCTEncode',
                    `-sOutputFile=${tmpFile2}`,
                    tmpFile1,
                ]);
                const outputFile = path.join(temporaryDirectory, 'file.pdf');
                await fsx.rename(tmpFile2, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'document-pdf': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.pdf');
                await runCommand([
                    'gs',
                    '-sDEVICE=pdfwrite',
                    '-dBATCH',
                    '-dNOPAUSE',
                    '-dPDFSETTINGS=/screen',
                    '-dSAFER',
                    '-dRemoveAllMetadata=true',
                    '-dCompressPages=true',
                    '-dCompatibilityLevel=1.7',
                    '-dDownsampleColorImages=true', '-dColorImageResolution=24',
                    '-dDownsampleGrayImages=true', '-dGrayImageResolution=24',
                    '-dDownsampleMonoImages=true', '-dMonoImageResolution=24',
                    '-dJPEGQ=40',
                    '-dAutoFilterColorImages=false',
                    '-dColorImageFilter=/DCTEncode',
                    `-sOutputFile=${outputFile}`,
                    sourceFilepath,
                ]);
                // '-dEmbedAllFonts=true',
                // '-dSubsetFonts=true',
                // '-dCompressFonts=true',
                return path.basename(outputFile);
            });
            break;
        }
        case 'image': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.avif');
                await runCommand([
                    'magick',
                    sourceFilepath,
                    '-resize',
                    '2000x2000>',
                    '-colorspace',
                    'YUV',
                    '-quality',
                    '50',
                    '-define',
                    'heic:chroma=420',
                    '-define',
                    'heic:effort=9', // Max effort
                    '-define',
                    'heic:speed=0',
                    '-define',
                    'heic:preserve-alpha=true',
                    outputFile,
                ]);
                return path.basename(outputFile);
            });
            break;
        }
        case 'image-animation': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.avif');
                await runCommand([
                    'ffmpeg',
                    '-i', sourceFilepath,
                    '-c:v', 'libsvtav1',
                    '-crf', '30',
                    '-preset', '8',
                    '-pix_fmt', 'yuv420p10le',
                    '-svtav1-params', 'tune=0',
                    '-vf', 'scale=w=480:h=480:force_original_aspect_ratio=decrease',
                    '-threads', '1', // Restrict to a single thread
                    outputFile,
                ]);
                return path.basename(outputFile);
            });
            break;
        }
        case 'video': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.mkv');
                await runCommand([
                    'ffmpeg',
                    '-i', sourceFilepath,
                    '-c:v', 'libsvtav1',
                    '-crf', '50',
                    '-preset', '8',
                    '-pix_fmt', 'yuv420p10le',
                    '-svtav1-params', 'tune=0',
                    '-vf', 'scale=w=1920:h=1080:force_original_aspect_ratio=decrease',
                    '-threads', '1', // Restrict to a single thread
                    outputFile,
                ]);
                return path.basename(outputFile);
            });
            break;
        }
        case 'text': {
            await fallbackCopy();
            break
        }
        case 'text-json': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.json');
                await runCommand([
                    'jq',
                    '.',
                    '--compact-output',
                    sourceFilepath,
                ], outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'text-xml': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.xml');
                await runCommand([
                    'xmllint',
                    '--noblanks',
                    sourceFilepath,
                ], outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'text-yaml': {
            await convertFile(async (temporaryDirectory) => {
                const outputFile = path.join(temporaryDirectory, 'file.yaml');
                await runCommand([
                    'yq',
                    '.',
                    '--compact-output',
                    '--yaml-output',
                    sourceFilepath,
                ], outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        default: {
            await fallbackCopy();
            log.error(`Unknown file type for optimization: ${relativeFilepath} - ${fileType}`);
            break;
        }
    }

    log.info(`File converted from ${relativeFilepath.replace(/\s/g, ' ')} to ${outputFilename.replace(/\s/g, ' ')}`);
}

void (async () => {
    const snapshotDirectories = await fsx.readdir(snapshotsDirectory, { withFileTypes: false, recursive: false });
    const lastSnapshotDirectory = snapshotDirectories.filter((el) => /^zfs-auto-snap_hourly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]+$/.test(el)).toSorted((lhs, rhs) => lhs.localeCompare(rhs)).at(-1)!;
    sourceDirectory = path.join(snapshotsDirectory, lastSnapshotDirectory);

    const files = await fsx.readdir(sourceDirectory, { withFileTypes: false, recursive: true });
    for (const relativeFilepath of files) {
        const fullFilepath = path.join(sourceDirectory, relativeFilepath);

        // Only optimize files
        if (!(await fsx.stat(fullFilepath)).isFile()) {
            continue;
        }

        // Skip lockfiles
        if ([
            /^.~/,
        ].some((el) => el.test(relativeFilepath))) {
            continue;
        }

        // Skip version-control and build artifact directories
        if ([
            /^.*\/(?:.git|.venv|node_modules|venv)\//,
        ].some((el) => el.test(fullFilepath))) {
            continue;
        }

        await processFile(relativeFilepath);
    }
})();

process.on('SIGTERM', () => {
    console.error('SIGTERM received');
    process.exit(0);
});
