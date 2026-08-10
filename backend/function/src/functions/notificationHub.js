const {
    NotificationHubsClient
} = require("@azure/notification-hubs");

function createNotificationHubClient() {
    const connectionString =
        process.env.NOTIFICATION_HUB_CONNECTION_STRING;

    const hubName =
        process.env.NOTIFICATION_HUB_NAME || "tripto-hub";

    if (!connectionString) {
        return null;
    }

    return new NotificationHubsClient(
        connectionString,
        hubName
    );
}

module.exports = {
    createNotificationHubClient
};
