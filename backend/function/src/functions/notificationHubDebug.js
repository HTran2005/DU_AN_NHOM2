const { app } = require("@azure/functions");
const { createNotificationHubClient } = require("./notificationHub");

const DEFAULT_ALLOWED_ORIGINS = [
    "https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net",
    "https://tripto2-e3g2epfdaahzaqaa.southeastasia-01.azurewebsites.net",
    "https://tripto-tm.trafficmanager.net",
    "http://localhost:8080"
];

const ALLOWED_ORIGINS = (
    process.env.CORS_ALLOWED_ORIGINS ||
    DEFAULT_ALLOWED_ORIGINS.join(",")
)
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

function getCorsHeaders(request) {
    const origin = request.headers.get("origin");

    if (!origin || !ALLOWED_ORIGINS.includes(origin)) {
        return null;
    }

    return {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers":
            "Content-Type, x-functions-key"
    };
}

function jsonResponse(status, corsHeaders, body) {
    return {
        status: status,
        headers: corsHeaders || {},
        jsonBody: body
    };
}

function errorBody(error) {
    return String(
        error && error.message ? error.message : error
    );
}

app.http("NotificationHubDebugList", {
    methods: ["GET", "OPTIONS"],
    authLevel: "function",
    route: "NotificationHubDebug/installations",

    handler: async (request, context) => {
        const corsHeaders = getCorsHeaders(request);

        if (request.method === "OPTIONS") {
            return { status: 204, headers: corsHeaders || {} };
        }

        try {
            const client = createNotificationHubClient();
            if (!client) {
                return jsonResponse(500, corsHeaders, {
                    success: false,
                    message:
                        "Notification hub connection string is not configured."
                });
            }

            const registrations = [];
            const iter = client.listRegistrations({ top: 100 });

            for await (const registration of iter) {
                registrations.push({
                    registrationId: registration.registrationId,
                    kind: registration.kind,
                    endpoint: registration.endpoint || null,
                    p256dh: registration.p256dh || null,
                    auth: registration.auth || null,
                    tags: registration.tags || [],
                    expirationTime:
                        registration.expirationTime || null,
                    etag: registration.etag || null
                });
            }

            return jsonResponse(200, corsHeaders, {
                success: true,
                count: registrations.length,
                registrations: registrations
            });
        } catch (error) {
            context.error(
                "NotificationHubDebug list error:",
                error
            );
            return jsonResponse(500, corsHeaders, {
                success: false,
                message: "Failed to list registrations.",
                error: errorBody(error)
            });
        }
    }
});

app.http("NotificationHubDebugInstallation", {
    methods: ["GET", "OPTIONS"],
    authLevel: "function",
    route: "NotificationHubDebug/installation/{installationId}",

    handler: async (request, context) => {
        const corsHeaders = getCorsHeaders(request);

        if (request.method === "OPTIONS") {
            return { status: 204, headers: corsHeaders || {} };
        }

        try {
            const client = createNotificationHubClient();
            if (!client) {
                return jsonResponse(500, corsHeaders, {
                    success: false,
                    message:
                        "Notification hub connection string is not configured."
                });
            }

            const installationId = request.params.installationId;
            const installation = await client.getInstallation(
                installationId
            );

            return jsonResponse(200, corsHeaders, {
                success: true,
                installation: installation
            });
        } catch (error) {
            context.error(
                "NotificationHubDebug installation error:",
                error
            );
            return jsonResponse(500, corsHeaders, {
                success: false,
                message: "Failed to get installation.",
                error: errorBody(error)
            });
        }
    }
});

app.http("NotificationHubDebugOutcome", {
    methods: ["GET", "OPTIONS"],
    authLevel: "function",
    route: "NotificationHubDebug/outcome",

    handler: async (request, context) => {
        const corsHeaders = getCorsHeaders(request);

        if (request.method === "OPTIONS") {
            return { status: 204, headers: corsHeaders || {} };
        }

        try {
            const client = createNotificationHubClient();
            if (!client) {
                return jsonResponse(500, corsHeaders, {
                    success: false,
                    message:
                        "Notification hub connection string is not configured."
                });
            }

            const url = new URL(request.url);
            const trackingId = url.searchParams.get("trackingId");

            if (!trackingId) {
                return jsonResponse(400, corsHeaders, {
                    success: false,
                    message:
                        "trackingId query parameter is required."
                });
            }

            const details = await client.getNotificationOutcomeDetails(
                trackingId
            );

            return jsonResponse(200, corsHeaders, {
                success: true,
                trackingId: trackingId,
                details: details
            });
        } catch (error) {
            context.error(
                "NotificationHubDebug outcome error:",
                error
            );
            return jsonResponse(500, corsHeaders, {
                success: false,
                message:
                    "Failed to get notification outcome. This API requires a Standard SKU notification hub.",
                error: errorBody(error)
            });
        }
    }
});
