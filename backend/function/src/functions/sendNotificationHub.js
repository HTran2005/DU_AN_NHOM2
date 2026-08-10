const { app } = require("@azure/functions");
const {
    createNotificationHubClient
} = require("./notificationHub");
const {
    createBrowserNotification
} = require("@azure/notification-hubs");

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
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
            "Content-Type, x-functions-key"
    };
}

app.http("SendNotificationHub", {
    methods: ["POST", "OPTIONS"],
    authLevel: "function",

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

            const title = body.title;
            const message = body.body || body.message;
            const tag = body.tag;

            if (
                typeof title !== "string" ||
                title.trim() === "" ||
                typeof message !== "string" ||
                message.trim() === ""
            ) {
                return {
                    status: 400,
                    headers: corsHeaders || {},
                    jsonBody: {
                        success: false,
                        message:
                            "title and body must be non-empty strings."
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

            const notification = createBrowserNotification({
                body: {
                    title: title.trim(),
                    body: message.trim()
                }
            });

            const options = {};

            if (tag) {
                options.tagExpression = tag;
            }

            const result =
                await client.sendNotification(
                    notification,
                    options
                );

            return {
                status: 200,
                headers: corsHeaders || {},
                jsonBody: {
                    success: true,
                    message: "Notification sent.",
                    trackingId: result.trackingId
                }
            };

        } catch (error) {

            context.error(
                "Notification sending error:",
                error
            );

            return {
                status: 500,
                headers: corsHeaders || {},
                jsonBody: {
                    success: false,
                    message:
                        "Failed to send notification."
                }
            };
        }
    }
});
