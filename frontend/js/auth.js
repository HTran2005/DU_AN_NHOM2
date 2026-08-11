/**
 * Authentication & Session Management Library
 * Quản lý phiên đăng nhập và hiển thị thông tin người dùng
 */

// ============================================================
// REQUIRED: send session cookie with every API fetch.
// Backend now identifies the user via $_SESSION (getCurrentUserId),
// NOT via the client-supplied userId. All requests to user.php must
// therefore send credentials:'include'. This wrapper covers every
// page because all of them load this auth.js.
// ============================================================
(function () {
    const __triptoOrigFetch = window.fetch;
    window.fetch = function (input, init) {
        init = init || {};
        let url = '';
        if (typeof input === 'string') {
            url = input;
        } else if (input && input.url) {
            url = input.url;
        }
        if (url.indexOf('tripto-api-management.azure-api.net/tripto/user.php') !== -1 && !init.credentials) {
            init.credentials = 'include';
        }
        return __triptoOrigFetch.call(this, input, init);
    };
})();

class TriptoAuth {
    constructor() {
        this.AUTH_KEY = 'triptoLoggedIn';
        this.USER_KEY = 'triptoUser';
        this.TOKEN_KEY = 'triptoToken';
        this.heartbeatInterval = null;
    }

    /**
     * Kiểm tra trạng thái đăng nhập
     */
    isLoggedIn() {
        return sessionStorage.getItem(this.AUTH_KEY) === 'true' && this.getUser() !== null;
    }

    /**
     * Lấy thông tin người dùng từ sessionStorage
     */
    getUser() {
        const userData = sessionStorage.getItem(this.USER_KEY);
        if (!userData) return null;
        try {
            return JSON.parse(userData);
        } catch (e) {
            console.error('Lỗi parse user data:', e);
            return null;
        }
    }

    /**
     * Lưu thông tin đăng nhập
     */
    setLoginData(userData) {
        sessionStorage.setItem(this.AUTH_KEY, 'true');
        sessionStorage.setItem(this.USER_KEY, JSON.stringify(userData));
        // Phát sự kiện để các trang khác biết user đã đăng nhập
        window.dispatchEvent(new CustomEvent('userLogin', { detail: userData }));
        // start heartbeat to refresh online status
        try { this.startHeartbeat(); } catch (e) { console.error('startHeartbeat error', e); }
    }

    /**
     * Đăng xuất
     */
    logout() {
        sessionStorage.removeItem(this.AUTH_KEY);
        sessionStorage.removeItem(this.USER_KEY);
        sessionStorage.removeItem(this.TOKEN_KEY);
        // Phát sự kiện để các trang khác biết user đã đăng xuất
        window.dispatchEvent(new CustomEvent('userLogout'));
        // stop heartbeat
        try { this.stopHeartbeat(); } catch (e) { }
        window.location.href = 'TRANGCHU.html';
    }

    /**
     * Gọi API đăng nhập
     */
    async login(email, password) {
        try {
            const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/user.php';
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                credentials: 'include',
                body: JSON.stringify({ action: 'login', email, password })
            });

            const result = await response.json();

