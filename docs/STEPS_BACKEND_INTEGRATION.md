# BÁO CÁO KỸ THUẬT — BACKEND & INTEGRATION (TRIPTO)

> **Phạm vi tài liệu:** Mô tả chi tiết quá trình tạo, cấu hình, tích hợp và kiểm thử **6 dịch vụ Backend & Integration** của website TripTo:
> 1. Azure API Management
> 2. Azure Logic Apps
> 3. Azure Communication Services
> 4. Azure Service Bus
> 5. Azure SignalR Service
> 6. Azure Notification Hubs
>
> **Nguồn dữ liệu:** Toàn bộ nội dung trong tài liệu này được đối chiếu từ **repository `DU_AN_NHOM2`** — code, file cấu hình, log deploy, log Function App, lịch sử git — 
>
> **Quy ước:** Những nội dung không tìm thấy bằng chứng trong repository được ghi rõ **"Không tìm thấy bằng chứng trong repository."**

---


### Kiến trúc backend của TripTo

Hệ thống TripTo gồm các thành phần chính đã triển khai (bằng chứng trong repository):

| Thành phần | Tài nguyên / URL | Bằng chứng |
|---|---|---|
| Website frontend | `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net` | `docs/STEPS_ACCOUNT1.md`, `GetVapidPublicKey.js` |
| Website dự phòng | `https://tripto2-e3g2epfdaahzaqaa.southeastasia-01.azurewebsites.net` | `docs/STEPS_ACCOUNT1.md` |
| API Management Gateway | `https://tripto-api-management.azure-api.net/tripto/` | Rất nhiều file frontend HTML/JS |
| Backend PHP | `backend/user.php`, `backend/admin.php` | Thư mục `backend/` |
| Function App | `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net` | `backend/function/`, `kudu-*.json`, log deploy |
| Database | MySQL Flexible `tripto-mysql-db.mysql.database.azure.com` | `backend/config.php:8` |
| Service Bus | `sb://sb-tripto-backend.servicebus.windows.net/` — queue `booking-queue` | `backend/config.php:61-86` |
| SignalR / Notification Hubs / Email | dùng qua Function App `tripto-function` | `backend/function/src/functions/*` |

### Thứ tự thời gian các bước triển khai (từ lịch sử git)

Trích lịch sử commit liên quan trực tiếp đến 6 dịch vụ (theo `git log`):

| Ngày | Commit | Nội dung | Dịch vụ liên quan |
|---|---|---|---|
| 02/08 | `30f809d` Hoàn thành Service Bus | Nghiệp vụ Service Bus ban đầu | Service Bus |
| 05/08 | `762bdbb` Add Azure Service Bus | Thêm Service Bus vào repo | Service Bus |
| 05/08 | `3cbc9ef` thêm service bus | Bổ sung code Service Bus | Service Bus |
| 05/08 | `7db3c34` Add Service Bus config (read SERVICEBUS_KEY from env, no hardcoded secret) | Đưa key vào biến môi trường | Service Bus |
| 06/08 | `42183aa` sửa code ServiceBus.php | Sửa class ServiceBus | Service Bus |
| 07/08 | `c1da73b` Integrate Azure Service Bus into booking flow | Tích hợp Service Bus vào luồng đặt tour | Service Bus |
| 07/08 | `7aa3bdc` sua service bus | Sửa tiếp | Service Bus |
| 08/08 | `5c8a6bf` Fix Service Bus booking flow: robust ServiceBus.php path + config double-include guard | Fix đường dẫn + guard config | Service Bus |
| 08/08 | `973adf3` sửa đường dẫn để tích hợp API Management | Đổi 20 file frontend sang gọi qua gateway | **API Management** |
| 08/08 | `aa50332` Thêm Azure Function gửi email xác nhận đặt tour | Thêm function `SendBookingEmail` | Communication Services |
| 08/08 | `d3e5401` up code Communication Services | Chuyển SMTP Gmail → SMTP ACS | **Communication Services** |
| 09/08 | `b91c313` thêm negotiate.js | Function `negotiate` | SignalR |
| 09/08 | `e5dd61a` thêm sendNotification.js | Function `sendNotification` | SignalR |
| 09/08 | `0871381` Add SignalR negotiate connection | Kết nối negotiate | SignalR |
| 09/08 | `b8cfcf7` Connect frontend to Azure SignalR | Kết nối frontend SignalR | SignalR |
| 09/08 | `2d80a87` Fix negotiate CORS | Fix CORS negotiate | SignalR |
| 09/08 | `245be02` Integrate Azure SignalR booking notification | Tích hợp SignalR vào luồng booking | SignalR |
| 09/08 | `9f9b335` thêm các file notificationHub | Thêm `notificationHub.js`, `registerNotification.js`, `sendNotificationHub.js` | Notification Hubs |
| 10/08 | `54c48df` thêm Notification Hub | Thêm `GetVapidPublicKey.js`, `push-notification.js`, `sw.js`, gọi `initPushNotifications()` ở frontend | Notification Hubs |

---

# 1. Azure API Management

## 1.1. Ý nghĩa của dịch vụ

- **Dịch vụ này là gì:** Azure API Management (APIM) là lớp cổng (Gateway) trung gian đứng trước các API backend. Tất cả request từ client đi qua gateway này rồi mới được định tuyến về backend thật.
- **Vai trò trong Azure:** Cung cấp một điểm truy cập API duy nhất, hỗ trợ CORS, xác thực, giới hạn tốc độ, ghi log, bảo mật và quản lý vòng đời API mà không cần sửa code backend.
- **Vì sao được dùng trong TripTo:** Frontend TripTo **không còn gọi thẳng backend PHP** nữa mà chuyển sang gọi qua gateway APIM (bằng chứng commit `973adf3` và toàn bộ URL `tripto-api-management.azure-api.net` trong frontend).
- **Vấn đề nó giải quyết:** Tránh để client gọi trực tiếp vào App Service backend; giấu địa chỉ backend, tập trung một đầu vào API, đồng thời xử lý CORS cross-origin cho frontend (comment rõ tại `backend/config.php:36-38`: *"CORS - cho phép frontend gọi API qua API Management (cross-origin)"*).

## 1.2. Vai trò trong hệ thống TripTo

API Management nằm **giữa Frontend và Backend**:

```
Frontend (user/*.html, admin/*.html, js/auth.js ...)
        │  GET/POST https://tripto-api-management.azure-api.net/tripto/...
        ▼
[ API MANAGEMENT GATEWAY ]   ← tripto-api-management.azure-api.net/tripto/
        │
        ▼
Backend (backend/user.php, backend/admin.php)
        │
        ▼
Database (Azure MySQL) + Service Bus + SignalR (tác vụ nền sau booking)
```

Các URL cụ thể được frontend sử dụng (bằng chứng trong các file HTML/JS):

| Loại | URL qua gateway | Ví dụ endpoint |
|---|---|---|
| User | `.../tripto/user.php` | `endpoint=auth&action=login`, `endpoint=get_tours`, `endpoint=create_booking`, `endpoint=get_booking_detail`, `endpoint=cancel_booking`, `endpoint=get_invoice`, `endpoint=toggle_favorite`, ... |
| Admin | `.../tripto/backend/admin.php` | `action=admin_login`, `action=get_tours`, `action=add_tour`, `action=update_tour`, `action=delete_tour`, `action=get_bookings`, `action=confirm_booking`, `action=get_users`, `action=get_payments`, ... |

## 1.3. Các bước tạo dịch vụ trên Azure

**Không tìm thấy bằng chứng trong repository.**

Trong repository **không có** file Bicep/JSON/PowerShell nào khai báo resource API Management, và **không có** tài liệu ghi lại quá trình bấm Portal để tạo APIM. Chỉ có thể xác định **từ code/URL**:

- **Tên gateway (host):** `tripto-api-management.azure-api.net`
- **API path prefix:** `/tripto/` (mọi request frontend đều có dạng `https://tripto-api-management.azure-api.net/tripto/user.php?...` hoặc `.../tripto/backend/admin.php?...`)
- **Tên API:** có khả năng là `tripto` (khớp với segment `/tripto/`) — nhưng đây là suy luận từ URL, **không có bằng chứng khai báo chính thức trong repo**.
- **SKU/tier, Region, Resource Group:** Không tìm thấy bằng chứng trong repository.

> Ghi chú: Đây là phần mà nhóm cần bổ sung nếu muốn tài liệu đầy đủ quá trình tạo resource (Portal hoặc CLI `az apim create`).

## 1.4. Các bước cấu hình sau khi tạo

Có bằng chứng từ phía **backend** để gateway hoạt động đúng với frontend cross-origin:

1. **CORS ở phía backend (`backend/config.php:36-52`):**
   - Gửi `Access-Control-Allow-Origin` theo origin của request.
   - `Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS`.
   - `Access-Control-Allow-Headers: Content-Type, Authorization, Origin, X-Requested-With, Accept`.
   - `Access-Control-Allow-Credentials: true` (hỗ trợ cookie session).
   - Tự trả HTTP 204 cho request `OPTIONS` (preflight).

2. **Cấu hình phía gateway APIM (API/Operation/Backend/Policy):**
   - **Không tìm thấy bằng chứng trong repository.** Không có chính sách (policy), không có khai báo operation/backend nào được lưu trong repo.
   - Không tìm thấy bằng chứng về **Subscription key** (`Ocp-Apim-Subscription-Key`) được gửi từ frontend — các request trong repo đều không kèm header subscription key, tức gateway được cấu hình chấp nhận request mà không bắt buộc subscription key (hoặc subscription key được đặt ở lớp khác không lưu trong repo).
   - **Không tự thêm Rate Limit (giới hạn 10 request/giây) vì repository không có bằng chứng về bất kỳ policy nào.**

## 1.5. Các file trong repository liên quan

| File | Vai trò |
|---|---|
| `frontend/js/auth.js` | Đăng nhập/đăng ký user gọi `https://tripto-api-management.azure-api.net/tripto/user.php` (dòng 66, 143, 407) |
| `frontend/js/microsoft-auth.js` | Đăng nhập Microsoft gọi gateway `.../user.php?endpoint=auth&action=microsoft_login` (dòng 115) |
| `frontend/user/*.html` (TRANGCHU, chitiettour, TATCA_TOUR, TATCA_COMBO, chuyendi, thanhtoan_chitiet, UUDAI, BLOG, yeuthich, ...) | Toàn bộ gọi API user qua gateway `.../tripto/user.php` |
| `frontend/admin/*.html` (Admin_Login, Trangchu_ad, Tour_ad, TourDaDat_ad, KhachHang, ThanhToan, ...) | Toàn bộ gọi API admin qua gateway `.../tripto/backend/admin.php` |
| `backend/user.php`, `backend/admin.php` | Backend thật đứng sau gateway |
| `backend/config.php:36-52` | CORS cho phép frontend gọi API qua API Management |

**Bằng chứng chuyển đổi trực tiếp → gateway (commit `973adf3`):** diff của `frontend/js/auth.js` thể hiện rõ thay đổi:

```diff
- const apiUrl = '../../user.php';
+ const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/user.php';
```

Commit này sửa **20 file frontend** (`frontend/admin/*` và `frontend/user/*`) cùng lúc.

## 1.6. Cách dịch vụ được tích hợp vào TripTo

Luồng thao tác thực tế:

```
Người dùng mở trang / bấm "Đăng nhập" / "Đặt tour" / Admin mở trang quản trị
        │
        ▼
Frontend thực hiện fetch() tới:
  https://tripto-api-management.azure-api.net/tripto/user.php
  https://tripto-api-management.azure-api.net/tripto/backend/admin.php
        │  (GET hoặc POST, kèm CORS preflight OPTIONS nếu cần)
        ▼
[ API MANAGEMENT GATEWAY ]  →  định tuyến theo path /tripto/
        │
        ▼
Backend PHP xử lý (user.php / admin.php) → truy vấn Azure MySQL
        │
        ▼
Trả JSON về frontend qua gateway
```

Ví dụ điển hình — **đăng nhập admin** (`frontend/admin/Admin_Login.html:298-308`):

1. Admin nhập email + mật khẩu.
2. Frontend `fetch('https://tripto-api-management.azure-api.net/tripto/backend/admin.php', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({ action:'admin_login', email, password }) })`.
3. Request đi qua gateway APIM → tới `backend/admin.php` → `adminLogin()` kiểm tra DB → trả JSON.
4. Frontend lưu thông tin admin vào `localStorage` và chuyển trang.

Ví dụ **đặt tour** (`frontend/user/thanhtoan_chitiet.html:1657-1663`):

1. User bấm "Xác nhận đặt tour".
2. Frontend `fetch('https://tripto-api-management.azure-api.net/tripto/user.php?endpoint=create_booking', { method: 'POST', ... })`.
3. Gateway chuyển tiếp tới `backend/user.php` → `handleCreateBooking()` lưu booking vào DB → trả JSON 201.
4. Sau đó backend nền gửi message lên Service Bus + gọi SignalR (xem mục 4 và 5).

## 1.7. Cách kiểm thử thực tế

Thao tác demo trên website TripTo:

1. Mở trang user bất kỳ (vd `frontend/user/TATCA_TOUR.html`) hoặc trang admin.
2. Mở DevTools (F12) → tab **Network**.
3. Lọc request và quan sát: mọi request API đều có URL bắt đầu bằng `tripto-api-management.azure-api.net/tripto/...`.
4. Thực hiện 1 thao tác cụ thể: **đăng nhập admin** tại `frontend/admin/Admin_Login.html` → trong Network thấy request POST `.../tripto/backend/admin.php` trả về HTTP 200 kèm JSON `{"success":true,...}`.
5. (Trên Azure Portal) mở resource **API Management** → chọn API → tab **Test** → gọi thử 1 operation tới `user.php?endpoint=get_tours` → nhận response JSON của backend (chỉ áp dụng nếu resource còn tồn tại và có quyền truy cập).

## 1.8. Kết quả đạt được

- **Website request đi qua API Management:** có bằng chứng trực tiếp — toàn bộ code frontend hiện tại đều gọi gateway `tripto-api-management.azure-api.net/tripto/...`, và backend đã có CORS phục vụ cross-origin cho gateway (`backend/config.php:36-52`).
- **Chuyển đổi hoàn chỉnh từ gọi trực tiếp sang gọi gateway:** commit `973adf3` đổi 20 file frontend, diff xác nhận `../../user.php` → `https://tripto-api-management.azure-api.net/tripto/user.php`.

## 1.9. Trạng thái cuối cùng

**Đã tích hợp thực tế vào website** (frontend gọi qua gateway + backend có CORS tương thích). Tuy nhiên:

- **Chưa có bằng chứng trong repository** về các bước tạo resource APIM (Portal/CLI), cấu hình API/Operation/Backend, Subscription key hay Policy (Rate Limit). Phần này cần bổ sung nếu muốn chứng minh đầy đủ end-to-end trên Portal.

---

# 2. Azure Logic Apps

## 2.1. Ý nghĩa của dịch vụ

