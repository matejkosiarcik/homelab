import express from 'express';
import { lastStatus } from './status-reader.ts';
import ajvFormats from 'ajv-formats';
import { AllowedSchema, Validator } from 'express-json-validator-middleware';
import fetch from 'cross-fetch';

const validator = new Validator({ allErrors: true });
ajvFormats.default(validator.ajv);
export const validateRequestSchema = validator.validate;

export const apiRouter = express.Router();

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

const hardwareServer = process.env['UPSTREAM']!;

apiRouter.post('/status', validateRequestSchema({ body: statusSchema }), async (request, response, next) => {
    try {
        const upstreamResponse = await fetch(hardwareServer, {
            method: 'POST',
            body: request.body,
        });
        const output: statusType = await upstreamResponse.json();

        response.status(200);
        response.json(output);
    } catch (error) {
        return next(error);
    }
});
