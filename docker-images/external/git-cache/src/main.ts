import crypto from 'node:crypto';
import fs from 'node:fs';
import http, { IncomingMessage } from 'node:http';
import https from 'node:https';
import net from 'node:net';
import process from 'node:process';
import stream from 'node:stream';
import { faker } from '@faker-js/faker';
import { DataTypes, Model, Sequelize } from '@sequelize/core';
import { PostgresDialect } from '@sequelize/postgres';
import { formatISO, subHours } from 'date-fns';
import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import fastq from 'fastq';
import cron from 'node-cron';
import { Client as PostgresClient } from 'pg';
import { createClient } from 'redis';

if (fs.existsSync('.env')) {
    dotenv.config();
}

const config = {
    port: process.env['PORT'] ? Number.parseInt(process.env['PORT'], 10) : 8080,
    redis: {
        host: 'redis',
        port: 6379,
    },
    postgres: {
        database: 'gitcache',
        host: 'postgres',
        password: process.env['PGPASSWORD']!,
        port: 5432,
        user: 'postgres',
    },
};

async function delay(timeout: number) {
    return new Promise((resolve) => {
        setTimeout(() => resolve(undefined), timeout);
    });
}

/**
 * Wait for redis
 */
async function waitForRedisPort() {
    const start = Date.now();

    let lastError: Error;
    while (start + 30_000 > Date.now()) {
        try {
            await new Promise<void>((resolve, reject) => {
                const socket = net.connect(config.redis.port, config.redis.host);
                socket.setTimeout(1000);
                socket.on('connect', () => {
                    socket.destroy();
                    resolve();
                });
                socket.on('error', (error) => {
                    reject(error);
                });
            });
            console.log("Redis port is ready");
            return;
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(`${error}`);
        }
    }
    throw lastError!;
}

await waitForRedisPort();

/**
 * Redis setup
 */
const redis = createClient({
    url: `redis://${config.redis.host}:${config.redis.port}`,
});
redis.on('error', (err) => console.error('Redis error:', err));
await redis.connect();

/**
 * Wait for postgres
 */
async function waitForPostgresPort() {
    const start = Date.now();

    let lastError: Error;
    while (start + 30_000 > Date.now()) {
        try {
            await new Promise<void>((resolve, reject) => {
                const socket = net.connect(config.postgres.port, config.postgres.host);
                socket.setTimeout(1000);
                socket.on('connect', () => {
                    socket.destroy();
                    resolve();
                });
                socket.on('error', (error) => {
                    reject(error);
                });
            });
            console.log("Postgres port is ready");
            return;
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(`${error}`);
        }
    }
    throw lastError!;
}

await waitForPostgresPort();

async function waitForPostgres() {
    const start = Date.now();

    let lastError: Error;
    while (start + 30_000 > Date.now()) {
        try {
            const client = new PostgresClient({
                database: config.postgres.database,
                user: config.postgres.user,
                host: config.postgres.host,
                password: config.postgres.password,
                port: config.postgres.port,
                ssl: { rejectUnauthorized: false }, // TODO: Pass in custom CA certificate
            });
            await client.connect();
            await client.end();
            console.log("Postgres is ready");
            return;
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(`${error}`);
        }
    }
    throw lastError!;
}

await waitForPostgres();

/**
 * Postgres setup
 */
const sequelize = new Sequelize({
    dialect: PostgresDialect,
    database: config.postgres.database,
    host: config.postgres.host,
    logging: false,
    password: config.postgres.password,
    port: config.postgres.port,
    user: config.postgres.user,
    ssl: { rejectUnauthorized: false }, // TODO: Pass in custom CA certificate
});
class CachedChunk extends Model {
    declare row: number;
    declare key: string;
    declare index: number;
    declare data: Buffer;
}
CachedChunk.init(
    {
        row: {
            primaryKey: true,
            autoIncrement: true,
            type: DataTypes.INTEGER,
        },
        key: {
            type: DataTypes.STRING,
            unique: 'key:index:rand',
        },
        index: {
            type: DataTypes.INTEGER,
            unique: 'key:index:rand',
        },
        rand: {
            type: DataTypes.STRING,
            unique: 'key:index:rand',
        },
        data: {
            type: DataTypes.BLOB,
        },
    },
    {
        sequelize: sequelize,
        modelName: 'CacheChunk',
        tableName: 'data',
    },
);
await sequelize.sync();

