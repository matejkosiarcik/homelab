import path from 'node:path';
import express from 'express';
import { ServerResponse } from 'http';

export const wwwRouter = express.static(path.join('dist', 'frontend'), {
    redirect: false,
    setHeaders: (response: ServerResponse, path: string, _) => {
        // Note: The `path` is already resolved to a real file on filesystem
        // So even "directory" requests are resolved to eg. index.html

        if (/\.(?:js|css)$/.test(path)) {
            response.setHeader('Cache-Control', 'max-age=31536000, immutable');
        }
        if (/\.(?:html|svgz?|ico|a?png|jpe?g|jpe?|gif|webp|avif)$/.test(path)) {
            response.setHeader('Cache-Control', 'max-age=86400');
        }
    },
});
