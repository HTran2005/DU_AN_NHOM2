const { app, output } = require('@azure/functions');

const signalR = output.generic({
    type: 'signalR',
    name: 'signalR',
    hubName: 'triptoHub',
    connectionStringSetting: 'AzureSignalRConnectionString',
});

app.http('sendNotification', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'sendNotification',
    extraOutputs: [signalR],

    handler: async (request, context) => {

        const data = await request.json();

        const signalRMessage = {
            target: 'newNotification',
            arguments: [data]
        };

        if (
            data &&
            typeof data.userId === 'string' &&
            data.userId !== ''
        ) {
            signalRMessage.userId = data.userId;
        }

        context.extraOutputs.set(signalR, signalRMessage);

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                success: true,
                message: 'Notification sent through SignalR'
            })
        };
    }
});