// TODO: Improve Postgres SSL - Provide custom CA certificate
// TODO: Check if authorized and non-authorized git queries are cached separately

type CachedMetadata = {
    status: number;
    headers: Record<string, string>;
    parts: number;
    rand: string;
};

async function listRedisKeys(): Promise<string[]> {
    const output: string[] = [];
    for await (const keys of redis.scanIterator({ MATCH: '*', COUNT: 100 })) {
        output.push(...keys);
    }
    return output.filter((el) => el !== 'ping');
}
let redisKeys = await listRedisKeys();
console.log('Redis keys:', redisKeys);
const postgresKeys = ((await sequelize.query('SELECT DISTINCT "key" FROM "data" ORDER BY "key";')) as [{ key: string }[], unknown])[0].map((el) => el.key);
console.log('Postgres keys:', postgresKeys);
for (const key of postgresKeys) {
    if (redisKeys.includes(key)) {
        continue;
    }
    console.log(`Removing postgres rows with key: ${key}`);
    await sequelize.query(
        'DELETE FROM "data" WHERE "key" = :key;',
        {
            replacements: {
                key: key,
            },
        }
    );
}

// Check integrity of data in postgres against redis metadata and remove it if necessary
for (const key of redisKeys) {
    const metadataRaw = await redis.get(key);
    if (!metadataRaw) {
        console.log(`Removing redis and postgres rows with key: ${key}`);
        await redis.del(key);
        await sequelize.query(
            'DELETE FROM "data" WHERE "key" = :key',
            {
                replacements: {
                    key: key,
                },
            },
        );
        continue;
    }
    const metadata = JSON.parse(metadataRaw) as CachedMetadata;
    await sequelize.query(
        'DELETE FROM "data" WHERE "key" = :key AND "rand" != :rand;',
        {
            replacements: {
                key: key,
                rand: metadata.rand,
            },
        },
    );

    const chunksLength = await CachedChunk.count({
        where: {
            key: key,
            rand: metadata.rand,
        },
    });
    if (chunksLength !== metadata.parts) {
        console.log(`Removing redis and postgres rows with key: ${key}`);
        await redis.del(key);
        await sequelize.query(
            'DELETE FROM "data" WHERE "key" = :key;',
            {
                replacements: {
                    key: key,
                },
            },
        );
        continue;
    } else {
        console.log(`Keeping redis and postgres rows with key: ${key}`);
    }
}

/**
 * Write queue setup
 */
const writeQueue = fastq.promise(writeQueueWorker, 1);

async function writeQueueWorker(params: { key: string; index: number; rand: string; data: Buffer }) {
    await sequelize.query(
        'DELETE FROM "data" WHERE "key" = :key AND "index" = :index AND "rand" = :rand;',
        {
            replacements: {
                index: params.index,
                key: params.key,
                rand: params.rand,
            }
        }
    );
    await CachedChunk.create({ key: params.key, index: params.index, rand: params.rand, data: params.data });
}

/**
 * Compute incremental SHA1 for POST without buffering
 */
async function computeStreamingKey(request: IncomingMessage): Promise<{ key: string; postStream: NodeJS.ReadableStream }> {
    const baseKey = `${request.method}:${request.url}`;

    if (request.method !== 'POST') {
        return { key: baseKey, postStream: request };
    }

    const hash = crypto.createHash('sha1');
    const passThrough = new stream.PassThrough();

    request.on('data', (chunk) => {
        hash.update(chunk);
        passThrough.write(chunk);
    });

    request.on('end', () => {
        passThrough.end();
    });

    const shaFull = await new Promise<string>((resolve) =>
        request.on('end', () => resolve(hash.digest('hex')))
    );

    const fullKey = `${baseKey}:${shaFull}`;
    return { key: fullKey, postStream: passThrough };
}