- **Dịch vụ này là gì:** Azure Logic Apps là nền tảng **serverless orchestration / integration** — cho phép xây dựng workflow (luồng công việc) bằng các bước (steps) như Trigger (Service Bus, HTTP, Timer...), Action (gửi email, gọi API, chuyển đổi dữ liệu...) mà không cần viết nhiều code.
- **Vai trò trong Azure:** Nối các dịch vụ lại với nhau bằng workflow trực quan (Logic App Designer), quản lý vòng đời, retry, theo dõi Run History.
- **Vì sao được dùng trong hệ thống TripTo:** *(theo giả định của đề bài nhóm)* — dùng để nhận message từ Service Bus `booking-queue` và xử lý (vd gửi email/thông báo). **Nhưng nội dung bên dưới dựa trên bằng chứng repository.**
- **Vấn đề nó giải quyết:** Tự động hoá xử lý message từ hàng đợi mà không cần service chạy thường trực.

## 2.2. Vai trò trong hệ thống TripTo

**Không tìm thấy bằng chứng trong repository.**

Không có bất kỳ bằng chứng nào về Azure Logic Apps trong repository: không có file khai báo workflow, không có link Logic App, không có commit git nào liên quan.

## 2.3. Các bước tạo dịch vụ trên Azure

**Không tìm thấy bằng chứng trong repository.**

## 2.4. Các bước cấu hình sau khi tạo

**Không tìm thấy bằng chứng trong repository.**

Không tìm thấy bằng chứng về:
- Trigger nhận message từ Service Bus.
- Run History (Succeeded/Failed).
- Workflow xử lý booking.

> Lưu ý: từ khoá "workflow" xuất hiện trong repo chỉ là **GitHub Actions workflows** (`.github/workflows/*.yml`, `azure-pipelines.yml`) — không liên quan Azure Logic Apps.

## 2.5. Các file trong repository liên quan

**Không có file nào liên quan đến Azure Logic Apps.**

## 2.6. Cách dịch vụ được tích hợp vào TripTo

**Không tìm thấy bằng chứng trong repository.** Không thể vẽ sơ đồ luồng `Service Bus → Logic App` vì repo không có bằng chứng.

## 2.7. Cách kiểm thử thực tế

**Không tìm thấy bằng chứng trong repository.**

## 2.8. Kết quả đạt được

**Không có kết quả nào có thể xác nhận từ repository.**

## 2.9. Trạng thái cuối cùng

**Chưa có đủ bằng chứng / chưa xác minh được.**

Không tìm thấy bằng chứng trong repository cho thấy Azure Logic Apps đã được tạo, cấu hình hay tích hợp vào hệ thống TripTo. Cần xác nhận lại với nhóm thực hiện phần này hoặc bổ sung tài liệu/IaC vào repo.

---

# 3. Azure Communication Services

## 3.1. Ý nghĩa của dịch vụ

- **Dịch vụ này là gì:** Azure Communication Services (ACS) là bộ dịch vụ giao tiếp của Azure — gồm Email, SMS, Voice, Chat, Video Call. Trong phạm vi TripTo, ACS được dùng cho **Email** (gửi email xác nhận đặt tour).
- **Vai trò trong Azure:** Cung cấp kênh SMTP/Email có thương hiệu Azure để ứng dụng gửi email (relay SMTP), kèm giao diện Portal quản lý domain, sender, v.v.
- **Vì sao được dùng trong TripTo:** Luồng gửi email xác nhận booking yêu cầu một SMTP ổn định thay vì dùng Gmail SMTP cá nhân.
- **Vấn đề nó giải quyết:** Chuyển từ SMTP Gmail cá nhân (đã từng dùng — bằng chứng log Gmail) sang SMTP do Azure quản lý để gửi email xác nhận tour.

## 3.2. Vai trò trong hệ thống TripTo

Dịch vụ nằm ở **phía sau Function App**, được gọi bởi function HTTP `SendBookingEmail`:

```
Frontend (thanhtoan_chitiet.html)
   │  POST /api/SendBookingEmail  (tới Function App trực tiếp, KHÔNG qua API Management)
   ▼
[ FUNCTION APP: tripto-function ]
   │  nodemailer + SMTP (SMTP_HOST / SMTP_PORT / SMTP_USERNAME / SMTP_PASSWORD / MAIL_FROM)
   ▼
[ AZURE COMMUNICATION SERVICES - SMTP Relay / SMTP host ]
   ▼
Email xác nhận đến hộp thư khách hàng
```

> **Lưu ý trách nhiệm triển khai:** Azure Function App `tripto-function` có thể do một thành viên khác trong nhóm triển khai (bằng chứng: Function App được mô tả trong `docs/STEPS_DATABASE_STORAGE.md` — "Máy 3", người thực hiện `NgocLan`). Tài liệu này **không khẳng định** rằng Backend & Integration đã xây dựng toàn bộ Function App; chỉ xác nhận code function `SendBookingEmail` tồn tại trong repo và sử dụng SMTP ACS.

## 3.3. Các bước tạo dịch vụ trên Azure

**Không tìm thấy bằng chứng trong repository** về việc tạo resource ACS trên Portal (không có tài liệu, không có Bicep/CLI, không ghi SKU/Region/Resource Group).

Chỉ có thể xác định từ code/log những **thông tin cấu hình** mà ACS cấp:

