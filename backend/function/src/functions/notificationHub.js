const {
    NotificationHubsClient
} = require("@azure/notification-hubs");

const connectionString =
    process.env.NOTIFICATION_HUB_CONNECTION_STRING;

const hubName =
    process.env.NOTIFICATION_HUB_NAME || "tripto-hub";

if (!connectionString) {
    throw new Error(
        "NOTIFICATION_HUB_CONNECTION_STRING is not configured."
    );
}

const notificationHubClient =
    new NotificationHubsClient(
        connectionString,
        hubName
    );

module.exports = notificationHubClient;