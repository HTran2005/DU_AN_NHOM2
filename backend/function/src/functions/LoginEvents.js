const { app } = require('@azure/functions');
const { BlobServiceClient } = require('@azure/storage-blob');

// ======================================================
// GET /api/login-events  (anonymous - mở trực tiếp trên trình duyệt)
//
// Trả về lịch sử các lần đăng nhập dạng JSON:
//   {
//     "total": 3,
//     "events": [
//       { "status", "username", "email", "timestamp", "message" }, ...
//     ]
//   }
//
// Dữ liệu được đọc lại từ Blob Storage container "login-events"
// — do LoginEventHandler ghi khi nhận sự kiện LoginResult từ Event Grid.
// KHÔNG chứa password.
//
// Response codes:
//   200 - lấy danh sách thành công (kể cả khi chưa có event nào)
//   500 - lỗi server (thiếu cấu hình storage / lỗi đọc blob)
// ======================================================

const LOGIN_EVENTS_CONTAINER = 'login-events';
const DEFAULT_MAX_EVENTS = 200;

function getStorageConnectionString() {
    return (
        process.env.LOGIN_EVENT_STORAGE_CONNECTION_STRING ||
        process.env.VISIT_STORAGE_CONNECTION_STRING ||
        process.env.AzureWebJobsStorage ||
        ''
    );
}

app.http('getLoginEvents', {
    methods: ['GET', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'login-events',

    handler: async (request, context) => {
        if (request.method === 'OPTIONS') {
            return {
                status: 204,
                headers: corsHeaders()
            };
        }

        try {
            const connectionString = getStorageConnectionString();

            if (!connectionString) {
                context.log('❌ Storage connection string missing for login-events.');
                return {
                    status: 500,
                    headers: corsHeaders(),
                    jsonBody: {
                        success: false,
                        total: 0,
                        events: [],
                        error: 'Storage chưa được cấu hình.'
                    }
                };
            }

            const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
            const containerClient = blobServiceClient.getContainerClient(LOGIN_EVENTS_CONTAINER);

            const containerExists = await containerClient.exists();
            if (!containerExists) {
                return {
                    status: 200,
                    headers: corsHeaders(),
                    jsonBody: {
                        total: 0,
                        events: []
                    }
                };
            }

            const limit = parseLimit(request.url);
            const events = [];

            for await (const blob of containerClient.listBlobsFlat()) {
                if (events.length >= limit) {
                    break;
                }

                try {
                    const blockBlobClient = containerClient.getBlockBlobClient(blob.name);
                    const download = await blockBlobClient.download();
                    const content = await streamToString(download.readableStreamBody);
                    const record = JSON.parse(content);

                    events.push({
                        status: record.status || 'Unknown',
                        username: record.username || '',
                        email: record.email || '',
                        timestamp: record.timestamp || '',
                        message: record.message || ''
                    });
                } catch (parseError) {
                    context.log('⚠️ Bỏ qua blob không đọc được:', blob.name, parseError.message);
                }
            }

            // Mới nhất lên trước
            events.sort((a, b) => (a.timestamp < b.timestamp ? 1 : a.timestamp > b.timestamp ? -1 : 0));

            return {
                status: 200,
                headers: corsHeaders(),
                jsonBody: {
                    total: events.length,
                    events: events
                }
            };

        } catch (error) {
            context.log('❌ getLoginEvents error:', error.message);
            return {
                status: 500,
                headers: corsHeaders(),
                jsonBody: {
                    success: false,
                    total: 0,
                    events: [],
                    error: error.message
                }
            };
        }
    }
});

function parseLimit(url) {
    try {
        const n = parseInt(new URL(url).searchParams.get('limit') || '0', 10);
        return Number.isFinite(n) && n > 0 ? Math.min(n, DEFAULT_MAX_EVENTS) : DEFAULT_MAX_EVENTS;
    } catch {
        return DEFAULT_MAX_EVENTS;
    }
}

function corsHeaders() {
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    };
}

async function streamToString(readableStream) {
    const chunks = [];
    for await (const chunk of readableStream) {
        chunks.push(Buffer.from(chunk));
    }
    return Buffer.concat(chunks).toString('utf-8');
}