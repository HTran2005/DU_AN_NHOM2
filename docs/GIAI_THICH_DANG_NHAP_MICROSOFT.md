# Giải thích tính năng "Đăng nhập bằng Microsoft" (Entra ID / MSAL)

> Tài liệu này tổng hợp **từ A→Z**: cách tạo kết nối (App Registration), luồng hoạt động của code,
> các lỗi đã gặp khi test và cách sửa, cuối cùng là các bước test chi tiết.
> Mục đích: để bạn đọc hiểu và có thể **giải thích rành mạch với giảng viên**.

---

## 1. Tính năng này là gì?

Trang web du lịch (DU_AN_NHOM2) cho phép người dùng đăng nhập **không cần đăng ký tài khoản riêng**,
mà dùng luôn **tài khoản Microsoft/Outlook/Hotmail** của họ. Đây là cơ chế **SSO (Single Sign-On)**:
một lần đăng nhập vào Microsoft, web tự biết bạn là ai.

Thuật ngữ quan trọng:
- **Entra ID** (tên cũ: Azure AD) — dịch vụ định danh của Microsoft, nơi "đăng ký" ứng dụng của ta.
- **App Registration** — "hồ sơ khai sinh" của ứng dụng trong Entra ID, cấp một **Client ID** duy nhất.
- **MSAL.js** — thư viện JavaScript chính thức của Microsoft giúp web mở popup đăng nhập và nhận token.
- **ID token (JWT)** — "thẻ căn cước" do Microsoft ký, chứa email, tên, id của người dùng.

---

## 2. Kiến trúc tổng quan (3 thành phần)

```
┌──────────────────┐   popup đăng nhập   ┌────────────────────┐
│  Trình duyệt     │ ──────────────────▶ │  Microsoft login   │
│  (Frontend web)  │ ◀────────────────── │  (Entra ID)        │
└──────────────────┘   trả về ID token   └────────────────────┘
        │
        │ POST id_token tới backend
        ▼
┌─────────────────────────────────────────────────────────┐
│  Backend PHP (`backend/user.php`)                       │
│  - Xác minh chữ ký token bằng khóa công khai Microsoft  │
│  - Kiểm tra issuer, audience, thời hạn                  │
│  - Tìm hoặc tự tạo tài khoản trong bảng `nguoi_dung`    │
│  - Mở session đăng nhập như login bình thường           │
└─────────────────────────────────────────────────────────┘
```

- **Frontend**: `frontend/js/microsoft-auth.js` + `frontend/js/auth.js` (tự chèn nút "Tiếp tục với Microsoft" vào modal đăng nhập).
- **Backend**: `backend/user.php` — hàm `authLoginMicrosoft()` và `verifyMicrosoftIdToken()`.
- **Cấu hình**: `backend/config.php` (fallback `MS_CLIENT_ID`) + `frontend/js/microsoft-auth.js` (clientId, tenant).

---

## 3. Luồng hoạt động chi tiết (bước → bước)

1. **User bấm nút "Tiếp tục với Microsoft"** trong modal Đăng Nhập.
   - Nút này do `microsoft-auth.js` tự chèn vào mọi khối `.social-buttons` (7 trang: TRANGCHU, BLOG, TATCA_TOUR, TATCA_COMBO, UUDAI, chitiettour, timkiem_chitiet).
2. **MSAL mở popup đăng nhập** của Microsoft (`loginPopup`), yêu cầu các quyền `openid profile email`.
   - Người dùng chọn tài khoản, nhập mật khẩu, đồng ý quyền (nếu lần đầu).
3. **Microsoft trả về ID token** (chuỗi JWT gồm 3 phần: `header.payload.signature`).
   - Đây là "bằng chứng" user đã đăng nhập thật — nhưng ta **không tin ngay**, phải xác minh.
4. **Frontend gửi `id_token`** lên backend:
   ```js
   fetch('../../user.php?endpoint=auth&action=microsoft_login', {
       method: 'POST',
       body: JSON.stringify({ action: 'microsoft_login', id_token: idToken })
   })
   ```
5. **Backend xác minh token** (hàm `verifyMicrosoftIdToken`) — gồm 4 tầng kiểm tra, mục 4 bên dưới.
6. **Backend tìm / tạo tài khoản**:
   - Nếu email đã tồn tại trong bảng `nguoi_dung` → dùng tài khoản đó.
   - Nếu chưa có → tự tạo mới với tên lấy từ token + mật khẩu ngẫu nhiên (không cần user nhập).
