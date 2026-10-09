import fs from 'node:fs';
import path from 'node:path';
import winston from 'winston';
import { testArtifactDirectory } from '#/playwright/utils.ts';
import { parseISO } from 'date-fns';

/**
 * Logger for usage in tests
 */
export class Log {
    private static instances: Record<string, winston.Logger> = {};

    private static get instance(): winston.Logger {
        const outputDirectory = testArtifactDirectory();
        const loggerName = path.basename(outputDirectory);

        if (this.instances[loggerName]) {
            return this.instances[loggerName];
        }

        const logLevel = process.env['LOG_LEVEL'] || 'info';
        if (!['error', 'warn', 'info', 'debug'].includes(logLevel)) {
            throw new Error(`Unknown env LOG_LEVEL ${logLevel}`);
        }

        const outputFile = path.join(outputDirectory, 'log.txt');
        fs.writeFileSync(outputFile, '', 'utf-8');

        this.instances[loggerName] = winston.createLogger({
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DDTHH:mm:ss.SSSZ' }),
                winston.format.printf(({ timestamp, level, message }) => {
                    const editedTimestamp = parseISO(timestamp as string).toISOString();
                    message = Array.isArray(message) ? message.map((el) => `${el}`).join(' ') : `${message}`;
                    return `${message}`
                        .trim()
                        .split('\n')
                        .map((line) => `${editedTimestamp} ${level.toUpperCase().padStart(5, '_')}: ${line}`)
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
        return this.instances[loggerName];
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
