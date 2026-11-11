import fs from 'node:fs';
import path from 'node:path';
import util from 'node:util';
import { parseISO } from 'date-fns';
import winston from 'winston';
import { testArtifactDirectory } from '#/playwright/utils.ts';

function formatMessagePart(part: unknown): string {
    if (typeof part === 'string') {
        return part;
    }

    return util.inspect(part, {
        breakLength: 120,
        colors: false,
        compact: false,
        depth: null,
        maxArrayLength: null,
        maxStringLength: null,
    });
}

/**
 * Logger for usage in tests
 */
export class Log {
    private static _instances: Record<string, winston.Logger> = {};

    private static get instance(): winston.Logger {
        const outputDirectory = testArtifactDirectory();
        fs.mkdirSync(outputDirectory, { recursive: true });
        const loggerName = path.basename(outputDirectory);

        if (this._instances[loggerName]) {
            return this._instances[loggerName];
        }

        const logLevel = process.env['LOG_LEVEL'] || 'info';
        if (!['error', 'warn', 'info', 'debug'].includes(logLevel)) {
            throw new Error(`Unknown env LOG_LEVEL ${logLevel}`);
        }

        const outputFile = path.join(outputDirectory, 'log.txt');
        fs.writeFileSync(outputFile, '', 'utf-8');

        this._instances[loggerName] = winston.createLogger({
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DDTHH:mm:ss.SSSZ' }),
                winston.format.printf(({ timestamp, level, message }) => {
                    const editedTimestamp = parseISO(timestamp as string).toISOString();
                    message = Array.isArray(message) ? message.map((el) => formatMessagePart(el)).join('\n') : formatMessagePart(message);
                    return `${message}`
                        .trim()
                        .split('\n')
                        .map((line) => `${editedTimestamp} [${level.toUpperCase()}]: ${line}`)
                        .join('\n');
                    }
                ),
            ),
            level: logLevel,
            transports: [
                new winston.transports.File({
                    dirname: path.dirname(outputFile),
                    filename: path.basename(outputFile),
                }),
            ],
        });
        return this._instances[loggerName];
    }

    public static debug(...args: any[]): void {
        this.instance.debug(args);
    }

    public static info(...args: any[]): void {
        this.instance.info(args);
    }

    public static warn(...args: any[]): void {
        this.instance.warn(args);
    }

    public static error(...args: any[]): void {
        this.instance.error(args);
    }
}
