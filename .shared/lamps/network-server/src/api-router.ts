import express from 'express';

export const apiRouter = express.Router();

apiRouter.get('/status', async (_, response, next) => {
  try {
    const output = {
        status: "off",
    };

    response.status(200);
    response.json(output);
  } catch (error) {
    return next(error);
  }
});
