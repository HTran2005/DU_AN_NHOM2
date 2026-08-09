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

        context.extraOutputs.set(signalR, {
            target: 'newNotification',
            arguments: [data]
        });

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