            if (result.success) {
                // Lưu thông tin người dùng
                this.setLoginData(result.user);
                return { success: true, user: result.user, message: result.message };
            } else {
                return { success: false, message: result.message };
            }
        } catch (error) {
            console.error('Lỗi đăng nhập:', error);
            return { success: false, message: 'Lỗi kết nối đến server' };
        }
    }

    /**
     * Cập nhật UI với thông tin người dùng đã đăng nhập
     * Tìm và cập nhật tất cả các phần tử có class 'user-name' hoặc 'login-btn'
     */
    updateUI() {
        console.log('🔄 updateUI() called, isLoggedIn:', this.isLoggedIn());
        
        if (!this.isLoggedIn()) {
            console.log('❌ User not logged in, skipping UI update');
            return;
        }

        const user = this.getUser();
        console.log('👤 Current user:', user);
        if (!user) {
            console.log('❌ User data is null');
            return;
        }

        // Cập nhật nút đăng nhập với tên người dùng
        const loginBtn = document.getElementById('loginBtn');
        console.log('🔘 loginBtn element:', loginBtn);
        if (loginBtn) {
            const newText = '👤 ' + user.ho_ten;
            console.log('✏️ Updating loginBtn to:', newText);
            loginBtn.innerHTML = newText;
            loginBtn.classList.add('logged-in');
            loginBtn.style.cursor = 'pointer';
            loginBtn.onclick = (e) => {
                e.preventDefault();
                e.stopPropagation();
                // Nếu đã đăng nhập, click sẽ redirect tới myReviews.html
                window.location.href = 'myReviews.html';
            };
            console.log('✅ loginBtn updated successfully');
        }

        // Cập nhật tên người dùng trong sidebar
        const userNameElements = document.querySelectorAll('.user-name');
        if (userNameElements.length > 0) {
            userNameElements.forEach(element => {
                element.textContent = user.ho_ten;
            });
        }

        // Cập nhật trạng thái online nếu có phần tử hiển thị
        const statusElements = document.querySelectorAll('.user-online-status');
        if (statusElements.length > 0) {
            // Query backend for real online status
            (async () => {
                try {
                    const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/user.php?endpoint=online&action=status&user_id=' + encodeURIComponent(user.id);
                    const resp = await fetch(apiUrl, { credentials: 'include' });
                    const j = await resp.json();
                    const online = j && j.online;
                    statusElements.forEach(el => {
                        el.textContent = online ? '🟢 Đang online' : '⚪ Offline';
                        el.classList.toggle('online', !!online);
                    });
                } catch (e) {
                    console.error('Fetch online status failed', e);
                    statusElements.forEach(el => el.textContent = '⚪ Offline');
                }
            })();
        }

        // Cập nhật email nếu có
        const userEmailElements = document.querySelectorAll('.user-email');
        if (userEmailElements.length > 0) {
            userEmailElements.forEach(element => {
                element.textContent = user.email;
            });
        }

        // Cập nhật ID nếu cần
        const userIdElements = document.querySelectorAll('.user-id');
        if (userIdElements.length > 0) {
            userIdElements.forEach(element => {
                element.textContent = user.id;
            });
        }

        // 🖼️ Cập nhật avatar từ sessionStorage
        this.initializeAvatars();

        console.log('✅ UI cập nhật thành công với thông tin user:', user.ho_ten);
    }

    /**
     * Khởi tạo hiển thị avatar từ dữ liệu sessionStorage khi trang load
     */
    initializeAvatars() {
        const user = this.getUser();
        if (!user) return;

        // Lấy avatar URL từ user data - kiểm tra cả avatar và anh_dai_dien
        let avatarUrl = user.anh_dai_dien || user.avatar || '../image/avt_pr.jpg';
        
        console.log('🖼️ Initializing avatars');
        console.log('   - user.anh_dai_dien:', user.anh_dai_dien);
        console.log('   - user.avatar:', user.avatar);
        console.log('   - Final avatarUrl:', avatarUrl);
        
        // Hàm kiểm tra xem file có tồn tại không
        const checkAvatarExists = (url) => {
            return fetch(url, { method: 'HEAD' })
                .then(response => response.ok)
                .catch(() => false);
        };
        
        // Cập nhật tất cả avatar elements
        const avatars = document.querySelectorAll('.avatar');
        avatars.forEach(avatar => {
            if (avatar.tagName === 'IMG' || avatar.tagName === 'img') {
                // Trước tiên kiểm tra xem avatar có tồn tại không
                checkAvatarExists(avatarUrl).then(exists => {
                    if (exists) {
                        avatar.src = avatarUrl;
                        console.log('✅ Avatar exists and set to:', avatarUrl);
                    } else {
                        avatar.src = '../image/avt_pr.jpg';
                        console.log('⚠️ Avatar does not exist, using default');
                    }
                });
            }
        });

        // Cập nhật profile avatar nếu có
        const profileAvatar = document.getElementById('profileAvatar');
        if (profileAvatar) {
            checkAvatarExists(avatarUrl).then(exists => {
                if (exists) {
                    profileAvatar.src = avatarUrl;
                    console.log('✅ Profile avatar exists and set to:', avatarUrl);
                } else {
                    profileAvatar.src = '../image/avt_pr.jpg';
                    console.log('⚠️ Profile avatar does not exist, using default');
                }
            });
        }

        console.log('🖼️ Avatars initialization started');
    }

    /**
     * Cập nhật avatar ở tất cả các trang
     * Được gọi khi avatar được cập nhật ở bất kỳ trang nào
     */
    updateAvatarAcrossPages(avatarUrl) {
        console.log('🖼️ Updating avatar across all pages:', avatarUrl);
        
        // Cập nhật avatar trong sessionStorage
        const user = this.getUser();
        if (user) {
            user.anh_dai_dien = avatarUrl;
            sessionStorage.setItem(this.USER_KEY, JSON.stringify(user));
            console.log('💾 Avatar URL lưu vào sessionStorage:', avatarUrl);
        }
        
        // Cập nhật tất cả các phần tử avatar .avatar class
        const avatars = document.querySelectorAll('.avatar');
        avatars.forEach(avatar => {
            if (avatar.tagName === 'IMG' || avatar.tagName === 'img') {
                avatar.src = avatarUrl;
                console.log('✅ Updated sidebar avatar image:', avatar);
            }
        });

        // Cập nhật profile avatar (#profileAvatar)
        const profileAvatar = document.getElementById('profileAvatar');
        if (profileAvatar) {
            profileAvatar.src = avatarUrl;
            console.log('✅ Updated profile avatar image:', profileAvatar);
        }

        // Cập nhật [data-avatar] elements
        const dataAvatarElements = document.querySelectorAll('[data-avatar]');
        dataAvatarElements.forEach(el => {
            if (el.tagName === 'IMG' || el.tagName === 'img') {
                el.src = avatarUrl;
                console.log('✅ Updated data-avatar element:', el);
            }
        });
        
        // Cập nhật background-image của elements
        const avatarElements = document.querySelectorAll('[style*="background-image"]');
        avatarElements.forEach(el => {
            if (el.style.backgroundImage && (el.style.backgroundImage.includes('avatar') || el.style.backgroundImage.includes('avt'))) {
                el.style.backgroundImage = `url('${avatarUrl}')`;
                console.log('✅ Updated avatar background:', el);
            }
        });

        console.log('🖼️ Avatar updated successfully across all pages');
    }

    /**
     * Gắn sự kiện cho login form
     */
    attachLoginFormListener(formId = 'loginForm') {
        const loginForm = document.getElementById(formId) || document.querySelector(`#loginModal form[id="${formId}"]`);
        
        if (!loginForm) {
            console.warn('Không tìm thấy form đăng nhập:', formId);
            return;
        }

        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            // Lấy giá trị từ form
            const emailInput = loginForm.querySelector('input[name="email"], #loginEmail');
            const passwordInput = loginForm.querySelector('input[name="password"], #loginPassword');

            if (!emailInput || !passwordInput) {
                alert('❌ Lỗi: Không tìm thấy các trường nhập liệu');
                return;
            }

            const email = emailInput.value.trim();
            const password = passwordInput.value.trim();

            if (!email || !password) {
                alert('❌ Vui lòng nhập đầy đủ email và mật khẩu');
                return;
            }

            // Gọi hàm đăng nhập
            const result = await this.login(email, password);

            if (result.success) {
                alert('✅ ' + result.message + '\n\nChào mừng ' + result.user.ho_ten + '!');
                loginForm.reset();

                // Đóng modal
                const loginModal = document.getElementById('loginModal');
                if (loginModal) {
                    loginModal.classList.remove('active');
                    document.body.style.overflow = '';
                }

                // Cập nhật UI
                this.updateUI();

                // Redirect nếu cần
                setTimeout(() => {
                    // Có thể redirect đến trang profile hoặc giữ nguyên trang hiện tại
                    location.reload();
                }, 1000);
            } else {
                alert('❌ Đăng nhập thất bại: ' + result.message);
            }
        });
    }

    /**
     * Kiểm tra đăng nhập và redirect nếu chưa đăng nhập
     */
    requireLogin() {
        if (!this.isLoggedIn()) {
            alert('Vui lòng đăng nhập trước!');
            const loginBtn = document.getElementById('loginBtn');
            if (loginBtn) {
                loginBtn.click();
            }
            return false;
        }
        return true;
    }

    /**
     * Tải microsoft-auth.js để bổ sung nút "Đăng nhập bằng Microsoft"
     */
    loadMicrosoftAuth() {
        if (document.querySelector('script[data-microsoft-auth]')) return;

        const script = document.createElement('script');
        script.src = '../js/microsoft-auth.js';
        script.setAttribute('data-microsoft-auth', 'true');
        script.async = true;
        document.head.appendChild(script);
    }

    /**
     * Tải social-icons.js để thay logo Google/Facebook bằng SVG chính thức
     */
    loadSocialIcons() {
        if (document.querySelector('script[data-social-icons]')) return;

        const script = document.createElement('script');
        script.src = '../js/social-icons.js';
        script.setAttribute('data-social-icons', 'true');
        script.async = true;
        document.head.appendChild(script);
    }

    startHeartbeat() {
        if (this.heartbeatInterval) return; // already running
        // send immediate heartbeat
        this.sendHeartbeat();
        this.heartbeatInterval = setInterval(() => {
            this.sendHeartbeat();
        }, 30000);
    }

    stopHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }

    async sendHeartbeat() {
        if (!this.isLoggedIn()) return;
        try {
            const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/user.php?endpoint=online&action=heartbeat';
            await fetch(apiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify({ action: 'heartbeat' })
            });
        } catch (e) {
            console.error('Heartbeat failed', e);
        }
    }

    /**
     * Khởi tạo auth (nên gọi khi trang load)
     */
    init() {
        // Cập nhật UI ngay khi trang load
        this.updateUI();

        // Tải Microsoft Entra ID login (MSAL.js)
        this.loadMicrosoftAuth();

        // Lắng nghe sự kiện login từ các trang khác
        window.addEventListener('userLogin', (e) => {
            console.log('📢 Nhận sự kiện userLogin:', e.detail);
            this.updateUI();
        });

        // 🔥 Lắng nghe sự kiện cập nhật avatar từ các trang khác
        window.addEventListener('userAvatarUpdated', (e) => {
            console.log('📢 Nhận sự kiện userAvatarUpdated:', e.detail);
            if (e.detail && e.detail.avatar_url) {
                this.updateAvatarAcrossPages(e.detail.avatar_url);
                
                // Cập nhật thông tin user
                const user = this.getUser();
                if (user && e.detail.ho_ten) {
                    user.ho_ten = e.detail.ho_ten;
                    sessionStorage.setItem(this.USER_KEY, JSON.stringify(user));
                }
            }
        });

        console.log('🔐 Auth system initialized');
    }
}

// Tạo instance global
const triptoAuth = new TriptoAuth();
window.triptoAuth = triptoAuth; // Đính lên window để mọi script truy cập được

// Tự động khởi tạo khi tài liệu load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        triptoAuth.init();
    });
} else {
    triptoAuth.init();
}
