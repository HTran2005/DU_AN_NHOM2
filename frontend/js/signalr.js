(async function initSignalR() {
    try {
        const connectionInfo = await fetch(
            'https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/negotiate',
            {
                method: 'POST'
            }
        );

        if (!connectionInfo.ok) {
            throw new Error('Không gọi được negotiate (HTTP ' + connectionInfo.status + ')');
        }

        const data = await connectionInfo.json();

        console.log('SignalR connection info:', data);

        const connection = new signalR.HubConnectionBuilder()
            .withUrl(data.url, {
                accessTokenFactory: () => data.accessToken
            })
            .withAutomaticReconnect()
            .build();

        connection.on('newNotification', (payload) => {
            console.log('Nhận notification:', payload);
        });

        await connection.start();

        console.log('SignalR connected!');
    } catch (error) {
        console.error('Lỗi SignalR:', error);
    }
})();