/**
 * Indicates whether response is already cached
 */
async function isCached(key: string): Promise<boolean> {
    // if (await redis.exists(key) !== 1) {
    //     return false;
    // }

    const metadataRaw = await redis.get(key);
    if (!metadataRaw) {
        return false;
    }

    const metadata = JSON.parse(metadataRaw) as CachedMetadata;

    let chunkCount = await CachedChunk.count({
        where: {
            key: key,
            rand: metadata.rand,
        },
    });
    if (metadata.parts !== chunkCount) {
        return false;
    }

    return true;
}

/**
 * Stream cached response
 */
async function streamFromCache(key: string, response: Response) {
    const metadataRaw = await redis.get(key);
    if (!metadataRaw) {
        response.status(404).end('Cache metadata missing');
        return;
    }

    const metadata = JSON.parse(metadataRaw) as CachedMetadata;

    // Set headers
    for (const [key, value] of Object.entries(metadata.headers)) {
        if (key.toLowerCase() !== 'content-length') {
            response.setHeader(key, value);
        }
    }

    response.status(metadata.status);

    // Stream all chunks
    // for (let i = 1; i <= metadata.chunks; i++) {
    //     const str = await redis.get(`${key}:chunk:${i.toFixed(0)}`);
    //     if (!str) {
    //         console.error(`Got error, chunk ${key}:chunk:${i.toFixed(0)} is empty`);
    //         continue;
    //     }
    //     const buffer = Buffer.from(str, 'base64');
    //     if (buffer) {
    //         response.write(buf);
    //     }
    // }
    let chunks = await CachedChunk.findAll({
        where: {
            key: key,
            rand: metadata.rand,
        },
        order: [
            ['index', 'ASC'],
        ],
    });

    if (chunks.length !== metadata.parts) {
        await delay(1000);
        chunks = await CachedChunk.findAll({
            where: {
                key: key,
                rand: metadata.rand,
            },
            order: [
                ['index', 'ASC'],
            ],
        });
        if (chunks.length !== metadata.parts) {
            console.error(`Saved chunks do not match expected parts ${chunks.length}:${metadata.parts}`);
            throw new Error(`Saved chunks do not match expected parts ${chunks.length}:${metadata.parts}`);
        }
    }

    for (let chunk of chunks) {
        const buffer = chunk.data;
        if (buffer) {
            response.write(buffer);
        }
    }

    response.end();
}

/**
 * Save streamed response into Redis in chunks
 */
async function saveStreamToCache(
    key: string,
    headers: Record<string, string>,
    status: number,
    upstreamStream: IncomingMessage
) {
    let part = 0;
    let workBuffer = Buffer.alloc(0);
    const chunkLength = 1024 * 1024;
    const rand = faker.string.alphanumeric(16);

    await new Promise<void>((resolve, reject) => {
        upstreamStream.on('data', async (buffer: Buffer) => {
            workBuffer = Buffer.concat([workBuffer, buffer]);
            if (workBuffer.byteLength > chunkLength) {
                part += 1;
                const savingBuffer = Buffer.allocUnsafe(chunkLength);
                workBuffer.copy(savingBuffer, 0, 0, chunkLength);
                const tmpBuffer = Buffer.allocUnsafe(workBuffer.byteLength - chunkLength);
                workBuffer.copy(tmpBuffer, 0, chunkLength, workBuffer.byteLength);
                workBuffer = tmpBuffer;
                await writeQueue.push({ key: key, index: part, rand: rand, data: savingBuffer });
            }
        });

        upstreamStream.on('end', async () => {
            if (workBuffer.byteLength > 0) {
                part += 1;
                const savingBuffer = Buffer.from(workBuffer);
                workBuffer = Buffer.alloc(0);
                await writeQueue.push({ key: key, index: part, rand: rand, data: savingBuffer });
            }

            await redis.set(key, JSON.stringify({
                status: status,
                headers: headers,
                parts: part,
                rand: rand,
            } satisfies CachedMetadata));
            await redis.expire(key, 12 * 60 * 60); // 12 hours

            console.log(`Saved ${part} chunks to Postgres for ${key} with rand ${rand}`);
            resolve();
        });

        upstreamStream.on('error', async (error) => {
            console.log(`Error for ${key} with rand ${rand}`);
            reject(error);
        })
    });
}

