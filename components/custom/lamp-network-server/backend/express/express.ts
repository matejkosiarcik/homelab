import express from 'express';
import expressPrometheus from 'express-prom-bundle';
import cors from 'cors';
import { apiRouter } from './api-router.ts';
import { wwwRouter } from './www-router.ts';

// Init express and expressWs
export const expressApp = express();

// Remove default HTTP headers
expressApp.disable('x-powered-by');
expressApp.set('etag', false);

// CORS
expressApp.use(
    cors({
        origin: /.*/,
    })
);

expressApp.use(express.json());

// Register prometheus
// NOTE: Must be registered before custom routes
expressApp.use(
    expressPrometheus({
        includePath: true,
        includeMethod: true,
        percentiles: [],
        metricType: 'summary',
    })
);

// Register custom routes
expressApp.use('/api/', apiRouter);
expressApp.use('/', wwwRouter);
