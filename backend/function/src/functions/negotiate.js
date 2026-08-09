const { app, input } = require('@azure/functions');

const inputSignalR = input.generic({
    type: 'signalRConnectionInfo',
    name: 'connectionInfo',
    hubName: 'triptoHub',
    connectionStringSetting: 'AzureSignalRConnectionString',
});

app.http('negotiate', {
    methods: ['POST', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'negotiate',
    extraInputs: [inputSignalR],

    handler: async (request, context) => {
        const connectionInfo =
            context.extraInputs.get(inputSignalR);

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(connectionInfo)
        };
    }
});