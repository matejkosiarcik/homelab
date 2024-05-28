import express from 'express';
import expressPrometheus from 'express-prom-bundle';
import cors from 'cors';
import { apiRouter } from './api-router';

// Init express and expressWs
export const expressApp = express();

// Remove default HTTP headers
expressApp.disable('x-powered-by');
expressApp.set('etag', false);

// CORS
expressApp.use(
  cors({
    origin: /.*/,
    allowedHeaders: ['Authorization', 'Content-Type'],
  })
);

const routers = [
    apiRouter,
];

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

// Disable client-side caching for dynamic requests
routers.forEach((router) => {
    router.use((_, response, next) => {
      response.setHeader('Cache-Control', 'private, no-store, no-cache');
      return next();
    });
})

// Register custom routes
expressApp.use('/api/', apiRouter);
