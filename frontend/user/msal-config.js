/**
 * Cấu hình Microsoft Entra ID cho frontend
 * File này được commit lên git để GitHub Actions tự deploy (không cần zip deploy riêng).
 * LƯU Ý: authority KHÔNG được có đuôi /v2.0 — MSAL 2.x tự thêm /v2.0.
 * Dùng 'common' để hỗ trợ cả tài khoản tổ chức lẫn tài khoản cá nhân (live.com/gmail).
 * redirectUri để rỗng => MSAL tự dùng URL trang hiện tại (phải được khai báo trong App Registration).
 */
window.MSAL_CONFIG = {
    clientId: 'd3803479-bbab-498a-ab4c-d4c9e36a3a66',
    authority: 'https://login.microsoftonline.com/common',
    redirectUri: ''
};