const app = express();

// Healthcheck endpoint
app.get('/.health', (_, res) => res.sendStatus(200));

// Main endpoint
app.use(async (mainRequest: Request, mainResponse: Response) => {
    const { key, postStream } = await computeStreamingKey(mainRequest);
    console.log(`Key: ${key}`);

    if (await isCached(key)) {
        console.log(`Cache HIT for ${key}`);
        mainResponse.set('X-Cache', 'HIT');
        return streamFromCache(key, mainResponse);
    }

    console.log(`Cache MISS for ${key}`);
    mainResponse.set('X-Cache', 'MISS');

    const upstreamUrl = new URL(mainRequest.originalUrl, 'https://github.com');
    const httpClient = upstreamUrl.protocol === 'https:' ? https : http;

    const upstreamRequest = httpClient.request(
        upstreamUrl,
        {
            method: mainRequest.method,
            headers: {
                ...mainRequest.headers,
                host: upstreamUrl.host,
                'accept-encoding': '',
            },
        },
        async (upstreamResponse) => {
            const headers = upstreamResponse.headers as Record<string, string>;
            for (const [key, value] of Object.entries(headers)) {
                if (key.toLowerCase() !== 'content-length' && value) {
                    mainResponse.setHeader(key, value);
                }
            }

            mainResponse.status(upstreamResponse.statusCode || 502);
            upstreamResponse.pipe(mainResponse);

            await saveStreamToCache(
                key,
                headers,
                upstreamResponse.statusCode || 500,
                upstreamResponse
            );
        }
    );

    postStream.pipe(upstreamRequest);

    upstreamRequest.on('error', (err) => {
        console.error('Upstream error:', err);
        mainResponse.status(502).end();
    });
});

app.listen(config.port, () => {
    console.log(`Server started on port ${config.port}`);
});

process.on('SIGTERM', () => {
    process.exit(0);
});

cron.schedule('0 30 */2 * * *', async () => {
    const currentDate = new Date();
    console.log('Running cron cleanup');

    let redisKeys = await listRedisKeys();

    // Delete rows for nonexistent keys
    const postgresKeys = ((await sequelize.query('SELECT DISTINCT "key" FROM "data" ORDER BY "key";')) as [{ key: string }[], unknown])[0].map((el) => el.key);
    for (const key of postgresKeys) {
        if (redisKeys.includes(key)) {
            continue;
        }
        console.log(`Removing postgres rows with key: ${key}`);
        await sequelize.query(
            'DELETE FROM "data" WHERE "key" = :key;',
            {
                replacements: {
                    key: key,
                },
            },
        );
    }

    // Delete rows for expired keys
    for (const key of redisKeys) {
        const metadataRaw = await redis.get(key);
        if (!metadataRaw) {
            console.log(`Removing redis and postgres rows with key: ${key}`);
            await redis.del(key);
            await sequelize.query(
                'DELETE FROM "data" WHERE "key" = :key;',
                {
                    replacements: {
                        key: key,
                    },
                },
            );
            continue;
        }
        const metadata = JSON.parse(metadataRaw) as CachedMetadata;
        await sequelize.query(
            'DELETE FROM "data" WHERE "key" = :key AND "rand" != :rand AND "createdAt" <= :createdAt;',
            {
                replacements: {
                    createdAt: formatISO(subHours(currentDate, 6)),
                    key: key,
                    rand: metadata.rand,
                }
            }
        );
    }
});
