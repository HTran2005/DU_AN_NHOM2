const { app } = require('@azure/functions');
const { BlobServiceClient } = require('@azure/storage-blob');
const { createClient } = require('redis');


// ======================================================
// REDIS
// ======================================================

let redisClient = null;

async function getRedisClient(context) {
    if (redisClient && redisClient.isReady) {
        return redisClient;
    }

    const host = process.env.REDIS_HOST;
    const port = process.env.REDIS_PORT || '10000';
    const password = process.env.REDIS_PASSWORD;

    if (!host || !password) {
        throw new Error('REDIS_HOST hoặc REDIS_PASSWORD chưa được cấu hình.');
    }

    redisClient = createClient({
        socket: {
            host: host,
            port: Number(port),
            tls: true
        },
        password: password
    });

    redisClient.on('error', (error) => {
        console.error('Redis error:', error.message);
    });

    await redisClient.connect();

    context.log('✅ Redis connected.');

    return redisClient;
}


// ======================================================
// 1. EVENT GRID
// Blob → Event Grid → BlobEventHandler
// ======================================================

app.eventGrid('BlobEventHandler', {
    handler: async (event, context) => {

        context.log('=================================');
        context.log('📦 EVENT GRID EVENT RECEIVED');
        context.log('=================================');

        const events = Array.isArray(event) ? event : [event];

        for (const singleEvent of events) {

            context.log('Event type:', singleEvent.eventType);
            context.log('Subject:', singleEvent.subject);
            context.log('Event time:', singleEvent.eventTime);

            // Event Grid validation
            if (
                singleEvent.eventType ===
                'Microsoft.EventGrid.SubscriptionValidationEvent'
            ) {
                context.log('Event Grid validation request received.');

                return {
                    status: 200,
                    jsonBody: {
                        validationResponse:
                            singleEvent.data.validationCode
                    }
                };
            }


            // Chỉ xử lý BlobCreated
            if (
                singleEvent.eventType ===
                'Microsoft.Storage.BlobCreated'
            ) {

                context.log('✅ BLOB CREATED');

                const subject = singleEvent.subject || '';

                context.log('Subject:', subject);


                // ==================================================
                // CHỈ ĐẾM BLOB TRONG CONTAINER web-visits
                // ==================================================

                if (!subject.includes('/containers/web-visits/')) {

                    context.log(
                        'ℹ️ Không phải web-visits. Không tăng lượt.'
                    );

                    continue;
                }


                // ==================================================
                // TĂNG REDIS
                // ==================================================

                try {

                    const redis = await getRedisClient(context);

                    const totalVisits = await redis.incr(
                        'tripto:visits:total'
                    );

                    context.log(
                        `🌐 WEB VISIT DETECTED`
                    );

                    context.log(
                        `🌐 TOTAL VISITS: ${totalVisits}`
                    );

                } catch (error) {

                    context.log(
                        '❌ Redis update failed:',
                        error.message
                    );
                }
            }
        }

        context.log('=================================');
    }
});


// ======================================================
// 2. WEBSITE → TẠO VISIT BLOB
// ======================================================

app.http('trackVisit', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'track-visit',

    handler: async (request, context) => {

        context.log('🌐 trackVisit called.');

        try {

            const connectionString =
                process.env.VISIT_STORAGE_CONNECTION_STRING;

            if (!connectionString) {

                context.log(
                    '❌ VISIT_STORAGE_CONNECTION_STRING missing.'
                );

                return {
                    status: 500,
                    jsonBody: {
                        success: false,
                        error: 'Storage connection string chưa cấu hình.'
                    }
                };
            }


            const blobServiceClient =
                BlobServiceClient.fromConnectionString(
                    connectionString
                );

            const containerClient =
                blobServiceClient.getContainerClient(
                    'web-visits'
                );


            await containerClient.createIfNotExists();


            // Tạo tên Blob duy nhất
            const blobName =
                `${Date.now()}-${Math.random()
                    .toString(36)
                    .substring(2, 10)}.json`;


            const blockBlobClient =
                containerClient.getBlockBlobClient(
                    blobName
                );


            const visitData = JSON.stringify({
                timestamp: new Date().toISOString(),
                userAgent:
                    request.headers.get('user-agent') || '',
                referer:
                    request.headers.get('referer') || ''
            });


            await blockBlobClient.upload(
                visitData,
                Buffer.byteLength(visitData),
                {
                    blobHTTPHeaders: {
                        blobContentType: 'application/json'
                    }
                }
            );


            context.log(
                `✅ VISIT BLOB CREATED: ${blobName}`
            );


            return {
                status: 200,
                jsonBody: {
                    success: true,
                    message: 'Visit recorded.'
                }
            };

        } catch (error) {

            context.log(
                '❌ trackVisit error:',
                error.message
            );

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


// ======================================================
// 3. WEBSITE → LẤY TỔNG SỐ LƯỢT
// ======================================================

app.http('getVisits', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'visits',

    handler: async (request, context) => {

        try {

            const redis = await getRedisClient(context);

            const total =
                await redis.get(
                    'tripto:visits:total'
                );

            return {
                status: 200,
                jsonBody: {
                    totalVisits: Number(total || 0)
                }
            };

        } catch (error) {

            context.log(
                '❌ getVisits error:',
                error.message
            );

            return {
                status: 500,
                jsonBody: {
                    totalVisits: 0,
                    error: error.message
                }
            };
        }
    }
});