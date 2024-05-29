import express from 'express';
import { lastStatus } from './status-watch.ts';

export const apiRouter = express.Router();

apiRouter.get('/status', async (_, response, next) => {
    try {
        const output = {
            status: lastStatus ? 'on' : 'off',
        };

        response.status(200);
        response.json(output);
    } catch (error) {
        return next(error);
    }
});
