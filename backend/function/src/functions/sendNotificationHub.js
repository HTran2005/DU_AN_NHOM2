const { app } = require("@azure/functions");

const {
    NotificationHubsClient
} = require("@azure/notification-hubs");

const connectionString =
    process.env.NOTIFICATION_HUB_CONNECTION_STRING;

const hubName =
    process.env.NOTIFICATION_HUB_NAME || "tripto-hub";

const client =
    new NotificationHubsClient(
        connectionString,
        hubName
    );

app.http("SendNotificationHub", {
    methods: ["POST"],
    authLevel: "function",

    handler: async (request, context) => {

        try {

            const body = await request.json();

            const {
                title,
                message,
                tag
            } = body;

            const payload = JSON.stringify({
                title:
                    title ||
                    "TripTo",

                body:
                    message ||
                    "Bạn có thông báo mới."
            });

            const notification = {
                body: payload,

                headers: {
                    "ServiceBusNotification-Format":
                        "browser"
                }
            };

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
                jsonBody: {
                    success: true,
                    message:
                        "Notification sent.",
                    trackingId:
                        result.trackingId
                }
            };

        } catch (error) {

            context.error(
                "Notification sending error:",
                error
            );

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    message:
                        "Failed to send notification.",
                    error: error.message
                }
            };
        }
    }
});