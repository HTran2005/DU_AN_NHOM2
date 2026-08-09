const DEFAULT_TITLE = "TripTo";
const DEFAULT_URL = "/frontend/user/TRANGCHU.html";

self.addEventListener("push", function (event) {
    let payload = {};

    if (event.data) {
        try {
            payload = event.data.json();
        } catch (error) {
            payload = { body: event.data.text() };
        }
    }

    const options = {};

    if (payload.body) {
        options.body = payload.body;
    }

    if (payload.icon) {
        options.icon = payload.icon;
    }

    if (payload.badge) {
        options.badge = payload.badge;
    }

    options.data = {
        url: payload.url || ""
    };

    event.waitUntil(
        self.registration.showNotification(
            payload.title || DEFAULT_TITLE,
            options
        )
    );
});

self.addEventListener("notificationclick", function (event) {
    event.notification.close();

    const url =
        event.notification.data &&
        event.notification.data.url
            ? event.notification.data.url
            : DEFAULT_URL;

    event.waitUntil(
        (async function () {
            const targetUrl = new URL(
                url,
                self.location.origin
            ).href;

            const clientsList =
                await self.clients.matchAll({
                    type: "window",
                    includeUncontrolled: true
                });

            for (const client of clientsList) {
                if ("focus" in client) {
                    try {
                        await client.navigate(targetUrl);
                    } catch (error) {}
                    return client.focus();
                }
            }

            return self.clients.openWindow(targetUrl);
        })()
    );
});
