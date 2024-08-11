import express from 'express';
import { lastStatus } from '../utils/status-reader.ts';
import ajvFormats from 'ajv-formats';
import { AllowedSchema, Validator } from 'express-json-validator-middleware';
import fetch from 'cross-fetch';
import { log } from '../utils/logging.ts';

const validator = new Validator({ allErrors: true });
ajvFormats.default(validator.ajv);
const validateRequestSchema = validator.validate;

export const apiRouter = express.Router();

apiRouter.use((_, response, next) => {
    response.setHeader('Cache-Control', 'private, no-store, no-cache');
    return next();
});

const statusSchema: AllowedSchema = {
    type: 'object',
    properties: {
        status: {
            type: 'string',
            enum: ['on', 'off'],
        },
    },
    required: ['status'],
};

type statusType = {
    status: 'on' | 'off',
};

apiRouter.get('/status', async (_, response, next) => {
    try {
        const output: statusType = {
            status: lastStatus ? 'on' : 'off',
        };
        response.status(200);
        response.json(output);
    } catch (error) {
        return next(error);
    }
});

apiRouter.post('/status', validateRequestSchema({ body: statusSchema }), async (request, response, next) => {
    try {
        const hardwareServer = process.env['HOMELAB_UPSTREAM_URL']!;
        const requestText = JSON.stringify(request.body);
        const upstreamResponse = await fetch(hardwareServer, {
            method: 'POST',
            body: requestText,
        });
        const responseText = await upstreamResponse.text();
        const output = await (async () => {
            try {
                return {
                    status: 200,
                    body: JSON.parse(responseText)
                };
            } catch {
                log.error(`Could not parse response JSON: ${responseText}`);
                return {
                    status: 500,
                    body: { status: lastStatus ? 'on' : 'off' },
                }
            }
        })();

        response.status(output.status);
        response.json(output.body);
    } catch (error) {
        return next(error);
    }
});
