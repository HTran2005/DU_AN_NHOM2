const DEFAULT_TITLE = "TripTo";
const DEFAULT_URL = "/frontend/user/TRANGCHU.html";

async function notifyClientsOfPermissionIssue() {
    try {
        const clientsList = await self.clients.matchAll({
            type: "window",
            includeUncontrolled: true
        });

        const message = {
            type: "TRIPTO_PUSH_PERMISSION_MISSING",
            origin: self.location.origin
        };

        for (const client of clientsList) {
            client.postMessage(message);
        }
    } catch (error) {}
}

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

    const title = payload.title || DEFAULT_TITLE;

    console.log(
        "[sw] push received:",
        title,
        options.body || ""
    );

    event.waitUntil(
        self.registration
            .showNotification(title, options)
            .catch(function (error) {
                console.error(
                    "[sw] showNotification failed:",
                    error
                );
                notifyClientsOfPermissionIssue();
            })
    );
});

self.addEventListener("pushsubscriptionchange", function (event) {
    console.warn(
        "[sw] Push subscription changed; re-subscription will happen on next page load."
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
