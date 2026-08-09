const { app } = require("@azure/functions");
const { createNotificationHubClient } = require("./notificationHub");

app.http("RegisterNotification", {
    methods: ["POST"],
    authLevel: "anonymous",

    handler: async (request, context) => {
        const client = createNotificationHubClient();
        if (!client) {
            return {
                status: 500,
                jsonBody: {
                    success: false,
                    message:
                        "Notification hub connection string is not configured."
                }
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
                !installationId ||
                !endpoint ||
                !p256dh ||
                !auth
            ) {
                return {
                    status: 400,
                    jsonBody: {
                        success: false,
                        message:
                            "Missing browser push subscription data."
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
                jsonBody: {
                    success: true,
                    message:
                        "Browser registered successfully.",
                    installationId:
                        installationId
                }
            };

        } catch (error) {

            context.error(
                "Notification registration error:",
                error
            );

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    message:
                        "Failed to register browser.",
                    error: error.message
                }
            };
        }
    }
});