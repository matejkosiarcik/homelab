import path from 'node:path';
import winston from 'winston';
import { testArtifactDirectory } from '#/playwright/utils.ts';

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

        this.instances[loggerName] = winston.createLogger({
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
                winston.format.printf(({ timestamp, level, message }) => {
                    message = Array.isArray(message) ? message.map((el) => `${el}`).join(' ') : `${message}`;
                    return `${message}`
                        .trim()
                        .split('\n')
                        .map((line) => `${timestamp} ${level.toUpperCase().padStart(5, '_')}: ${line}`)
                        .join('\n');
                    }
                ),
            ),
            level: logLevel,
            transports: [
                new winston.transports.File({
                    dirname: outputDirectory,
                    filename: 'output.log',
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
