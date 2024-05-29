import express from 'express';
import { lastStatus } from './status-reader.ts';
import ajvFormats from 'ajv-formats';
import { AllowedSchema, Validator } from 'express-json-validator-middleware';
import { writeStatus } from './status-writer.ts';

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

apiRouter.post('/status', validateRequestSchema({ body: statusSchema }), async (request, response, next) => {
    try {
        const data: statusType = request.body;
        const newStatus = data.status === 'on';
        writeStatus(newStatus);
        response.status(200);
        response.json(true);
    } catch (error) {
        return next(error);
    }
});
