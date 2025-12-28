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
import { formatISO, subSeconds } from 'date-fns';
import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import fastq from 'fastq';
import cron from 'node-cron';
import { Client as PostgresClient, Query } from 'pg';
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
    expirationInterval: 43_200, // 12 hours in seconds
};

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
        createdAt: 'created_at',
        updatedAt: 'updated_at',
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

    const pgClient = new PostgresClient({
        database: config.postgres.database,
        user: config.postgres.user,
        host: config.postgres.host,
        password: config.postgres.password,
        port: config.postgres.port,
        ssl: { rejectUnauthorized: false }, // TODO: Pass in custom CA certificate
    });

    await pgClient.connect();

    // Stream rows from Postgres using Query events
    const query = new Query('SELECT "index", "data" FROM "data" WHERE "key" = $1 AND "rand" = $2 ORDER BY "index" ASC;', [key, metadata.rand]);

    try {
        await new Promise<void>((resolve, reject) => {
            const queryStream = pgClient.query(query);

            queryStream.on('row', (row: CachedChunk) => {
                response.write(row.data);
            });

            queryStream.on('end', async () => {
                resolve();
            });

            queryStream.on('error', async (err) => {
                reject(err);
            });
        });
    } finally {
        await pgClient.end();
        response.end();
    }
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
    const chunkLength = 2 * 1024 * 1024;
    const rand = faker.string.alphanumeric(16);
    let part = 0;
    let workBufferMaxLength = chunkLength;
    let workBufferLength = 0;
    let workBuffer = Buffer.allocUnsafe(workBufferMaxLength);

    await new Promise<void>((resolve, reject) => {
        upstreamStream.on('data', async (buffer: Buffer) => {
            if (workBufferLength + buffer.byteLength >= chunkLength) {
                // We have reached the limit for a single chunk to save in DB

                if (workBufferLength + buffer.byteLength > workBufferMaxLength) {
                    // We have to enlarge the workBuffer a bit before we can copy into it
                    workBufferMaxLength = workBufferLength + buffer.byteLength;
                    const newWorkBuffer = Buffer.allocUnsafe(workBufferMaxLength);
                    workBuffer.copy(newWorkBuffer, 0, 0, workBufferLength);
                    workBuffer = newWorkBuffer;
                }

                buffer.copy(workBuffer, workBufferLength, 0, buffer.byteLength);
                workBufferLength += buffer.byteLength;

                part += 1;
                upstreamStream.pause();
                await writeQueue.push({ key: key, index: part, rand: rand, data: workBuffer.subarray(0, workBufferLength) });
                upstreamStream.resume();
                workBufferLength = 0;
            } else {
                // Just copy the buffer and continue
                buffer.copy(workBuffer, workBufferLength, 0, buffer.byteLength);
                workBufferLength += buffer.byteLength;
            }
        });

        upstreamStream.on('end', async () => {
            if (workBufferLength > 0) {
                part += 1;
                await writeQueue.push({ key: key, index: part, rand: rand, data: workBuffer.subarray(0, workBufferLength) });
                workBufferLength = 0;
            }

            await redis.set(key, JSON.stringify({
                status: status,
                headers: headers,
                parts: part,
                rand: rand,
            } satisfies CachedMetadata));
            await redis.expire(key, config.expirationInterval);

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

const upstreamUrl = process.env['UPSTREAM_URL'] || '';
if (!upstreamUrl) {
    console.error(`UPSTREAM_URL unset.`);
    process.exit(1);
}

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

    const requestUpstreamUrl = new URL(mainRequest.originalUrl, upstreamUrl);
    const httpClient = requestUpstreamUrl.protocol === 'https:' ? https : http;

    const upstreamRequest = httpClient.request(
        requestUpstreamUrl,
        {
            method: mainRequest.method,
            headers: {
                ...mainRequest.headers,
                host: requestUpstreamUrl.host,
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
            'DELETE FROM "data" WHERE "key" = :key AND "rand" != :rand AND "created_at" <= :createdAt;',
            {
                replacements: {
                    createdAt: formatISO(subSeconds(currentDate, config.expirationInterval * 2)),
                    key: key,
                    rand: metadata.rand,
                }
            }
        );
    }
});
