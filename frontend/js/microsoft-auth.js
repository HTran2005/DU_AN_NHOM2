/**
 * Microsoft Entra ID Authentication Library
 * Đăng nhập bằng tài khoản Microsoft (MSAL.js 2.x)
 *
 * Yêu cầu cấu hình trên Azure Portal (Entra ID → App registrations):
 *   1. Tạo App Registration, Redirect URI loại SPA (vd: http://localhost:8080/frontend/user/TRANGCHU.html)
 *   2. Tích "Allow public client flows"
 *   3. Điền Client ID vào MicrosoftAuthConfig.clientId bên dưới
 */

const MicrosoftAuthConfig = {
    clientId: '3e2d9308-3417-468d-a85a-6f6975c0da90',
    tenantId: 'common',
    redirectUri: window.location.origin,
    msalCdn: 'https://alcdn.msauth.net/browser/2.38.2/js/msal-browser.min.js'
};

class MicrosoftAuth {
    constructor(config) {
        this.config = config;
        this.authority = 'https://login.microsoftonline.com/' + config.tenantId;
        this.msalInstance = null;
        this.msalLoaded = false;
        this.msalLoading = null;
    }

    /**
     * Tải MSAL.js từ CDN (tải 1 lần duy nhất)
     */
    loadMsal() {
        if (this.msalLoaded) return Promise.resolve(true);
        if (this.msalLoading) return this.msalLoading;

        this.msalLoading = new Promise((resolve, reject) => {
            if (window.msal && window.msal.PublicClientApplication) {
                this.msalLoaded = true;
                return resolve(true);
            }

            const script = document.createElement('script');
            script.src = this.config.msalCdn;
            script.async = true;
            script.onload = () => {
                this.msalLoaded = true;
                resolve(true);
            };
            script.onerror = () => {
                console.error('Không thể tải MSAL.js từ CDN');
                reject(new Error('Không thể tải MSAL.js'));
            };
            document.head.appendChild(script);
        });

        return this.msalLoading;
    }

    /**
     * Khởi tạo PublicClientApplication
     */
    getInstance() {
        if (this.msalInstance) return this.msalInstance;

        this.msalInstance = new msal.PublicClientApplication({
            auth: {
                clientId: this.config.clientId,
                authority: this.authority,
                redirectUri: this.config.redirectUri || window.location.origin
            },
            cache: {
                cacheLocation: 'localStorage',
                storeAuthStateInCookie: true
            }
        });

        return this.msalInstance;
    }

    /**
     * Chèn nút "Đăng nhập bằng Microsoft" vào mọi khối .social-buttons
     */
    injectButtons() {
        const containers = document.querySelectorAll('.social-buttons');
        containers.forEach((container) => {
            if (container.querySelector('.btn-microsoft-login')) return;

            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'btn-social-modal btn-microsoft-login';
            btn.innerHTML = '<svg width="18" height="18" viewBox="0 0 23 23" aria-hidden="true" style="vertical-align:middle"><path fill="#f35325" d="M0 0h11v11H0z"/><path fill="#81bc06" d="M12 0h11v11H12z"/><path fill="#05a6f0" d="M0 12h11v11H0z"/><path fill="#ffba08" d="M12 12h11v11H12z"/></svg> Tiếp tục với Microsoft';
            btn.addEventListener('click', () => this.login());

            container.appendChild(btn);
        });
    }

    /**
     * Đăng nhập bằng popup MSAL → gửi ID token cho backend
     */
    async login() {
        try {
            await this.loadMsal();
            const msalInstance = this.getInstance();

            const result = await msalInstance.loginPopup({
                scopes: ['openid', 'profile', 'email'],
                prompt: 'select_account'
            });

            const idToken = result.idToken;
            if (!idToken) {
                alert('❌ Không nhận được ID token từ Microsoft');
                return;
            }

            const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/backend/user.php?endpoint=auth&action=microsoft_login';
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ action: 'microsoft_login', id_token: idToken })
            });

            const data = await response.json();

            if (data.success) {
                const auth = window.triptoAuth || globalThis.triptoAuth;
                if (auth) {
                    auth.setLoginData(data.user);
                    auth.updateUI();
                } else {
                    console.warn('triptoAuth chưa sẵn sàng, gán sessionStorage thủ công');
                    sessionStorage.setItem('triptoLoggedIn', 'true');
                    sessionStorage.setItem('triptoUser', JSON.stringify(data.user));
                }

                alert('✅ ' + (data.message || 'Đăng nhập bằng Microsoft thành công!'));

                const loginModal = document.getElementById('loginModal');
                if (loginModal) {
                    loginModal.classList.remove('active');
                    document.body.style.overflow = '';
                }

                setTimeout(() => location.reload(), 1000);
            } else {
                alert('❌ Đăng nhập thất bại: ' + (data.message || 'Lỗi không xác định'));
            }
        } catch (error) {
            if (error && (error.errorCode === 'user_cancelled' || error.errorCode === 'access_denied')) {
                return;
            }
            console.error('Microsoft login error:', error);
            alert('❌ Không thể đăng nhập bằng Microsoft: ' + (error && error.message ? error.message : 'Lỗi không xác định'));
        }
    }

    /**
     * Khởi tạo: chèn nút sau khi DOM sẵn sàng
     */
    init() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.injectButtons());
        } else {
            this.injectButtons();
        }
    }
}

const microsoftAuth = new MicrosoftAuth(MicrosoftAuthConfig);
microsoftAuth.init();