7. **Backend mở session** (`$_SESSION['user_id']`, `logged_in = true`) và trả về thông tin user.
8. **Frontend lưu vào `sessionStorage`** và cập nhật giao diện: nút Đăng Nhập hiện tên user, đóng modal.

> 💡 Điểm cốt lõi: web **không bao giờ thấy mật khẩu** của người dùng Microsoft — mọi thứ nằm trong popup của Microsoft. Đây chính là bản chất của SSO / OAuth 2.0 + OpenID Connect.

---

## 4. Backend xác minh token như thế nào? (bảo mật)

Hàm `verifyMicrosoftIdToken($idToken)` trong `backend/user.php`:

1. **Tách token**: `explode('.', $idToken)` → đúng 3 phần `header.payload.signature`, giải mã base64url.
2. **Kiểm tra thời hạn**: `exp` (hết hạn) và `nbf` (chưa có hiệu lực).
3. **Kiểm tra issuer (`iss`)**: token phải do một trong các host tin cậy của Microsoft ký:
   `login.microsoftonline.com`, `sts.windows.net`, `login.live.com`.
   - → Lỗi thường gặp: dùng `common` (mọi tài khoản cá nhân) nhưng token có thể đến từ `login.live.com`
     (tài khoản cá nhân) → nếu chỉ cho phép `login.microsoftonline.com` thì bị chặn. Đã bổ sung đủ 3 host.
4. **Kiểm tra audience (`aud`)**: phải **khớp chính xác Client ID** của app (`MS_CLIENT_ID`).
   - → Nếu khác → "Audience của ID token không khớp Client ID" (token của app khác, hoặc Client ID cấu hình sai).
5. **Kiểm tra thuật toán**: phải là `RS256`.
6. **Xác minh chữ ký bằng JWKS**:
   - Đọc header, lấy `kid` (id của khóa ký).
   - Tải danh sách khóa công khai của Microsoft từ `https://login.microsoftonline.com/common/discovery/keys` (có cache 1 giờ).
   - Tìm khóa có `kid` trùng, dựng khóa RSA công khai từ các thành phần `n`, `e`.
   - Dùng `openssl_verify` kiểm tra chữ ký trên chuỗi `header.payload`.
   - → Nếu chữ ký sai → "Chữ ký ID token không hợp lệ" (token bị làm giả / chỉnh sửa).

> 💡 **Vì sao an toàn?** Backend **không tin token gửi lên**, mà tự xác minh chữ ký bằng khóa **công khai** do Microsoft phát hành. Ai đó không thể tự tạo token giả vì không có khóa bí mật của Microsoft.

---

## 5. Xử lý tên người dùng (phần mới nhất)

ID token Microsoft chứa các "claim" (trường thông tin): `given_name` (tên), `family_name` (họ),
`name` (tên đầy đủ), `email`.

### Vấn đề gặp phải
- Nhiều tài khoản Microsoft cá nhân **không gửi `given_name`/`family_name`** → trước đây code đặt tên
  mặc định là **"Khách Microsoft"** → nhìn rất xấu trên web.
- Token vẫn có claim **`name`** (tên đầy đủ, ví dụ "Hhd 211105").

### Cách đã sửa (`backend/user.php`)
1. **Khi tạo user mới** — thứ tự ưu tiên lấy tên:
   ```
   1) given_name + family_name  (nếu có)
   2) claim "name" → tách họ/tên: phần cuối cùng làm ten_cuoi, phần còn lại làm ten_dau
      (vd "Hhd 211105" → ten_dau="Hhd", ten_cuoi="211105")
   3) cuối cùng mới là "Khách" + "Microsoft" (hiếm khi xảy ra)
   ```
2. **Cập nhật user cũ**: tài khoản nào đang là "Khách Microsoft" (hoặc tên rỗng) sẽ được
   **tự cập nhật tên thật** ngay lần đăng nhập tiếp theo:
   ```sql
   UPDATE nguoi_dung SET ten_dau = ?, ten_cuoi = ? WHERE id = ?
   ```

---

## 6. Các lỗi đã gặp khi test và cách sửa (bảng tóm tắt)

