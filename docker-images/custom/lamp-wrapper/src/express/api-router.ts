import express from 'express';
import ajvFormats from 'ajv-formats';
import { Validator } from 'express-json-validator-middleware';
import fetch from 'cross-fetch';

const validator = new Validator({ allErrors: true });
ajvFormats.default(validator.ajv);

const lampUrl = process.env['LAMP_URL']!;

export const apiRouter = express.Router();

apiRouter.use((_, response, next) => {
    response.setHeader('Cache-Control', 'private, no-store, no-cache');
    return next();
});

apiRouter.get('/status', async (_, response, next) => {
    try {
        console.time('/api/status');
        const lampResponse = await fetch(`${lampUrl}/api/status`);
        console.timeEnd('/api/status');
        response.status(lampResponse.status);
        response.json(await lampResponse.json());
    } catch (error) {
        return next(error);
    }
});

apiRouter.post('/turn-on', async (_, response, next) => {
    try {
        console.time('/api/turn-on');
        const lampResponse = await fetch(`${lampUrl}/api/turn-on`, { method: 'POST' });
        console.timeEnd('/api/turn-on');
        response.status(lampResponse.status);
        response.json(await lampResponse.json());
    } catch (error) {
        return next(error);
    }
});

apiRouter.post('/turn-off', async (_, response, next) => {
    try {
        console.time('/api/turn-off');
        const lampResponse = await fetch(`${lampUrl}/api/turn-off`, { method: 'POST' });
        console.timeEnd('/api/turn-off');
        response.status(lampResponse.status);
        response.json(await lampResponse.json());
    } catch (error) {
        return next(error);
    }
});
