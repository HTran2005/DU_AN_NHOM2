const { app, input } = require('@azure/functions');

const inputSignalR = input.generic({
    type: 'signalRConnectionInfo',
    name: 'connectionInfo',
    hubName: 'triptoHub',
    connectionStringSetting: 'AzureSignalRConnectionString',
    userId: '{query.userId}',
});

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
};

app.http('negotiate', {
    methods: ['POST', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'negotiate',
    extraInputs: [inputSignalR],

    handler: async (request, context) => {
        if (request.method === 'OPTIONS') {
            return {
                status: 204,
                headers: corsHeaders
            };
        }

        const connectionInfo =
            context.extraInputs.get(inputSignalR);

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                ...corsHeaders
            },
            body: JSON.stringify(connectionInfo)
        };
    }
});