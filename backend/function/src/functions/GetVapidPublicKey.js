const { app } = require("@azure/functions");

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
        "Access-Control-Allow-Headers": "Content-Type"
    };
}

app.http("GetVapidPublicKey", {
    methods: ["GET", "OPTIONS"],
    authLevel: "anonymous",

    handler: async (request, context) => {
        const corsHeaders = getCorsHeaders(request);

        if (request.method === "OPTIONS") {
            return {
                status: 204,
                headers: corsHeaders || {}
            };
        }

        const publicKey = process.env.VAPID_PUBLIC_KEY;

        if (!publicKey) {
            context.error(
                "VAPID_PUBLIC_KEY is not configured."
            );
            return {
                status: 500,
                headers: corsHeaders || {},
                jsonBody: {
                    error:
                        "VAPID public key is not configured."
                }
            };
        }

        return {
            status: 200,
            headers: corsHeaders || {},
            jsonBody: {
                publicKey: publicKey
            }
        };
    }
});
