const { app } = require("@azure/functions");
const { createNotificationHubClient } = require("./notificationHub");

const DEFAULT_ALLOWED_ORIGINS = [
    "https://bao-cao-nhom2-web-cxenh6f9emhxdbgp.southeastasia-01.azurewebsites.net",
    "https://bao-cao-nhom2-web2.azurewebsites.net",
    "https://bao-cao-nhom2-tm.trafficmanager.net",
    "http://localhost:8080"
];

const ALLOWED_ORIGINS = (
    process.env.CORS_ALLOWED_ORIGINS ||
    DEFAULT_ALLOWED_ORIGINS.join(",")
)
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

const INSTALLATION_ID_PATTERN = /^[A-Za-z0-9\-_:]{1,64}$/;

function getCorsHeaders(request) {
    const origin = request.headers.get("origin");

    if (!origin || !ALLOWED_ORIGINS.includes(origin)) {
        return null;
    }

    return {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type"
    };
}

app.http("RegisterNotification", {
    methods: ["POST", "OPTIONS"],
    authLevel: "anonymous",

    handler: async (request, context) => {
        const corsHeaders = getCorsHeaders(request);

        if (request.method === "OPTIONS") {
            return {
                status: 204,
                headers: corsHeaders || {}
            };
        }

        try {

            const body = await request.json();

            const {
                installationId,
                endpoint,
                p256dh,
                auth,
                userId
            } = body;

            if (
                typeof installationId !== "string" ||
                !INSTALLATION_ID_PATTERN.test(installationId)
            ) {
                return {
                    status: 400,
                    headers: corsHeaders || {},
                    jsonBody: {
                        success: false,
                        message:
                            "installationId must be 1-64 characters using A-Z a-z 0-9 - _ :."
                    }
                };
            }

            if (
                typeof endpoint !== "string" ||
                endpoint.trim() === "" ||
                typeof p256dh !== "string" ||
                p256dh.trim() === "" ||
                typeof auth !== "string" ||
                auth.trim() === ""
            ) {
                return {
                    status: 400,
                    headers: corsHeaders || {},
                    jsonBody: {
                        success: false,
                        message:
                            "endpoint, p256dh and auth must be non-empty strings."
                    }
                };
            }

            const client = createNotificationHubClient();
            if (!client) {
                return {
                    status: 500,
                    headers: corsHeaders || {},
                    jsonBody: {
                        success: false,
                        message:
                            "Notification hub connection string is not configured."
                    }
                };
            }

            const installation = {
                installationId: installationId,

                platform: "browser",

                pushChannel: {
                    endpoint: endpoint,
                    p256dh: p256dh,
                    auth: auth
                },

                tags: userId
                    ? [`user:${userId}`]
                    : []
            };

            await client.createOrUpdateInstallation(
                installation
            );

            return {
                status: 200,
                headers: corsHeaders || {},
                jsonBody: {
                    success: true,
                    installationId: installationId
                }
            };

        } catch (error) {

            context.error(
                "Notification registration error:",
                error
            );

            return {
                status: 500,
                headers: corsHeaders || {},
                jsonBody: {
                    success: false,
                    message:
                        "Failed to register browser."
                }
            };
        }
    }
});
