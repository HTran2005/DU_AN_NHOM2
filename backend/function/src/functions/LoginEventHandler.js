const { app } = require('@azure/functions');
const { BlobServiceClient } = require('@azure/storage-blob');

// ======================================================
// LOGIN EVENT HANDLER
// Azure Event Grid -> LoginResult -> Function
//
// 1. Ghi log bằng chứng: status = Success | False
//    Invocation "Success" chỉ nghĩa là Function chạy xong,
//    KHÔNG phải đăng nhập thành công. Dùng data.status.
// 2. PERSIST event vào Blob Storage container "login-events"
//    ($LOGIN_EVENT_STORAGE_CONNECTION_STRING || $VISIT_STORAGE_CONNECTION_STRING)
//    để endpoint GET /api/login-events đọc lại được lịch sử đăng nhập.
//
// KHÔNG xử lý / lưu password hay token.
// ======================================================

const LOGIN_EVENTS_CONTAINER = 'login-events';

function getStorageConnectionString() {
    return (
        process.env.LOGIN_EVENT_STORAGE_CONNECTION_STRING ||
        process.env.VISIT_STORAGE_CONNECTION_STRING ||
        process.env.AzureWebJobsStorage ||
        ''
    );
}

// Chuẩn hoá + ghi 1 event vào Blob Storage (idempotent theo event id).
async function saveLoginEvent(singleEvent, context) {
    const data = singleEvent.data || {};

    const record = {
        status: data.status === 'Success' ? 'Success' : 'False',
        username: data.username || data.email || '',
        email: data.email || '',
        timestamp: data.timestamp || singleEvent.eventTime || new Date().toISOString(),
        message: data.message ||
            (data.status === 'Success' ? 'Đăng nhập thành công' : 'Đăng nhập thất bại')
    };

    const connectionString = getStorageConnectionString();
    if (!connectionString) {
        context.log(
            '❌ LOGIN_EVENT_STORAGE_CONNECTION_STRING / VISIT_STORAGE_CONNECTION_STRING missing. Event NOT persisted.'
        );
        return;
    }

    try {
        const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
        const containerClient = blobServiceClient.getContainerClient(LOGIN_EVENTS_CONTAINER);
        await containerClient.createIfNotExists();

        // Blob name gắn theo event id -> Event Grid redelivery (at-least-once)
        // ghi đè cùng blob, KHÔNG tạo bản duplicate.
        const eventId = singleEvent.id ||
            `${singleEvent.topic}-${singleEvent.eventTime}-${Math.random().toString(36).substring(2, 10)}`;
        const blobName = `${eventId}.json`;

        const blockBlobClient = containerClient.getBlockBlobClient(blobName);
        const body = JSON.stringify(record);
        await blockBlobClient.upload(body, Buffer.byteLength(body), {
            blobHTTPHeaders: {
                blobContentType: 'application/json'
            }
        });

        context.log(`✅ LOGIN EVENT PERSISTED: ${blobName} (status=${record.status})`);
    } catch (error) {
        context.log('❌ Failed to persist login event:', error.message);
    }
}

app.eventGrid('LoginEventHandler', {
    handler: async (event, context) => {
        const events = Array.isArray(event) ? event : [event];

        for (const singleEvent of events) {
            context.log('============================================');
            context.log('Event grid event received');
            context.log('Event type:', singleEvent.eventType);
            context.log('Subject:', singleEvent.subject);
            context.log('Event time:', singleEvent.eventTime);
            context.log('============================================');

            // Event Grid subscription validation
            if (
                singleEvent.eventType ===
                'Microsoft.EventGrid.SubscriptionValidationEvent'
            ) {
                context.log(
                    'Event Grid validation request received.',
                    singleEvent.data.validationCode
                );

                return {
                    status: 200,
                    jsonBody: {
                        validationResponse:
                            singleEvent.data.validationCode
                    }
                };
            }

            // Chỉ xử lý sự kiện đăng nhập của TripTo (LoginResult - dùng mới)
            // Giữ User.Login để tương thích với các event cũ đang chờ giao.
            if (
                singleEvent.eventType === 'LoginResult' ||
                singleEvent.eventType === 'User.Login'
            ) {
                const data = singleEvent.data || {};

                // LUÔN trả 200 cho Event Grid -> "Invocation Success/0" không
                // đồng nghĩa "Login thành công". Kết quả đăng nhập thực sự
                // nằm ở dòng LOGIN RESULT bên dưới.
                const loginSucceeded = data.status === 'Success';

                context.log('============================================');
                context.log('LOGIN RESULT =>', loginSucceeded ? 'SUCCESS' : 'FAILURE');
                context.log('============================================');
                context.log('[Login Event]');
                context.log('Status:', data.status);
                context.log('username:', data.username || data.email || '');
                context.log('email:', data.email || '');
                context.log('Time:', data.timestamp || singleEvent.eventTime);

                // Persist để endpoint GET /api/login-events đọc lại
                await saveLoginEvent(singleEvent, context);

                // Ghi custom telemetry lên Application Insights
                if (app.insights) {
                    app.insights.trackEvent({
                        name: 'LoginResult',
                        properties: {
                            status: data.status || 'Unknown',
                            username: data.username || data.email || '',
                            email: data.email || '',
                            eventTime: singleEvent.eventTime || ''
                        }
                    });
                }
            }
        }

        return { status: 200 };
    }
});