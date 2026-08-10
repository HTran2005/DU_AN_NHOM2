(function initSignalR() {
    // CDN @microsoft/signalr phải được load TRƯỚC file này
    if (!window.signalR) {
        console.warn('SignalR client library chưa được load. Bỏ qua kết nối.');
        return;
    }

    // =============================================
    // TOAST UI - hiển thị notification realtime
    // =============================================
    function ensureToastContainer() {
        let container = document.getElementById('triptoToastContainer');
        if (!container) {
            container = document.createElement('div');
            container.id = 'triptoToastContainer';
            document.body.appendChild(container);
        }
        return container;
    }

    function injectToastStyles() {
        if (document.getElementById('triptoToastStyles')) return;

        const style = document.createElement('style');
        style.id = 'triptoToastStyles';
        style.textContent = `
            #triptoToastContainer {
                position: fixed;
                top: 20px;
                right: 20px;
                z-index: 100000;
                display: flex;
                flex-direction: column;
                gap: 12px;
                pointer-events: none;
            }
            .tripto-toast {
                pointer-events: auto;
                width: 360px;
                max-width: calc(100vw - 40px);
                background: #FFFFFF;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.16);
                padding: 16px;
                display: flex;
                gap: 14px;
                font-family: 'Roboto', Arial, sans-serif;
                border-left: 4px solid #049153;
                animation: triptoToastIn 0.35s ease;
                position: relative;
            }
            .tripto-toast.tripto-toast-leaving {
                animation: triptoToastOut 0.35s ease forwards;
            }
            .tripto-toast-icon {
                width: 42px;
                height: 42px;
                min-width: 42px;
                border-radius: 10px;
                background: rgba(4, 145, 83, 0.12);
                color: #049153;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 20px;
            }
            .tripto-toast-body {
                flex: 1;
                min-width: 0;
            }
            .tripto-toast-title {
                font-size: 15px;
                font-weight: 700;
                color: #121316;
                margin: 0 0 4px 0;
            }
            .tripto-toast-desc {
                font-size: 13px;
                color: #383E48;
                line-height: 1.45;
                margin: 0 0 6px 0;
            }
            .tripto-toast-meta {
                font-size: 12px;
                color: #737374;
                display: flex;
                flex-direction: column;
                gap: 2px;
            }
            .tripto-toast-price {
                font-size: 13px;
                font-weight: 700;
                color: #0057FF;
                margin-top: 4px;
            }
            .tripto-toast-close {
                position: absolute;
                top: 8px;
                right: 10px;
                background: none;
                border: none;
                color: #D7D7D7;
                font-size: 16px;
                cursor: pointer;
                padding: 2px 4px;
                line-height: 1;
                transition: color 0.2s ease;
            }
            .tripto-toast-close:hover {
                color: #121316;
            }
            @keyframes triptoToastIn {
                from { opacity: 0; transform: translateX(40px); }
                to { opacity: 1; transform: translateX(0); }
            }
            @keyframes triptoToastOut {
                from { opacity: 1; transform: translateX(0); }
                to { opacity: 0; transform: translateX(40px); }
            }
        `;
        document.head.appendChild(style);
    }

    function formatVnd(amount) {
        const num = Number(amount || 0);
        return num.toLocaleString('vi-VN') + ' VNĐ';
    }

    function showBookingToast(payload) {
        injectToastStyles();

        const title = payload.title || 'Đặt tour thành công!';
        const bookingCode = payload.bookingCode || '';
        const tourName = payload.tourName || '';
        const departDate = payload.departDate || '';

        const descLines = [payload.message || ('Đặt tour ' + bookingCode + ' thành công.')];
        if (tourName) descLines.push('Tour: ' + tourName);
        if (departDate) descLines.push('Ngày khởi hành: ' + departDate);

        const toast = document.createElement('div');
        toast.className = 'tripto-toast';
        toast.innerHTML = `
            <div class="tripto-toast-icon"><i class="fas fa-circle-check"></i></div>
            <div class="tripto-toast-body">
                <p class="tripto-toast-title"></p>
                <div class="tripto-toast-meta"></div>
                <div class="tripto-toast-price"></div>
            </div>
            <button class="tripto-toast-close" aria-label="Đóng">&times;</button>
        `;
        toast.querySelector('.tripto-toast-title').textContent = title;

        const meta = toast.querySelector('.tripto-toast-meta');
        descLines.forEach(function (line) {
            const p = document.createElement('p');
            p.className = 'tripto-toast-desc';
            p.textContent = line;
            meta.appendChild(p);
        });

        if (payload.totalPrice !== undefined && payload.totalPrice !== null) {
            toast.querySelector('.tripto-toast-price').textContent = 'Tổng tiền: ' + formatVnd(payload.totalPrice);
        }

        const closeBtn = toast.querySelector('.tripto-toast-close');
        let dismissed = false;

        function dismiss() {
            if (dismissed) return;
            dismissed = true;
            toast.classList.add('tripto-toast-leaving');
            setTimeout(function () {
                toast.remove();
            }, 350);
        }

        closeBtn.addEventListener('click', dismiss);

        const container = ensureToastContainer();
        container.appendChild(toast);

        // Tự động biến mất sau 5 giây
        setTimeout(dismiss, 5000);
    }

    function handleNotification(payload) {
        console.log('Nhận notification:', payload);

        if (!payload || typeof payload !== 'object') return;

        if (payload.type === 'booking_success') {
            showBookingToast(payload);
        }
    }

    // =============================================
    // KẾT NỐI SIGNALR
    // =============================================
    async function connect() {
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

            connection.on('newNotification', handleNotification);

            await connection.start();

            console.log('SignalR connected!');
        } catch (error) {
            console.error('Lỗi SignalR:', error);
        }
    }

    connect();
})();
