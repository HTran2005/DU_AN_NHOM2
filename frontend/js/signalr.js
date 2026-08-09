const connectionInfo = await fetch(
    'https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/negotiate',
    {
        method: 'POST'
    }
);

const data = await connectionInfo.json();

console.log('SignalR connection info:', data);