| # | Lỗi / triệu chứng | Nguyên nhân | Cách sửa |
|---|---|---|---|
| 1 | Popup báo lỗi `redirect_uri` không khớp | Redirect URI trong App Registration không khớp URL web thật | Đặt đúng URL web (đã làm: `https://tripto-...azurewebsites.net`) |
| 2 | Popup lỗi client config / login thất bại | Thiếu `client_secret`/cấu hình client | SPA **không cần** `client_secret` (client public) → bỏ yêu cầu thừa |
| 3 | Backend báo "Issuer không hợp lệ" | Tài khoản cá nhân phát token từ `login.live.com`, code chỉ cho phép `login.microsoftonline.com` | Thêm `login.live.com` vào danh sách issuer tin cậy |
| 4 | Backend báo "Audience không khớp Client ID" | `aud` trong token khác `MS_CLIENT_ID` | Đảm bảo Client ID frontend = `MS_CLIENT_ID` backend |
| 5 | Backend báo lỗi xác minh chữ ký / không tìm thấy khóa | Lỗi dựng khóa RSA từ JWKS | Dựng khóa RSA đúng chuẩn từ `n`, `e`, chọn đúng `kid` |
| 6 | Login thành công nhưng tên hiện "Khách Microsoft" | Token thiếu `given_name`/`family_name` | Fallback dùng claim `name` + tự cập nhật tên cho user cũ |
| 7 | Đăng nhập nhưng chưa vào được session | Session chưa được mở / dữ liệu trả về thiếu | Backend `session_start()` + trả đủ `user` → frontend `setLoginData()` |

---

## 7. Test chi tiết (từng bước)

### A. Kiểm tra giao diện
1. Mở web thật: `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net` (hoặc `tripto-tm.trafficmanager.net`).
2. Bấm **Đăng Nhập** → trong modal phải thấy **3 nút**: Facebook, Google, **Microsoft** (logo 4 ô màu đỏ/xanh/cam/xanh dương).
3. Bấm nút Microsoft → **popup** của Microsoft hiện ra.

### B. Kiểm tra đăng nhập thành công
4. Trong popup: đăng nhập bằng email Microsoft bất kỳ → đồng ý quyền.
5. Popup tự đóng → thông báo **"Đăng nhập bằng Microsoft thành công!"** → nút Đăng Nhập đổi thành **tên thật** của bạn.

### C. Kiểm tra phía backend / dữ liệu
6. Mở SQL database → bảng `nguoi_dung`:
   ```sql
   SELECT id, ten_dau, ten_cuoi, email, microsoft_id FROM nguoi_dung WHERE microsoft_id IS NOT NULL;
   ```
   → Phải thấy dòng user mới (hoặc user cũ đã được cập nhật tên thật).
7. Portal Entra ID → **Monitoring → Sign-in logs** → thấy lần đăng nhập mới
   = bằng chứng quá trình xác thực thật sự đi qua Entra ID.

### D. Kiểm tra khi gặp lỗi (debug)
- Mở **F12 → Network** → tìm request `user.php?...action=microsoft_login` → xem **Response**:
  `success: true` = thành công; `success: false` + `message` = xem thông báo lỗi.
- Mở **F12 → Console** để xem lỗi phía MSAL (ví dụ `redirect_uri`, `user_cancelled`).
- Backend: xem `error_log` của App Service (hoặc thêm tạm `error_log(...)`) để đọc exception.

---

## 8. Gợi ý cách trình bày với giảng viên

1. **Giới thiệu**: "Chức năng đăng nhập bằng tài khoản Microsoft dựa trên **Entra ID (Azure AD)** và giao thức **OpenID Connect**, dùng thư viện **MSAL.js** ở frontend và xác minh JWT ở backend."
2. **Demo luồng**: mở web → bấm Đăng Nhập → Microsoft → đăng nhập thật → hiện tên.
3. **Giải thích bảo mật**: "Token do Microsoft ký; backend tự xác minh chữ ký bằng khóa công khai (JWKS), kiểm tra issuer/audience/thời hạn nên **không thể giả token**."
4. **Nêu khó khăn đã giải quyết**: lỗi redirect_uri, issuer `login.live.com` cho tài khoản cá nhân, lỗi audience, tên "Khách Microsoft" → đã fallback claim `name`.
5. **Minh chứng phía Azure**: mở App Registration + **Sign-in logs** trong Entra ID.

---

## 9. Lưu ý an toàn (để trả lời giảng viên)

- **Client ID** của SPA **không phải bí mật** (nằm public trong code trình duyệt) → commit lên git được.
- **Khác với Azure Maps key** (trong `maps-config.js`) — key đó là bí mật, phải gitignore, không commit.
- Mọi xác minh quan trọng đều ở **backend**; frontend chỉ làm nhiệm vụ nhận token.
- Không dùng `client_secret` cho SPA (dòng chảy public client) — không an toàn nếu nhúng vào frontend.
