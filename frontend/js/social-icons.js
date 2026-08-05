/**
 * Social Media Icons Fix
 * Thay thế logo dạng chữ cái (G, f) trong các nút đăng nhập xã hội
 * bằng logo SVG chính thức của Google và Facebook.
 * Tự động chạy trên mọi trang có `.btn-social-modal` và chứa text "Google"/"Facebook".
 */

const SocialLogoSVG = {
    google: '<svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true" style="vertical-align:middle"><path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24c0 11.045 8.955 20 20 20 11.045 0 20-8.955 20-20 0-1.341-.139-2.65-.389-3.917z"/><path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/><path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/><path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571l6.19 5.238C36.971 39.205 44 34 44 24 44 22.659 43.862 21.35 43.611 20.083z"/></svg>',
    facebook: '<svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true" style="vertical-align:middle"><path fill="#1877F2" d="M24 4C12.954 4 4 12.954 4 24c0 9.887 7.315 18.062 16.875 19.547V29.406h-5.078V24h5.078v-4.406c0-5.011 2.985-7.781 7.553-7.781 2.188 0 4.477.391 4.477.391v4.922h-2.522c-2.485 0-3.26 1.542-3.26 3.125V24h5.547l-.887 5.406h-4.66v14.141C36.685 42.062 44 33.887 44 24 44 12.954 35.046 4 24 4z"/><path fill="#FFFFFF" d="M28.383 29.406l.887-5.406h-5.547v-3.281c0-1.583.775-3.125 3.26-3.125h2.522v-4.922c0 0-2.289-.391-4.477-.391-4.568 0-7.553 2.77-7.553 7.781V24h-5.078v5.406h5.078v14.141c.879.129 1.771.197 2.688.197.917 0 1.809-.068 2.688-.197V29.406h4.537z"/></svg>'
};

function fixSocialLogos() {
    const buttons = document.querySelectorAll('.btn-social-modal');
    buttons.forEach((btn) => {
        const text = (btn.textContent || '').toLowerCase();
        let svg = null;
        if (text.includes('google')) {
            svg = SocialLogoSVG.google;
        } else if (text.includes('facebook')) {
            svg = SocialLogoSVG.facebook;
        } else {
            return;
        }

        const icon = btn.querySelector('i');
        if (icon && (!btn.querySelector('svg'))) {
            // Nếu <i> chỉ chứa 1 ký tự (G hoặc f) → thay bằng SVG
            icon.outerHTML = svg;
        } else if (!btn.querySelector('svg')) {
            btn.insertAdjacentHTML('afterbegin', svg + ' ');
        }
    });
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', fixSocialLogos);
} else {
    fixSocialLogos();
}