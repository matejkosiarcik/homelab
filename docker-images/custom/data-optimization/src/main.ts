// import crypto from 'node:crypto';
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

const sourceDirectory = path.resolve(process.env['SOURCE_DIR'] || '/source-data');
const targetDirectory = path.resolve(process.env['TARGET_DIR'] || '/target-data');
const cacheDirectory = path.resolve(process.env['CACHE_DIR'] || '/cache-data');

console.log('Source directory:', sourceDirectory);
console.log('Target directory:', targetDirectory);
console.log('Cache directory:', cacheDirectory);

if (!fs.existsSync(path.dirname(sourceDirectory))) {
    fs.mkdirSync(path.dirname(sourceDirectory), { recursive: true });
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

// function hashFile(filepath: string): Promise<string> {
//     return new Promise((resolve, reject) => {
//         const hash = crypto.createHash('sha256');
//         const stream = fs.createReadStream(filepath);
//         stream.on('data', chunk => hash.update(chunk));
//         stream.on('end', () => resolve(hash.digest('hex')));
//         stream.on('error', () => reject());
//     });
// }

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

async function processFile(relativeFilepath: string) {
    console.error();

    // const fileHash = await hashFile(path.join(sourceDirectory, relativeFilepath));
    // const cacheFilepath = path.join(cacheDirectory, fileHash.substring(0, 2), `${fileHash}.bin`);
    const sourceFilepath = path.join(sourceDirectory, relativeFilepath);
    const targetFilepath = path.join(targetDirectory, relativeFilepath);

    if (['.DS_Store', 'Icon\r'].includes(path.basename(relativeFilepath))) {
        log.info(`Skipping file ${relativeFilepath.replace(/\s/g, ' ')}`);
        return;
    }

    // await fsx.mkdir(path.dirname(cacheFilepath), { recursive: true });
    await fsx.mkdir(path.dirname(targetFilepath), { recursive: true });

    // Check if the file was already processed and just copy it if it was
    // TODO: check if the file exists with other extensions
    // if (fs.existsSync(cacheFilepath)) {
    //     await fsx.copyFile(cacheFilepath, targetFilepath);
    //     return;
    // }

    const fileType = await getFileType(relativeFilepath);
    const [fileType1, fileType2] = fileType.split(';')[0].trim().split('/');
    const originalExtension = path.extname(relativeFilepath).substring(1);

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

    let outputFilename = '';

    async function fallbackCopy() {
        await fsx.copyFile(sourceFilepath, targetFilepath);
        outputFilename = path.basename(targetFilepath);
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

                outputFilename = path.basename(convertedFilepath);
                // await fsx.copyFile(convertedFilepath, cacheFilepath);
                await fsx.copyFile(convertedFilepath, path.join(path.dirname(targetFilepath), path.basename(convertedFilepath)));
            } else {
                log.warn(`File ${relativeFilepath} was not optimized (bigger result)`);
                await fallbackCopy();
            }
        } catch (error) {
            log.error(`There was error optimizing ${relativeFilepath.replace(/\s/g, ' ')}: (${actualFileType}) ${error}`);
            await fallbackCopy();
        } finally {
            await fsx.rm(temporaryDirectory, { force: true, recursive: true });
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

    log.info(`Optimizing ${relativeFilepath.replace(/\s/g, ' ')} (${actualFileType})`);
    switch (actualFileType) {
        case 'audio': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.opus');
                await runCommand([
                    'ffmpeg',
                    '-i', sourceFilepath,
                    '-c:a', 'libopus',
                    '-b:a', '96k',
                    '-threads', '1', // Restrict to a single thread
                    tmpFile,
                ]);
                const outputFile = ensureExtension(path.join(temporaryDirectory, path.basename(relativeFilepath)), 'opus');
                await fsx.rename(tmpFile, outputFile);
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
                const tmpFile = path.join(temporaryDirectory, `${path.basename(relativeFilepath).replace(/\..+$/, '')}.pdf`);
                await runCommand([
                    'soffice',
                    '--headless',
                    '--convert-to',
                    'pdf',
                    '--outdir', temporaryDirectory,
                    sourceFilepath,
                ]);
                await fsx.mkdir(path.join(temporaryDirectory, 'tmpdir'), { recursive: true });
                const tmpFile2 = path.join(temporaryDirectory, 'tmpdir', 'file.pdf');
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
                    tmpFile,
                ]);
                const outputFile = ensureExtension(path.join(temporaryDirectory, path.basename(relativeFilepath)), 'pdf');
                await fsx.rename(tmpFile2, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'document-pdf': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.pdf');
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
                    `-sOutputFile=${tmpFile}`,
                    sourceFilepath,
                ]);
                // '-dEmbedAllFonts=true',
                // '-dSubsetFonts=true',
                // '-dCompressFonts=true',
                const outputFile = ensureExtension(path.join(temporaryDirectory, path.basename(relativeFilepath)), 'pdf');
                await fsx.rename(tmpFile, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'image': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.avif');
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
                    tmpFile,
                ]);
                const outputFile = ensureExtension(path.join(temporaryDirectory, path.basename(relativeFilepath)), 'avif');
                await fsx.rename(tmpFile, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'image-animation': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.avif');
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
                    tmpFile,
                ]);
                const outputFile = ensureExtension(path.join(temporaryDirectory, path.basename(relativeFilepath)), 'avif');
                await fsx.rename(tmpFile, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'video': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.mkv');
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
                    tmpFile,
                ]);
                const outputFile = ensureExtension(path.join(temporaryDirectory, path.basename(relativeFilepath)), 'mkv');
                await fsx.rename(tmpFile, outputFile);
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
                const tmpFile = path.join(temporaryDirectory, 'file.json');
                await runCommand([
                    'jq',
                    '.',
                    '--compact-output',
                    sourceFilepath,
                ], tmpFile);
                const outputFile = path.join(temporaryDirectory, path.basename(relativeFilepath));
                await fsx.rename(tmpFile, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'text-xml': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.xml');
                await runCommand([
                    'xmllint',
                    '--noblanks',
                    sourceFilepath,
                ], tmpFile);
                const outputFile = path.join(temporaryDirectory, path.basename(relativeFilepath));
                await fsx.rename(tmpFile, outputFile);
                return path.basename(outputFile);
            });
            break;
        }
        case 'text-yaml': {
            await convertFile(async (temporaryDirectory) => {
                const tmpFile = path.join(temporaryDirectory, 'file.yaml');
                await runCommand([
                    'yq',
                    '.',
                    '--compact-output',
                    '--yaml-output',
                    sourceFilepath,
                ], tmpFile);
                const outputFile = path.join(temporaryDirectory, path.basename(relativeFilepath));
                await fsx.rename(tmpFile, outputFile);
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

    log.info(`File ${relativeFilepath.replace(/\s/g, ' ')} is converted as ${outputFilename.replace(/\s/g, ' ')}`);
}

void (async () => {
    // For all files:
    // 1. Hash file
    // 2. Check database if the filepath and hash match
    // 2a). If filepath does not exist at all -> goto 4.
    // 2b). If filepath exists and hash not matches -> goto 4.
    // 2c). If filepath exists and hash matches -> goto (end)
    // 3. Delete optimized file from target directory and database entry
    // 4. Optimize file and save in target directory
    // 5. Save filepath and original hash in database

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
