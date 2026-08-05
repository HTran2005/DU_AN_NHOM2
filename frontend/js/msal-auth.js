/**
 * =====================================================
 * MICROSOFT ENTRA ID LOGIN - MSAL.js
 * =====================================================
 * 
 * Tích hợp "Đăng nhập bằng Microsoft" vào modal đăng nhập Tripto.
 * - Tự chèn nút "Tiếp tục với Microsoft" vào #loginModal .social-buttons
 * - Popup đăng nhập bằng MSAL.js (không chuyển trang)
 * - Gửi id_token lên backend user.php (action=login_microsoft) để xác minh + tạo session
 * 
 * Yêu cầu: msal-config.js phải được tải TRƯỚC file này (định nghĩa window.MSAL_CONFIG)
 */

(function () {
    const MSAL_CDN = 'https://cdn.jsdelivr.net/npm/@azure/msal-browser@2.38.3/lib/msal-browser.min.js';

    // -----------------------------------------------------
    // Tải MSAL SDK động nếu chưa có
    // -----------------------------------------------------
    function loadMsalSdk() {
        return new Promise((resolve, reject) => {
            if (window.msal && window.msal.PublicClientApplication) {
                resolve(window.msal);
                return;
            }
            const script = document.createElement('script');
            script.src = MSAL_CDN;
            script.async = true;
            script.onload = () => resolve(window.msal);
            script.onerror = () => reject(new Error('Không tải được MSAL SDK'));
            document.head.appendChild(script);
        });
    }

    // -----------------------------------------------------
    // Lấy cấu hình từ msal-config.js
    // -----------------------------------------------------
    function getConfig() {
        return window.MSAL_CONFIG || null;
    }

    function configReady(cfg) {
        return cfg && cfg.clientId && cfg.clientId.indexOf('<') === -1;
    }

    // -----------------------------------------------------
    // Tạo/tái dùng instance MSAL (dùng chung cho init + login)
    // -----------------------------------------------------
    let msalInstance = null;

    async function getMsalInstance() {
        if (msalInstance) return msalInstance;
        const msalLib = await loadMsalSdk();
        const cfg = getConfig();

        // redirectUri mặc định = URL trang hiện tại (phải được đăng ký trong App Registration)
        const redirectUri = cfg.redirectUri && cfg.redirectUri.indexOf('<') === -1
            ? cfg.redirectUri
            : window.location.origin + window.location.pathname;

        msalInstance = new msalLib.PublicClientApplication({
            auth: {
                clientId: cfg.clientId,
                authority: cfg.authority || 'https://login.microsoftonline.com/common/v2.0',
                redirectUri: redirectUri
            },
            cache: { cacheLocation: 'sessionStorage', storeAuthStateInCookie: false }
        });
        return msalInstance;
    }

    // -----------------------------------------------------
    // Tạo nút "Tiếp tục với Microsoft"
    // -----------------------------------------------------
    function createMsButton() {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'btn-social-modal ms-login-btn';
        btn.id = 'msLoginBtn';
        btn.innerHTML =
            '<svg width="18" height="18" viewBox="0 0 21 21" xmlns="http://www.w3.org/2000/svg" style="vertical-align:middle;margin-right:8px;">' +
            '<rect x="1" y="1" width="9" height="9" fill="#f25022"/>' +
            '<rect x="11" y="1" width="9" height="9" fill="#7fba00"/>' +
            '<rect x="1" y="11" width="9" height="9" fill="#00a4ef"/>' +
            '<rect x="11" y="11" width="9" height="9" fill="#ffb900"/>' +
            '</svg>' +
            'Tiếp tục với Microsoft';
        return btn;
    }

    // -----------------------------------------------------
    // Xử lý đăng nhập Microsoft
    // -----------------------------------------------------
    async function handleMicrosoftLogin() {
        const cfg = getConfig();
        if (!configReady(cfg)) {
            alert('⚠️ Đăng nhập Microsoft chưa được cấu hình.\n\nVui lòng điền Client ID và Tenant ID trong file msal-config.js (xem hướng dẫn).');
            return;
        }

        const btn = document.getElementById('msLoginBtn');
        if (btn) {
            btn.disabled = true;
            btn.textContent = '⏳ Đang kết nối Microsoft...';
        }

        try {
            const msalInstance = await getMsalInstance();

            const loginRequest = { scopes: ['openid', 'profile', 'email'] };
            const response = await msalInstance.loginPopup(loginRequest);

            const idToken = response.idToken;
            if (!idToken) {
                throw new Error('Không nhận được id_token từ Microsoft');
            }

            // Gửi lên backend xác minh + tạo session.
            // Dùng đường dẫn tuyệt đối từ gốc web để tránh 404 do URL tương đối (../../) phụ thuộc cấp thư mục trang.
            const apiUrl = '/user.php?endpoint=auth&action=login_microsoft';
            const res = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ id_token: idToken })
            });

            const text = await res.text();
            let result;
            try {
                result = JSON.parse(text);
            } catch (e) {
                throw new Error('Server trả về dữ liệu không hợp lệ: ' + text.substring(0, 200));
            }

            if (result.success && result.user) {
                // Lưu phiên giống đăng nhập thường
                sessionStorage.setItem('triptoUser', JSON.stringify(result.user));
                sessionStorage.setItem('triptoLoggedIn', 'true');

                // Cập nhật UI
                if (window.triptoAuth && typeof window.triptoAuth.setLoginData === 'function') {
                    window.triptoAuth.setLoginData(result.user);
                } else {
                    window.dispatchEvent(new CustomEvent('userLogin', { detail: result.user }));
                }

                // Đóng modal
                const modal = document.getElementById('loginModal');
                if (modal) {
                    modal.classList.remove('active');
                    document.body.style.overflow = '';
                }

                alert('✅ ' + (result.message || 'Đăng nhập thành công!') + '\n\nChào mừng ' + result.user.ho_ten + '!');
                setTimeout(() => location.reload(), 1000);
            } else {
                throw new Error(result.message || 'Đăng nhập Microsoft thất bại');
            }
        } catch (error) {
            console.error('❌ Lỗi đăng nhập Microsoft:', error);
            // Bỏ qua lỗi người dùng hủy popup
            if (error && error.name === 'ClientAuthError' && error.message && error.message.indexOf('User cancelled') !== -1) {
                return;
            }
            if (error && error.name === 'InteractionInProgressError') {
                alert('⏳ Một phiên đăng nhập Microsoft đang diễn ra. Vui lòng đợi và thử lại.');
                return;
            }
            alert('❌ Đăng nhập Microsoft thất bại:\n\n' + (error.message || 'Không xác định'));
        } finally {
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = createMsButton().innerHTML;
            }
        }
    }

    // -----------------------------------------------------
    // Chèn nút vào tất cả modal đăng nhập trên trang
    // -----------------------------------------------------
    function injectButtons() {
        const containers = document.querySelectorAll('#loginModal .social-buttons');
        containers.forEach(container => {
            if (container.querySelector('.ms-login-btn')) return;
            const btn = createMsButton();
            btn.addEventListener('click', handleMicrosoftLogin);
            container.appendChild(btn);
        });
    }

    // Khởi tạo khi DOM sẵn sàng
    async function init() {
        const cfg = getConfig();
        if (configReady(cfg)) {
            try {
                const msalInstance = await getMsalInstance();
                await msalInstance.handleRedirectPromise();
            } catch (e) {
                console.error('❌ Lỗi khởi tạo MSAL:', e);
            }
        }
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', injectButtons);
        } else {
            injectButtons();
        }
    }

    // Cho phép gọi thủ công từ console / các trang khác
    window.triptoMsLogin = handleMicrosoftLogin;

    init();
})();
