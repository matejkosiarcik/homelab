import fs from 'node:fs';
import path from 'node:path';
import winston from 'winston';
import { parseISO } from 'date-fns';

/**
 * General logger
 */
export class Log {
    private static _instance: winston.Logger | undefined = undefined;

    private static get instance(): winston.Logger {
        const outputDirectory = path.join('/', 'homelab', 'logs', 'default');

        if (this._instance) {
            return this._instance;
        }

        const logLevel = process.env['LOG_LEVEL'] || 'info';
        if (!['error', 'warn', 'info', 'debug'].includes(logLevel)) {
            throw new Error(`Unknown env LOG_LEVEL ${logLevel}`);
        }

        const outputFile = path.join(outputDirectory, 'file.log');
        fs.writeFileSync(outputFile, '', 'utf-8');

        this._instance = winston.createLogger({
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DDTHH:mm:ss.SSSZ' }),
                winston.format.printf(({ timestamp, level, message }) => {
                    const editedTimestamp = parseISO(timestamp as string).toISOString();
                    message = Array.isArray(message) ? message.map((el) => `${el}`).join(' ') : `${message}`;
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
                new winston.transports.Console({
                    stderrLevels: ['error', 'warn', 'info', 'debug'], // Send all to stderr
                }),
                new winston.transports.File({
                    dirname: path.dirname(outputFile),
                    filename: path.basename(outputFile),
                }),
            ],
        });
        return this._instance;
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
