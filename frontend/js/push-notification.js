(function () {
    const FUNCTION_APP_URL =
        "https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net";
    const SW_PATH = "/sw.js";
    const INSTALLATION_ID_KEY =
        "tripto_notification_installation_id";
    const INSTALLATION_ID_PATTERN =
        /^[A-Za-z0-9\-_:]{1,64}$/;

    function isPushSupported() {
        return (
            "serviceWorker" in navigator &&
            "PushManager" in window &&
            "Notification" in window
        );
    }

    function urlBase64ToUint8Array(base64UrlString) {
        const padding = "=".repeat(
            (4 - (base64UrlString.length % 4)) % 4
        );

        const base64 = (base64UrlString + padding)
            .replace(/-/g, "+")
            .replace(/_/g, "/");

        const rawData = window.atob(base64);

        const outputArray = new Uint8Array(rawData.length);

        for (let i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i);
        }

        return outputArray;
    }

    function arrayBufferToBase64Url(buffer) {
        const bytes = new Uint8Array(buffer);

        let binary = "";

        for (let i = 0; i < bytes.length; ++i) {
            binary += String.fromCharCode(bytes[i]);
        }

        return window
            .btoa(binary)
            .replace(/\+/g, "-")
            .replace(/\//g, "_")
            .replace(/=+$/, "");
    }

    function generateInstallationId() {
        if (
            window.crypto &&
            typeof window.crypto.randomUUID === "function"
        ) {
            return window.crypto.randomUUID();
        }

        const randomBytes = new Uint8Array(16);
        window.crypto.getRandomValues(randomBytes);

        let hex = "";

        for (let i = 0; i < randomBytes.length; ++i) {
            hex += randomBytes[i]
                .toString(16)
                .padStart(2, "0");
        }

        return hex;
    }

    function getOrCreateInstallationId() {
        const existing = window.localStorage.getItem(
            INSTALLATION_ID_KEY
        );

        if (
            existing &&
            INSTALLATION_ID_PATTERN.test(existing)
        ) {
            return existing;
        }

        const installationId = generateInstallationId();

        window.localStorage.setItem(
            INSTALLATION_ID_KEY,
            installationId
        );

        return installationId;
    }

    async function getVapidPublicKey() {
        try {
            const response = await fetch(
                FUNCTION_APP_URL + "/api/GetVapidPublicKey"
            );

            if (!response.ok) {
                console.error(
                    "Failed to fetch VAPID public key."
                );
                return null;
            }

            const data = await response.json();

            if (
                typeof data.publicKey !== "string" ||
                data.publicKey.trim() === ""
            ) {
                console.error(
                    "VAPID public key missing from response."
                );
                return null;
            }

            return data.publicKey;
        } catch (error) {
            console.error(
                "VAPID public key request failed.",
                error
            );
            return null;
        }
    }

    async function registerBrowserSubscription(
        subscriptionData
    ) {
        const installationId = getOrCreateInstallationId();

        const user =
            window.triptoAuth &&
            typeof window.triptoAuth.getUser === "function"
                ? window.triptoAuth.getUser()
                : null;

        const userId =
            user &&
            user.id !== undefined &&
            user.id !== null
                ? String(user.id)
                : "";

        const payload = {
            installationId: installationId,
            endpoint: subscriptionData.endpoint,
            p256dh: subscriptionData.p256dh,
            auth: subscriptionData.auth,
            userId: userId
        };

        try {
            const response = await fetch(
                FUNCTION_APP_URL + "/api/RegisterNotification",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(payload)
                }
            );

            if (!response.ok) {
                console.error(
                    "RegisterNotification request failed."
                );
                return null;
            }

            const data = await response.json();

            if (!data || data.success !== true) {
                console.error(
                    "RegisterNotification failed."
                );
                return null;
            }

            console.log(
                "Browser push registered successfully.",
                installationId
            );

            return {
                success: true,
                installationId: installationId
            };
        } catch (error) {
            console.error(
                "RegisterNotification request error.",
                error
            );
            return null;
        }
    }

    async function ensureFreshSubscription(
        registration,
        publicKey
    ) {
        let subscription =
            await registration.pushManager.getSubscription();

        if (subscription) {
            const currentKeyBytes =
                urlBase64ToUint8Array(publicKey);
            const existingKey =
                subscription.getKey("applicationServerKey");

            let keysMatch = false;

            if (existingKey) {
                const existingKeyBytes = new Uint8Array(
                    existingKey
                );

                keysMatch =
                    existingKeyBytes.length ===
                        currentKeyBytes.length &&
                    currentKeyBytes.every(function (
                        value,
                        index
                    ) {
                        return value === existingKeyBytes[index];
                    });
            }

            if (!keysMatch) {
                console.warn(
                    "Existing push subscription uses a different VAPID key. Re-subscribing."
                );
                await subscription.unsubscribe();
                subscription = null;
            }
        }

        if (!subscription) {
            subscription =
                await registration.pushManager.subscribe({
                    userVisibleOnly: true,
                    applicationServerKey:
                        urlBase64ToUint8Array(publicKey)
                });
        }

        return subscription;
    }

    async function initPushNotifications() {
        if (!isPushSupported()) {
            console.warn(
                "Browser does not support push notifications."
            );
            return null;
        }

        let registration;

        try {
            registration =
                await navigator.serviceWorker.register(SW_PATH);
            console.log(
                "Service worker registered with scope:",
                registration.scope
            );
        } catch (error) {
            console.error(
                "Service worker registration failed.",
                error
            );
            return null;
        }

        const permission =
            await Notification.requestPermission();

        if (permission !== "granted") {
            console.warn(
                "Notification permission is",
                permission,
                "- push notifications disabled."
            );
            return null;
        }

        const publicKey = await getVapidPublicKey();

        if (!publicKey) {
            return null;
        }

        let subscription;

        try {
            subscription = await ensureFreshSubscription(
                registration,
                publicKey
            );
            console.log(
                "Push subscription ready. Endpoint:",
                subscription.endpoint
            );
        } catch (error) {
            console.error(
                "Push subscription creation failed.",
                error
            );
            return null;
        }

        const p256dhKey = subscription.getKey("p256dh");
        const authKey = subscription.getKey("auth");

        if (!p256dhKey || !authKey) {
            console.error(
                "Push subscription keys are missing."
            );
            return null;
        }

        const registrationResult =
            await registerBrowserSubscription({
                endpoint: subscription.endpoint,
                p256dh: arrayBufferToBase64Url(p256dhKey),
                auth: arrayBufferToBase64Url(authKey)
            });

        return registrationResult;
    }

    async function getPushDebugInfo() {
        const info = {
            secureContext: window.isSecureContext,
            permission:
                "Notification" in window
                    ? Notification.permission
                    : "unsupported",
            serviceWorkerSupported:
                "serviceWorker" in navigator,
            serviceWorkerActive: false,
            subscription: null,
            installationId: getOrCreateInstallationId()
        };

        try {
            const registration =
                await navigator.serviceWorker.ready;

            info.serviceWorkerActive =
                registration.active &&
                registration.active.state === "activated";

            info.subscription =
                await registration.pushManager.getSubscription();
        } catch (error) {
            console.error(
                "getPushDebugInfo error.",
                error
            );
        }

        return info;
    }

    window.initPushNotifications = initPushNotifications;
    window.getPushDebugInfo = getPushDebugInfo;
    window.urlBase64ToUint8Array = urlBase64ToUint8Array;
    window.getOrCreateInstallationId =
        getOrCreateInstallationId;
})();
