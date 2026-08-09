const { app } = require('@azure/functions');
const Redis = require('ioredis');

app.http('track-visit', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {

        context.log('===== TRACK VISIT =====');

        try {
            const redis = new Redis({
                host: process.env.REDIS_HOST,
                port: Number(process.env.REDIS_PORT || 10000),
                password: process.env.REDIS_PASSWORD,
                tls: {}
            });

            const count = await redis.incr('web:visits');

            await redis.quit();

            context.log(`Website visits: ${count}`);

            return {
                status: 200,
                jsonBody: {
                    success: true,
                    visits: count
                }
            };

        } catch (error) {

            context.log('Redis error:', error.message);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: error.message
                }
            };
        }
    }
});