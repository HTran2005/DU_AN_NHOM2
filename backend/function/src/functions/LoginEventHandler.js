const { app } = require('@azure/functions');

// ======================================================
// LOGIN EVENT HANDLER
// Azure Event Grid -> User.Login -> Function
// Ghi log bằng chứng: status = Success | False
// KHÔNG xử lý / lưu password hay token.
// ======================================================

app.eventGrid('LoginEventHandler', {
    handler: async (event, context) => {
        const events = Array.isArray(event) ? event : [event];

        for (const singleEvent of events) {
            context.log('============================================');
            context.log('Event grid event received');
            context.log('Event type:', singleEvent.eventType);
            context.log('Subject:', singleEvent.subject);
            context.log('Event time:', singleEvent.eventTime);
            context.log('============================================');

            // Event Grid subscription validation
            if (
                singleEvent.eventType ===
                'Microsoft.EventGrid.SubscriptionValidationEvent'
            ) {
                context.log(
                    'Event Grid validation request received.',
                    singleEvent.data.validationCode
                );

                return {
                    status: 200,
                    jsonBody: {
                        validationResponse:
                            singleEvent.data.validationCode
                    }
                };
            }

            // Chỉ xử lý sự kiện đăng nhập của TripTo
            if (singleEvent.eventType === 'User.Login') {
                const data = singleEvent.data || {};

                // LUÔN trả 200 cho Event Grid -> "Invocation Success/0" không
                // đồng nghĩa "Login thành công". Kết quả đăng nhập thực sự
                // nằm ở dòng LOGIN RESULT bên dưới.
                const loginSucceeded = data.status === 'Success';

                context.log('============================================');
                context.log('LOGIN RESULT =>', loginSucceeded ? 'SUCCESS' : 'FAILURE');
                context.log('============================================');
                context.log('[Login Event]');
                context.log('Status:', data.status);
                context.log('loginMethod:', data.loginMethod || 'username_or_email');
                if (data.userId !== undefined) {
                    context.log('userId:', data.userId);
                }
                if (data.email) {
                    context.log('email:', data.email);
                }
                if (data.reason) {
                    context.log('reason:', data.reason);
                }
                context.log('Time:', data.timestamp || singleEvent.eventTime);

                // Ghi custom telemetry lên Application Insights
                if (app.insights) {
                    app.insights.trackEvent({
                        name: 'User.Login',
                        properties: {
                            status: data.status || 'Unknown',
                            loginMethod: data.loginMethod || 'username_or_email',
                            userId: data.userId !== undefined ? String(data.userId) : '',
                            email: data.email || '',
                            reason: data.reason || '',
                            eventTime: singleEvent.eventTime || ''
                        }
                    });
                }
            }
        }

        return { status: 200 };
    }
});
