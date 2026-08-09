const { app } = require('@azure/functions');
const mysql = require('mysql2/promise');

async function updateTourImageUrl(blobUrl, context) {
    const dbHost = process.env.DB_HOST;
    const dbUser = process.env.DB_USER;
    const dbPass = process.env.DB_PASS;
    const dbName = process.env.DB_NAME;

    if (!dbHost || !dbUser || !dbPass || !dbName) {
        context.log('MySQL env vars missing. Skipping tour image update.');
        return;
    }

    let blobName;
    try {
        const url = new URL(blobUrl);
        const pathParts = url.pathname.split('/').filter(Boolean);
        if (pathParts.length < 2) {
            context.log('Blob URL path format invalid:', url.pathname);
            return;
        }
        blobName = pathParts.slice(1).join('/');
    } catch (error) {
        context.log('Invalid blob URL:', error.message);
        return;
    }

    const likePattern = `%${blobName}`;

    let connection;
    try {
        connection = await mysql.createConnection({
            host: dbHost,
            user: dbUser,
            password: dbPass,
            database: dbName,
            ssl: { rejectUnauthorized: false }
        });

        const [result] = await connection.execute(
            `UPDATE tour SET url_anh_chinh = ? WHERE url_anh_chinh = ? OR url_anh_chinh LIKE ?`,
            [blobUrl, blobName, likePattern]
        );

        context.log(`Tour update completed. Rows affected: ${result.affectedRows}`);
    } catch (error) {
        context.log('MySQL update failed:', error.message);
    } finally {
        if (connection) {
            await connection.end();
        }
    }
}

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

            if (singleEvent.eventType === 'Microsoft.EventGrid.SubscriptionValidationEvent') {
                context.log('Event Grid validation request received.');
                return {
                    status: 200,
                    jsonBody: {
                        validationResponse: singleEvent.data.validationCode
                    }
                };
            }

            if (singleEvent.eventType === 'Microsoft.Storage.BlobCreated') {
                context.log('✅ BLOB CREATED');

                if (singleEvent.data) {
                    context.log('Blob URL:', singleEvent.data.url);
                    context.log('Content type:', singleEvent.data.contentType);
                    context.log('Size:', singleEvent.data.contentLength);
                    await updateTourImageUrl(singleEvent.data.url, context);
                }
            }
        }

        context.log('=================================');
    }
});