| Thông tin | Giá trị / bằng chứng |
|---|---|
| Biến môi trường | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM` (`SendBookingEmail.js:149-169`) |
| App Settings trên Function App | Được liệt kê trong `docs/STEPS_DATABASE_STORAGE.md` (mục Dịch vụ 6, Bước 4) |
| Xác nhận kết nối | Log Function: `"✅ ACS SMTP connection successful"` |

## 3.4. Các bước cấu hình sau khi tạo

Bằng chứng trong repo cho thấy quá trình cấu hình gồm:

1. **Viết function gửi email qua SMTP** (`backend/function/src/functions/SendBookingEmail.js`):
   - HTTP trigger `POST`/`OPTIONS`, `authLevel: 'anonymous'`.
   - CORS `Access-Control-Allow-Origin: *` cho OPTIONS preflight và response.
   - Đọc body `{ name, email, phone, tour, departDate, total, bookingCode }`.
   - Kiểm tra đủ biến môi trường SMTP; thiếu thì trả 500.
   - Tạo `nodemailer.createTransport({ host: SMTP_HOST, port: Number(SMTP_PORT), secure:false, auth:{user,pass} })`.
   - `transporter.verify()` → log `✅ ACS SMTP connection successful`.
   - `sendMail()` với nội dung HTML xác nhận đặt tour (mã đặt tour, tên khách, sđt, tour, ngày khởi hành, tổng tiền VNĐ).
   - Log `Message ID`, `Accepted`, `Rejected`, `SMTP Response`.

2. **Đặt biến môi trường trên Function App** (ghi trong `docs/STEPS_DATABASE_STORAGE.md`): `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM`.

3. **Di trú từ Gmail → ACS** (bằng chứng commit `d3e5401` "up code Communication Services", diff `SendBookingEmail.js`):
   ```diff
   - const transporter = nodemailer.createTransport({ service: "gmail", auth: { user: EMAIL_USER, pass: EMAIL_PASS } });
   + const transporter = nodemailer.createTransport({ host: SMTP_HOST, port: Number(SMTP_PORT), secure:false, auth:{user:SMTP_USERNAME, pass:SMTP_PASSWORD} });
   - context.log("✅ Gmail SMTP connection successful");
   + context.log("✅ ACS SMTP connection successful");
   - from: `"Tripto" <${EMAIL_USER}>`
   + from: process.env.MAIL_FROM
   ```

## 3.5. Các file trong repository liên quan

| File | Vai trò |
|---|---|
| `backend/function/src/functions/SendBookingEmail.js` | Function gửi email xác nhận đặt tour qua SMTP (ACS) — bằng chứng chính |
| `backend/function/package.json` | Dependency `nodemailer` |
| `frontend/user/thanhtoan_chitiet.html:1689` | Frontend gọi `POST /api/SendBookingEmail` sau khi đặt tour thành công |
| `backend/function/tripto-function-logs/LogFiles/Application/Functions/Host/*.log` | Log thực thi: `ACS SMTP connection successful`, `Accepted`, `SMTP Response` |
| `docs/STEPS_DATABASE_STORAGE.md` | Liệt kê app settings `SMTP_*` cho Function App |

## 3.6. Cách dịch vụ được tích hợp vào TripTo

Luồng thực tế khi khách **đặt tour thành công** trên `thanhtoan_chitiet.html`:

1. Khách điền thông tin + bấm "Xác nhận đặt tour".
2. Frontend `fetch()` gọi **API Management gateway** → `user.php?endpoint=create_booking` → backend lưu booking vào DB, trả JSON 201 kèm `so_dat_tour`.
3. Ngay sau đó, frontend `fetch()` gọi **trực tiếp Function App**:
   ```
   POST https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/SendBookingEmail
   { name, email, phone, tour, departDate, total, bookingCode }
   ```
   (bằng chứng `thanhtoan_chitiet.html:1689-1703`)
4. Function `SendBookingEmail` xác thực biến môi trường → `transporter.verify()` (xác nhận kết nối SMTP ACS) → gửi email HTML → trả JSON `{ success: true, message: "Đã gửi email xác nhận thành công.", accepted: [...], rejected: [...] }`.
5. Frontend đọc `data.success` → hiện thông báo `📧 Email xác nhận đã được gửi đến: <email>`.

```
Frontend thanhtoan_chitiet.html
   │ 1) POST .../tripto/user.php?endpoint=create_booking  (qua API Management)
   ▼
Backend PHP → DB → trả so_dat_tour
   │ 2) POST /api/SendBookingEmail  (tới Function App trực tiếp)
   ▼
Function SendBookingEmail → SMTP (Azure Communication Services)
   ▼
Email "Xác nhận đặt tour thành công" → Gmail/Email khách
```

## 3.7. Cách kiểm thử thực tế

1. Mở trang thanh toán tour (`frontend/user/thanhtoan_chitiet.html`) trên web `tripto...azurewebsites.net`.
2. Đăng nhập, chọn tour + ngày khởi hành + số người → bấm **Xác nhận đặt tour**.
3. Quan sát: sau khi đặt thành công, trình duyệt hiện thông báo *"Email xác nhận đã được gửi đến: <email>"*.
4. Mở hộp thư của khách → nhận email **"🎉 Xác nhận đặt tour thành công"** với bảng thông tin (mã đặt tour, tour, tổng tiền VNĐ).
5. (Tùy chọn) Xem log Function App → **Monitor** → function `SendBookingEmail` → các log `===== EMAIL RESULT =====`, `Accepted`, `SMTP Response: 250 ... Queued mail for delivery`.

**Bằng chứng log thực tế trong repo** (Function Host logs):
- `2026-08-08T17:04:56.840` → `Accepted: [ 'camlylv2021@gmail.com' ]`, `SMTP Response: 250 2.6.0 ... Queued mail for delivery`, `Executed 'Functions.SendBookingEmail' (Succeeded ...)`.
- `2026-08-08T17:06:53.751` → `Accepted: [ '0023411831@student.dthu.edu.vn' ]`, `Executed (Succeeded ...)`.
- `2026-08-09T03:00:22.486` → `Accepted: [ '0023412018@student.dthu.edu.vn' ]`, `Executed (Succeeded, Duration=3624ms)`.
- Phiên bản trước (Gmail, 12:53 ngày 08/08) → `Gmail SMTP connection successful`, `Message ID: <...@gmail.com>`, `gsmtp`.

## 3.8. Kết quả đạt được

- **Email xác nhận đến Gmail:** có bằng chứng mạnh — nhiều log `SendBookingEmail` kết thúc **Succeeded** với `Accepted` chứa địa email thật (`camlylv2021@gmail.com`, `0023411831@student.dthu.edu.vn`, `0023412018@student.dthu.edu.vn`) và SMTP Response `250 ... Queued mail for delivery`.
- **Kết nối SMTP ACS thành công:** log `✅ ACS SMTP connection successful` xuất hiện ở phiên bản mới (sau commit `d3e5401`).

## 3.9. Trạng thái cuối cùng

**Đã tích hợp thực tế và có bằng chứng hoạt động** (email gửi thành công qua SMTP — phiên bản code hiện tại dùng biến `SMTP_*` và log ghi "ACS SMTP").

Tuy nhiên cần lưu ý:
- **Không tìm thấy bằng chứng** về việc tạo resource Azure Communication Services trên Portal (SKU/domain/sender).
- Việc **gửi email trực tiếp từ Function App** (không qua API Management gateway) là đúng như code hiện tại, nhưng không khẳng định phần Function App là do Backend & Integration xây dựng (xem ghi chú mục 3.2).

---

# 4. Azure Service Bus

## 4.1. Ý nghĩa của dịch vụ

- **Dịch vụ này là gì:** Azure Service Bus là **message broker** (hàng đợi trung gian) của Azure, dùng để truyền message không đồng bộ giữa các thành phần.
- **Vai trò trong Azure:** Cung cấp **Queue** (hàng đợi) và **Topic** (chủ đề) với cơ chế Peek-Lock, SAS, độ trễ thấp, hỗ trợ REST API.
- **Vì sao được dùng trong TripTo:** Sau khi khách đặt tour, backend PHP gửi một message booking lên queue `booking-queue` để xử lý không đồng bộ (tách khỏi request chính, không làm chậm response cho khách).
- **Vấn đề nó giải quyết:** Tách rời luồng ghi DB (đồng bộ) khỏi luồng xử lý hậu kỳ (không đồng bộ); đảm bảo dữ liệu booking không bị mất kể cả khi tác vụ hậu kỳ thất bại (message nằm an toàn trong queue).

## 4.2. Vai trò trong hệ thống TripTo

```
Frontend → (gateway) → backend/user.php (handleCreateBooking)
                              │ 1) ghi dat_tour vào MySQL (đồng bộ, trả 201 cho client)
                              │ 2) ServiceBus::send(...)  ← tác vụ nền
                              ▼
              [ AZURE SERVICE BUS: sb-tripto-backend ]
                              │  queue: booking-queue
                              ▼
              (consumer xử lý message — KHÔNG có bằng chứng trong repo)
```

## 4.3. Các bước tạo dịch vụ trên Azure

**Không tìm thấy bằng chứng trong repository** về các bước bấm Portal (tạo namespace, tạo queue). Chỉ xác định được từ `backend/config.php:61-86`:

| Thông tin | Giá trị |
|---|---|
| Namespace endpoint | `sb://sb-tripto-backend.servicebus.windows.net/` |
| Queue | `booking-queue` |
| Shared Access Policy | `RootManageSharedAccessKey` |
| Key (secret) | đọc từ biến môi trường `SERVICEBUS_KEY` — **không hardcode** |

> Đây là bằng chứng cấu hình (config), không phải bằng chứng tạo resource. Nếu cần chứng minh Portal, cần bổ sung tài liệu/ảnh hoặc `az servicebus ...`.

## 4.4. Các bước cấu hình sau khi tạo

1. **Tạo class helper `backend/servicebus/ServiceBus.php`** — tự gọi REST API Service Bus bằng GuzzleHTTP:
   - `generateSasToken($expiry=3600)` — tự xây **Shared Access Signature** (HMAC-SHA256) cho namespace.
   - `buildHeaders()` — `Authorization: SharedAccessSignature ...`.
   - `send(array $data)` — `POST {namespace}/{queue}/messages` với header `BrokerProperties: {"Label":"TripTo Booking"}`, body JSON.
   - `receive()` — `POST {namespace}/{queue}/messages/head` (Peek-Lock), lấy `Location` header để xoá message.
   - `deleteMessage($location)` — `DELETE` tới Location nhận được từ receive (hoàn tất message).

2. **Tạo endpoint thử nghiệm độc lập:**
   - `backend/servicebus/sendMessage.php` — nhận JSON, bắt buộc các trường `booking_id, tour_id, user_id, customer_name, email, phone, price`; tạo message kèm `created_at`; gọi `ServiceBus->send()`. Chỉ chấp nhận `POST` (405 nếu khác).
   - `backend/servicebus/receiveMessage.php` — gọi `receive()` rồi `deleteMessage()` nếu có Location; trả `queue_message` + `delete_result`.

3. **Tích hợp vào luồng đặt tour (`backend/user.php` → `handleCreateBooking()`):**
   - Sau khi ghi `dat_tour` vào MySQL, **gửi response 201 + flush trước** (`fastcgi_finish_request()`), rồi mới chạy tác vụ nền gửi Service Bus — tránh lỗi nginx 5xx làm mất response.
   - Message booking gửi lên queue gồm: `booking_id, tour_id, user_id, customer_name, email, phone, price, tour_name, depart_date, booking_code, adults, children`.
   - Mọi lỗi Service Bus/SignalR trong tác vụ nền được bọc `try/catch` + `error_log` — không làm hỏng luồng booking.

4. **Cấu hình double-include guard + đường dẫn file:** commit `5c8a6bf` thêm `if (!defined('SERVICEBUS_QUEUE')) require config` và `APP_SKIP_DB_CONNECT` để Service Bus không phụ thuộc DB.

## 4.5. Các file trong repository liên quan

| File | Vai trò |
|---|---|
| `backend/config.php:61-86` | Cấu hình namespace `sb-tripto-backend`, queue `booking-queue`, policy `RootManageSharedAccessKey`, key từ env |
| `backend/servicebus/ServiceBus.php` | Class helper: SAS token + send/receive/deleteMessage |
| `backend/servicebus/sendMessage.php` | Endpoint test gửi message |
| `backend/servicebus/receiveMessage.php` | Endpoint test nhận + xoá message |
| `backend/user.php:4009-4122` | Tích hợp gửi message vào luồng đặt tour (tác vụ nền) |
| `backend/composer.json` | GuzzleHTTP dependency |

## 4.6. Cách dịch vụ được tích hợp vào TripTo

Luồng đặt tour đầy đủ:

```
Frontend thanhtoan_chitiet.html
   │ POST .../tripto/user.php?endpoint=create_booking  (qua API Management)
   ▼
backend/user.php → handleCreateBooking()
   │ 1) INSERT dat_tour vào MySQL
   │ 2) echo JSON 201 + fastcgi_finish_request()  ← client nhận response ngay
   ▼  (tác vụ nền)
   │ ServiceBus::send([
   │    booking_id, tour_id, user_id, customer_name, email, phone, price,
   │    tour_name, depart_date, booking_code, adults, children ])
   ▼
AZURE SERVICE BUS  (namespace sb-tripto-backend)
   ▼  queue: booking-queue
   (message nằm trong hàng đợi chờ consumer xử lý)
```

## 4.7. Cách kiểm thử thực tế

1. **Từ website:** đặt tour thật tại `frontend/user/thanhtoan_chitiet.html` → backend tự gửi message lên `booking-queue` (tác vụ nền, không chặn response).
2. **Trên Azure Portal:** mở **Service Bus** → namespace `sb-tripto-backend` → Queue `booking-queue` → tab **Service Bus Explorer** (hoặc Overview) → xem **Active message count** tăng sau mỗi lần đặt tour — đây là bằng chứng trực quan message đã vào queue.
3. **Bằng endpoint PHP trong repo** (khi chạy local/App Service):
   - `POST http://<host>/backend/servicebus/sendMessage.php` với JSON đủ trường → trả `{"success":true,"status":201,"message":"Message sent successfully."}`.
   - `GET http://<host>/backend/servicebus/receiveMessage.php` → nhận message đầu queue rồi xoá.
4. (Tùy chọn) kiểm tra `curl` trực tiếp queue REST với SAS token sinh từ `ServiceBus.php`.

## 4.8. Kết quả đạt được

- **Message booking được gửi lên Service Bus:** có bằng chứng từ code tích hợp (`user.php:4073-4086` gọi `$serviceBus->send(...)` trong luồng đặt tour thật).
- **Queue `booking-queue` và namespace `sb-tripto-backend` được cấu hình:** bằng chứng `backend/config.php:61-86`.
- **End-to-end kiểm chứng từ website → queue:** cần xác nhận bằng Portal Service Bus Explorer (active message count) — **không có ảnh/log Portal nào trong repository** chứng minh message thực tế xuất hiện trong queue.

> **Lưu ý quan trọng về Logic Apps:** mặc dù đề bài giả định "Service Bus → Logic App", repository **không có bằng chứng** về consumer nào (Logic App hoặc Function) nhận message từ `booking-queue` để xử lý. Mối liên hệ Service Bus ↔ Logic Apps **không được chứng minh trong repo** (xem mục 2).

## 4.9. Trạng thái cuối cùng

**Đã tích hợp thực tế vào luồng booking** (backend gửi message lên queue sau khi đặt tour) **và có đủ code/cấu hình** (namespace, queue, SAS, send/receive).

Nhưng **chưa hoàn thiện end-to-end**: không có bằng chứng trong repository về việc một consumer (Logic App/Function) thực sự nhận và xử lý message từ queue, và không có ảnh/log Portal chứng minh message xuất hiện trong queue.

---

# 5. Azure SignalR Service

## 5.1. Ý nghĩa của dịch vụ

- **Dịch vụ này là gì:** Azure SignalR Service là dịch vụ **real-time** của Azure, duy trì kết nối WebSocket giữa server và nhiều client, đẩy thông báo tới client tức thời mà không cần client hỏi lại (polling).
- **Vai trò trong Azure:** Quản lý kết nối, scale, và broadcast message tới các **Hub** (khái niệm nhóm kênh giao tiếp).
- **Vì sao được dùng trong TripTo:** Để đẩy **notification realtime** cho giao diện website khi có đặt tour mới — ví dụ một tab khác (admin/user) hiện Toast thông báo ngay lập tức.
- **Vấn đề nó giải quyết:** Thay vì reload trang hay polling, trình duyệt nhận sự kiện `newNotification` qua kết nối WebSocket và hiển thị Toast realtime.

## 5.2. Vai trò trong hệ thống TripTo

```
backend/user.php (handleCreateBooking — tác vụ nền sau booking)
   │  curl POST /api/sendNotification   { type:'booking_success', bookingCode, tourName, ... }
   ▼
[ FUNCTION APP: tripto-function ] → sendNotification.js (output binding SignalR)
   │  hub: triptoHub, event: newNotification
   ▼
[ AZURE SIGNALR SERVICE ]  (kết nối AzureSignalRConnectionString)
   ▼  (broadcast)
Trình duyệt (frontend/js/signalr.js — WebSocket qua negotiate)
   ▼
Toast hiển thị realtime
```

## 5.3. Các bước tạo dịch vụ trên Azure

**Không tìm thấy bằng chứng trong repository** về các bước bấm Portal tạo resource SignalR (SKU, region, resource group). Xác định được từ code:

| Thông tin | Giá trị / bằng chứng |
|---|---|
| Hub | `triptoHub` (`negotiate.js:6`, `sendNotification.js:6`) |
| App Setting | `AzureSignalRConnectionString` (tên biến môi trường lưu connection string — `negotiate.js:7`, `sendNotification.js:7`) |
| Function route | `/api/negotiate`, `/api/sendNotification` |
| URL Function App | `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net` |

> `docs/STEPS_DATABASE_STORAGE.md` (mục Dịch vụ 6, Bước 4) liệt kê app setting `AzureSignalRConnectionString` trên Function App — là bằng chứng cấu hình connection string.

## 5.4. Các bước cấu hình sau khi tạo

1. **Viết function `negotiate.js`** — cấp connection info cho client:
   - Input binding `signalRConnectionInfo`, `hubName: 'triptoHub'`, `connectionStringSetting: 'AzureSignalRConnectionString'`.
   - Route `negotiate`, methods `POST`/`OPTIONS`, CORS `Access-Control-Allow-Origin: *`.
   - Trả về `{ url, accessToken }` cho frontend.

2. **Viết function `sendNotification.js`** — phát sự kiện:
   - Output binding `signalR`, `hubName: 'triptoHub'`.
   - Route `sendNotification`, methods `POST`.
   - `context.extraOutputs.set(signalR, { target: 'newNotification', arguments: [data] })` — gửi event `newNotification` kèm payload tới hub.

3. **Viết client `frontend/js/signalr.js`**:
   - `fetch('https://tripto-function-...azurewebsites.net/api/negotiate', { method:'POST' })`.
   - `new signalR.HubConnectionBuilder().withUrl(data.url, { accessTokenFactory: () => data.accessToken }).withAutomaticReconnect().build()`.
   - `connection.on('newNotification', handleNotification)`.
   - `handleNotification()` hiển thị Toast khi `payload.type === 'booking_success'` (kèm tiêu đề, mã đặt tour, tên tour, ngày khởi hành, tổng tiền định dạng VNĐ); Toast tự đóng sau 5 giây.

4. **Tải thư viện client vào trang** (CDN `@microsoft/signalr@8.0.7`) + file `../js/signalr.js`:
   - `frontend/user/TRANGCHU.html:3679-3680`
   - `frontend/user/thanhtoan_chitiet.html:1828-1829`
   - `frontend/user/chitiettour.html:3737-3738`

5. **Tích hợp backend booking → SignalR** (`backend/user.php:4088-4119`): sau booking, `curl POST {FunctionApp}/api/sendNotification` với payload `{ type:'booking_success', title, message, bookingId, bookingCode, tourName, departDate, totalPrice }`, timeout 3s, có log lỗi nếu fail.

6. **Fix CORS negotiate** (commit `2d80a87`).

## 5.5. Các file trong repository liên quan

| File | Vai trò |
|---|---|
| `backend/function/src/functions/negotiate.js` | Cấp `{url, accessToken}` cho client (input binding SignalR, hub `triptoHub`) |
| `backend/function/src/functions/sendNotification.js` | Gửi event `newNotification` tới hub (output binding SignalR) |
| `frontend/js/signalr.js` | Client SignalR: kết nối + hiển thị Toast realtime |
| `frontend/user/TRANGCHU.html`, `thanhtoan_chitiet.html`, `chitiettour.html` | Load CDN `@microsoft/signalr` + `../js/signalr.js` |
| `backend/user.php:4088-4119` | Backend gọi `/api/sendNotification` sau khi đặt tour |
| `package.json` (root) | Dependency `@microsoft/signalr: ^10.0.11` (bản dùng để build/test cục bộ) |
| `docs/STEPS_DATABASE_STORAGE.md` | Liệt kê app setting `AzureSignalRConnectionString` |

## 5.6. Cách dịch vụ được tích hợp vào TripTo

```
User đặt tour (thanhtoan_chitiet.html)
   │
   ▼
backend/user.php → lưu DB → trả 201 → tác vụ nền:
   │
   ├──► ServiceBus::send(...)                 (mục 4)
   │
   └──► curl POST /api/sendNotification        (payload booking_success)
             │
             ▼
         sendNotification.js → output binding SignalR → hub triptoHub
             │  event: newNotification
             ▼
         AZURE SIGNALR SERVICE → đẩy tới mọi client đang kết nối
             │
             ▼
         Trình duyệt: frontend/js/signalr.js
             │  connection.on('newNotification', handleNotification)
             ▼
         Toast "Đặt tour thành công!" + mã đặt tour + tổng tiền hiện realtime
```

Thao tác **kết nối ban đầu** của trang:

```
Mỗi trang load frontend/js/signalr.js
   │ fetch POST /api/negotiate
   ▼
negotiate.js → input binding → { url, accessToken }
   ▼
HubConnectionBuilder().withUrl(url, accessToken) → kết nối WebSocket tới Azure SignalR
```

## 5.7. Cách kiểm thử thực tế

1. **Mở 2 tab trình duyệt** trên web TripTo (mỗi tab đều load `signalr.js`).
2. Mở DevTools → Console: cả 2 tab in `"SignalR connected!"` (bằng chứng kết nối negotiate + WebSocket thành công).
3. Tại tab 1: vào `frontend/user/thanhtoan_chitiet.html`, đặt tour thành công.
4. Quan sát tab 2 (đang ở trang khác): **Toast xanh hiện realtime** "Đặt tour thành công!" kèm mã đặt tour, tên tour, tổng tiền VNĐ — không cần reload trang.
5. (Portal) Function App → **Monitor** → function `negotiate` → xem lần chạy gần nhất **Succeeded**.

**Bằng chứng log trong repo:** Function Host log `2026-08-09T04-10-22Z-03cff5410f.log:592-593`:

```
Executing 'Functions.negotiate' (Reason='This function was programmatically called via the host APIs.', ...)
Executed 'Functions.negotiate' (Succeeded, ..., Duration=454ms)
```

> Không tìm thấy log thực thi của `sendNotification` trong các log Function App lưu trong repo — nhưng code luồng `user.php → sendNotification` là có bằng chứng đầy đủ. Việc Toast hiển thị cần kiểm chứng trực tiếp trên 2 tab như mô tả trên.

## 5.8. Kết quả đạt được

- **Function `negotiate` chạy thành công:** log `Executed 'Functions.negotiate' (Succeeded ...)`.
- **Luồng booking → Backend → SignalR → Frontend → Toast:** được code hoàn chỉnh end-to-end (backend gọi `sendNotification`, output binding SignalR, client lắng nghe `newNotification` và hiển thị Toast).
- **Frontend đã kết nối SignalR:** `frontend/js/signalr.js` chạy `connect()` tự động ở các trang user.

## 5.9. Trạng thái cuối cùng

**Đã hoàn thành và tích hợp thực tế** (code + cấu hình + một phần bằng chứng log `negotiate` Succeeded). Để demo đầy đủ: chạy 2 tab và đặt tour như mục 5.7; kết quả Toast realtime cần kiểm chứng trực tiếp vì repo chưa có log gửi/sự kiện hiển thị Toast.

---

# 6. Azure Notification Hubs

## 6.1. Ý nghĩa của dịch vụ

- **Dịch vụ này là gì:** Azure Notification Hubs là dịch vụ **push notification đa nền tảng** — nhận một thông báo và đẩy tới thiết bị/trình duyệt qua các PNS (Push Notification Service) như FCM (Android), APNs (iOS), WNS, và **Web Push (W3C)** cho trình duyệt.
- **Vai trò trong Azure:** Quản lý **Installation/Registration** (thiết bị/trình duyệt đăng ký), **Tags** (nhóm nhận), gửi broadcast hoặc gửi theo tag, cung cấp debug outcome.
- **Vì sao được dùng trong TripTo:** Gửi **push notification cho trình duyệt (Web Push)** — ngay cả khi trang đang ở nền (background), vẫn hiện thông báo hệ điều hành thông qua **Service Worker**.
- **Vấn đề nó giải quyết:** Bổ sung kênh thông báo nền (background) cho PWA TripTo, bổ trợ cho SignalR (chỉ hoạt động khi trang đang mở).

## 6.2. Vai trò trong hệ thống TripTo

```
Trình duyệt (push-notification.js)
   │ 1) GET /api/GetVapidPublicKey          → lấy VAPID public key
   │ 2) register('/sw.js') + pushManager.subscribe(applicationServerKey)
   │ 3) POST /api/RegisterNotification      → tạo Installation trên hub (platform: browser)
   ▼
[ FUNCTION APP: tripto-function ]
   │  notificationHub.js → NotificationHubsClient (NOTIFICATION_HUB_CONNECTION_STRING, tripto-hub)
   ▼
[ AZURE NOTIFICATION HUBS: tripto-hub ]
   │  (lưu installation browser: endpoint, p256dh, auth; tag user:<userId>)
   ▼  POST /api/SendNotificationHub → createBrowserNotification({title, body})
   ▼
(PNS Web Push / FCM)
   ▼
Service Worker sw.js → showNotification → notification xuất hiện trên trình duyệt
```

## 6.3. Các bước tạo dịch vụ trên Azure

**Không tìm thấy bằng chứng trong repository** về việc tạo resource `tripto-hub` trên Portal (SKU/tier, region, resource group). Xác định được từ code:

| Thông tin | Giá trị / bằng chứng |
|---|---|
| Hub name | `tripto-hub` (default trong `notificationHub.js:10`) |
| Connection string | `NOTIFICATION_HUB_CONNECTION_STRING` (biến môi trường — `notificationHub.js:6-7`) |
| VAPID keys | `VAPID_PUBLIC_KEY` (đọc từ env — `GetVapidPublicKey.js:46`) |

> Không có bằng chứng về tier. Lưu ý trong `notificationHubDebug.js:201` có nhắc rằng API outcome (`getNotificationOutcomeDetails`) *"requires a Standard SKU notification hub"* — gợi ý hub có thể đang dùng tier thấp hơn (Free/Basic), nhưng **đây là nhận định gián tiếp, không có bằng chứng trực tiếp** về SKU trong repo.

## 6.4. Các bước cấu hình sau khi tạo

1. **Viết client khởi tạo hub** (`notificationHub.js`): `createNotificationHubClient()` dùng `NOTIFICATION_HUB_CONNECTION_STRING` + `NOTIFICATION_HUB_NAME || 'tripto-hub'`, trả `new NotificationHubsClient(connectionString, hubName)` (SDK `@azure/notification-hubs`).

2. **Viết function `GetVapidPublicKey.js`**:
   - `GET`/`OPTIONS`, trả `{ publicKey }` từ `VAPID_PUBLIC_KEY`.
   - CORS allowlist: `tripto-gcbmg6gybegye7ex...`, `tripto2-e3g2epfdaahzaqaa...`, `tripto-tm.trafficmanager.net`, `http://localhost:8080` (hoặc biến `CORS_ALLOWED_ORIGINS`).

3. **Viết function `registerNotification.js`**:
   - `POST`/`OPTIONS`; validate `installationId` (regex `^[A-Za-z0-9\-_:]{1,64}$`), `endpoint`, `p256dh`, `auth`.
   - Tạo installation `{ installationId, platform: 'browser', pushChannel: { endpoint, p256dh, auth }, tags: userId ? ['user:'+userId] : [] }`.
   - `client.createOrUpdateInstallation(installation)`.

4. **Viết function `sendNotificationHub.js`**:
   - `POST`/`OPTIONS`, **`authLevel: 'function'`** (cần function key khi gọi).
   - Validate `title`, `body`; tạo `createBrowserNotification({ body: { title, body } })`.
   - Gửi theo tag tuỳ chọn: `options.tagExpression = tag`.
   - Trả `{ success, trackingId }`.

5. **Viết function debug `notificationHubDebug.js`** (các route `NotificationHubDebug/installations`, `.../installation/{id}`, `.../outcome`) — dùng để liệt kê installation, lấy chi tiết installation và outcome (outcome yêu cầu Standard SKU).

6. **Viết client trình duyệt `frontend/js/push-notification.js`**:
   - `isPushSupported()` kiểm tra `serviceWorker`, `PushManager`, `Notification`.
   - `initPushNotifications()`: register `'/sw.js'` → `Notification.requestPermission()` → `getVapidPublicKey()` → `pushManager.subscribe({ userVisibleOnly:true, applicationServerKey })` → gửi `POST /api/RegisterNotification`.
   - Hỗ trợ re-subscribe khi VAPID key đổi; tự sinh/lưu `installationId` trong `localStorage` (key `tripto_notification_installation_id`).

7. **Viết Service Worker `sw.js`**:
   - `push` event → `event.data.json()` → `self.registration.showNotification(title, { body, icon, badge, data:{url} })`.
   - `notificationclick` → focus/`navigate` hoặc `openWindow` (URL mặc định `frontend/user/TRANGCHU.html`).
   - `pushsubscriptionchange` → log cảnh báo sẽ đăng ký lại ở lần nạp trang sau.

8. **Gọi `initPushNotifications()` ở frontend** — gần như mọi trang user (vd `TRANGCHU.html:3684-3685`, `BLOG.html:1913-1914`, `caidat.html:419-420`, `chuyendi.html:1280-1281`, `chitiettour.html:1622-1623`, `thanhtoan.html:487-488`, ...).

## 6.5. Các file trong repository liên quan

| File | Vai trò |
|---|---|
| `backend/function/src/functions/notificationHub.js` | Khởi tạo `NotificationHubsClient` (hub `tripto-hub`) |
| `backend/function/src/functions/registerNotification.js` | API `RegisterNotification` — đăng ký installation trình duyệt |
| `backend/function/src/functions/sendNotificationHub.js` | API `SendNotificationHub` — gửi browser notification (cần function key) |
| `backend/function/src/functions/GetVapidPublicKey.js` | API `GetVapidPublicKey` — cấp VAPID public key |
| `backend/function/src/functions/notificationHubDebug.js` | API debug: liệt kê installation, lấy installation, outcome |
| `frontend/js/push-notification.js` | Client đăng ký Web Push + gọi RegisterNotification |
| `sw.js` (root) | Service Worker: xử lý `push`, `notificationclick`, `pushsubscriptionchange` |
| `frontend/user/*.html` | Gọi `window.initPushNotifications()` khi load trang |
| `backend/function/package.json` | Dependency `@azure/notification-hubs: ^2.1.0` |
| `backend/function/kudu-src-functions.json` | Xác nhận `notificationHub.js`, `registerNotification.js`, `sendNotificationHub.js` đã deploy lên server |

## 6.6. Cách dịch vụ được tích hợp vào TripTo

**Luồng đăng ký (Registration):**

```
Mở trang TripTo → window.initPushNotifications()
   │
   ├── 1) navigator.serviceWorker.register('/sw.js')
   ├── 2) Notification.requestPermission()  → 'granted'
   ├── 3) GET /api/GetVapidPublicKey        → publicKey
   ├── 4) pushManager.subscribe({ userVisibleOnly, applicationServerKey })
   ├── 5) lấy endpoint + p256dh + auth
   └── 6) POST /api/RegisterNotification
            { installationId, endpoint, p256dh, auth, userId }
              │
              ▼
         registerNotification.js → createOrUpdateInstallation
              ▼
         NOTIFICATION HUB (tripto-hub)  → installation platform:'browser'
```

**Luồng gửi notification (theo thiết kế code):**

```
(admin/user/backend) → POST /api/SendNotificationHub
                          { title, body, tag? }  + x-functions-key
   ▼
sendNotificationHub.js → createBrowserNotification({ title, body })
   ▼
NOTIFICATION HUB → Web Push/FCM → trình duyệt
   ▼
sw.js 'push' event → showNotification → notification hiển thị
```

> Lưu ý: trong repository, **chưa tìm thấy** chỗ gọi `SendNotificationHub` từ luồng nghiệp vụ thật (backend booking/admin) — code function gửi đã có, nhưng **chưa thấy nơi trigger**. Việc gửi hiện tại chỉ có thể test thủ công qua HTTP (cần function key).

## 6.7. Cách kiểm thử thực tế

**Phân biệt rõ 3 mức kiểm thử:**

**A. Mức trình duyệt (client + Service Worker) — có bằng chứng trong repo:**

1. Mở web TripTo trong Chrome → DevTools → Console:
   - `Service worker registered with scope: ...` và `Push subscription ready. Endpoint: ...` nếu thành công.
   - (Có thể dùng `window.getPushDebugInfo()` do `push-notification.js` expose để xem `secureContext`, `permission`, `serviceWorkerActive`, `subscription`, `installationId`).
2. DevTools → **Application → Service Workers**: thấy `sw.js` **activated and running**.
3. DevTools → **Application → Push**: thấy subscription endpoint có.
4. Gửi test push thủ công từ DevTools (Application → Service Workers → Push) → quan sát `[sw] push received:` trong Console và **notification hiện ra** — đây là bằng chứng **Service Worker + showNotification hoạt động**.
5. Trong DevTools → Application → Local Storage: thấy key `tripto_notification_installation_id`.

**B. Mức đăng ký lên Notification Hub (server-side):**

1. Gọi `GET /api/GetVapidPublicKey` → nhận `{ publicKey }` (200).
2. Sau khi browser subscribe, gọi `POST /api/RegisterNotification` → nhận `{ success: true, installationId }` (200).
3. (Debug) Gọi API `NotificationHubDebug/installations` (cần function key) → đếm `count` và xem installation `platform: 'browser'` với endpoint/p256dh/auth.

**C. Mức gửi end-to-end (Notification Hub → trình duyệt):**

1. Gọi `POST /api/SendNotificationHub` với `{ title, body }` kèm `x-functions-key`.
2. Nhận `{ success: true, trackingId }`.
3. Kiểm tra **browser có hiện notification hay không** (trang đang mở hoặc background) — **đây là kiểm chứng cuối cùng cần thực hiện trực tiếp**, chưa có bằng chứng trong repository.

## 6.8. Kết quả đạt được

**Phân tách đúng 3 nhóm bằng chứng (theo yêu cầu):**

1. **Những phần đã hoạt động (có bằng chứng code/cấu hình/deploy):**
   - Các function `GetVapidPublicKey`, `RegisterNotification`, `SendNotificationHub`, `notificationHubDebug`, `notificationHub` đã viết đầy đủ và **(một phần) đã deploy** lên Function App (bằng chứng `kudu-src-functions.json` liệt kê `notificationHub.js`, `registerNotification.js`, `sendNotificationHub.js` trên server; `docs/STEPS_DATABASE_STORAGE.md:500` liệt kê nhóm function push notification).
   - Client `push-notification.js` và Service Worker `sw.js` đã viết và được gọi ở nhiều trang frontend.
   - Hub `tripto-hub`, biến `NOTIFICATION_HUB_CONNECTION_STRING`, `VAPID_PUBLIC_KEY` được tham chiếu trong code.

2. **Những phần đã kiểm thử thành công (bằng chứng trong repo):**
   - **Chưa có** log Function App nào trong repository ghi lại việc `RegisterNotification`, `GetVapidPublicKey` hay `SendNotificationHub` được thực thi thành công (đã rà soát toàn bộ `LogFiles/Application/Functions/Host/*.log`).
   - `docs/STEPS_DATABASE_STORAGE.md:598` có ghi *"Push notification cho PWA qua Notification Hubs hoạt động"* — nhưng **đây là khẳng định trong tài liệu, chưa kèm bằng chứng runtime (log/ảnh) trong repo**.

3. **Những phần chưa chứng minh được end-to-end:**
   - **Chưa có bằng chứng** chuỗi `Notification Hub → FCM/Web Push → Service Worker → Browser notification` hoạt động hoàn chỉnh.
   - Việc test Service Worker trong DevTools (nhận push giả, hiển thị `showNotification`) **chỉ chứng minh phần Service Worker phía trình duyệt** — **KHÔNG được dùng làm bằng chứng** rằng Notification Hub đã gửi notification end-to-end.
   - Chưa tìm thấy nơi trigger `SendNotificationHub` từ luồng nghiệp vụ thật trong website.

## 6.9. Trạng thái cuối cùng

**Đã tích hợp ở mức code/cấu hình + một phần deploy, NHƯNG CHƯA hoàn thiện end-to-end.**

- Code đầy đủ: client (`push-notification.js`), Service Worker (`sw.js`), server (`GetVapidPublicKey`, `RegisterNotification`, `SendNotificationHub`, `notificationHubDebug`).
- Một số function đã deploy lên Function App (bằng chứng Kudu).
- **Chưa có bằng chứng trong repository** rằng `Notification Hub (tripto-hub) → FCM/Chrome → Service Worker → Browser notification` hoạt động end-to-end.
- **Không được khẳng định "hoàn thành 100%"** cho Notification Hubs trong báo cáo demo; cần thực hiện và ghi lại kiểm chứng mục 6.7C trước khi tuyên bố hoàn thành.

---

## TỔNG KẾT

| # | Dịch vụ | Tài nguyên / đối tượng chính | Trạng thái trong repository |
|---|---|---|---|
| 1 | API Management | Gateway `tripto-api-management.azure-api.net/tripto/` | ✅ Đã tích hợp thực tế (frontend gọi gateway, backend có CORS). ❌ Không có bằng chứng tạo/Policy/Subscription trong repo |
| 2 | Logic Apps | — | ❌ Không tìm thấy bất kỳ bằng chứng nào trong repository |
| 3 | Communication Services | SMTP qua Function `SendBookingEmail` | ✅ Code + log gửi email Succeeded (ACS SMTP). ❌ Không có bằng chứng tạo resource ACS |
| 4 | Service Bus | `sb://sb-tripto-backend` / `booking-queue` | ✅ Tích hợp gửi message vào luồng booking. ⚠️ Chưa chứng minh consumer xử lý end-to-end |
| 5 | SignalR Service | hub `triptoHub`, event `newNotification` | ✅ Code + cấu hình + log `negotiate` Succeeded. ⚠️ Toast realtime cần kiểm chứng trực tiếp |
| 6 | Notification Hubs | hub `tripto-hub`, Web Push/VAPID, `sw.js` | ⚠️ Code + deploy một phần. ❌ **Chưa chứng minh end-to-end** (Hub → FCM → Service Worker → browser notification) |

### Lưu ý cuối cùng

- Tài liệu này **chỉ ghi những gì có bằng chứng trong repository**. Với các phần thiếu bằng chứng (các bước tạo resource trên Portal, Policy APIM, Logic Apps, trigger `SendNotificationHub`, kiểm chứng notification end-to-end), đã ghi rõ **"Không tìm thấy bằng chứng trong repository."** — cần bổ sung tài liệu/IaC/ảnh Portal/log thực thi để hoàn thiện báo cáo.
- Các bước demo trực tiếp trên lớp nên dựa vào mục "Cách kiểm thử thực tế" của từng dịch vụ và kiểm chứng trước trên Portal/website.
