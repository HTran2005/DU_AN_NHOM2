# BẰNG CHỨNG TEST — 6 DỊCH VỤ BACKEND & INTEGRATION (MÁY 2)

> **Phạm vi:** Tổng hợp bằng chứng thực tế cho 6 dịch vụ:
> 1. API Management (Consumption)
> 2. Logic Apps (Consumption)
> 3. Communication Services
> 4. Service Bus (Basic)
> 5. Azure SignalR Service
> 6. Notification Hubs
>
> **Nguồn bằng chứng:** Chỉ sử dụng dữ liệu có thật trong repository `DU_AN_NHOM2`:
> file cấu hình (`backend/config.php`), code (`backend/servicebus/*.php`, `backend/function/src/functions/*.js`,
> `frontend/js/signalr.js`, `frontend/js/push-notification.js`, `sw.js`), log Function App
> (`backend/function/tripto-function-logs/LogFiles/Application/Functions/Host/*.log`),
> bằng chứng deploy/Kudu (`kudu-src-functions.json`, `deployments/latest.json`), và lịch sử git.
>
> **Quy ước 4 mức chứng minh (phân biệt rõ):**
> - **(a) Resource tồn tại** — có URL/định danh/endpoint tham chiếu trong repo (chưa chứng minh resource thật đang chạy).
> - **(b) Service đã được cấu hình** — có config/code khai báo kết nối (connection string, key, hub, queue...) trong repo.
> - **(c) Service đã được ứng dụng gọi** — có code gọi tới service trong luồng nghiệp vụ thật (backend/frontend).
> - **(d) Service hoạt động end-to-end** — có log/response thực tế chứng minh luồng hoàn chỉnh thành công.
>
> **KHÔNG bịa thêm** lệnh CLI, request, response hay chức năng chưa được kiểm tra.

---

## TỔNG QUAN NHANH

| # | Dịch vụ | Mức chứng minh cao nhất | Kết luận |
|---|---|---|---|
| 1 | API Management (Consumption) | (b) Cấu hình + (c) code frontend gọi qua gateway | **ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END** |
| 2 | Logic Apps (Consumption) | — (không có bằng chứng nào trong repo) | **CHƯA CÓ BẰNG CHỨNG** |
| 3 | Communication Services | (d) Log `SendBookingEmail` Succeeded + SMTP `250 Queued` | **ĐÃ XÁC NHẬN (email thật gửi qua SMTP ACS)** — tạo resource chưa có bằng chứng |
| 4 | Service Bus (Basic) | (b) Config + (c) `user.php` gọi `send()` trong luồng booking | **ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END** |
| 5 | SignalR Service | (d) Log `negotiate` Succeeded | **ĐÃ XÁC NHẬN (negotiate)** — Toast end-to-end chưa có bằng chứng |
| 6 | Notification Hubs | (b) Code + deploy qua Kudu | **ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END** |

> **Lưu ý chung về CLI:** Trong repository **không có output của lệnh `az apim`, `az logicapp`,
> `az communication`, `az servicebus`, `az signalr`, `az notification-hub` nào được ghi lại**.
> Các lệnh CLI duy nhất xuất hiện trong repo thuộc về các máy khác (vd `az maps account create`
> — `docs/STEPS_ACCOUNT1.md`, `az deployment group create` / `az webapp deployment source config-zip`
> — `docs/STEPS_DATABASE_STORAGE.md:560,651` cho tài nguyên máy 3). Vì vậy phần "Lệnh CLI đã chạy"
> của từng dịch vụ dưới đây ghi rõ trạng thái thực tế.

---

# 1. API Management (Consumption)

## Tên dịch vụ
Azure API Management (APIM) — gateway, SKU ghi theo đề bài: **Consumption**.

## Resource thực tế đã kiểm tra
- Gateway host: `tripto-api-management.azure-api.net` (chỉ có trong code frontend — mức (a)/(b)).
- API path prefix: `/tripto/` → mọi request có dạng `https://tripto-api-management.azure-api.net/tripto/user.php`
  hoặc `.../tripto/backend/admin.php`.
- Không có Resource Group / region / subscription / tên API khai báo chính thức trong repo.
- Không có bằng chứng policy, operation, backend config, hay `Ocp-Apim-Subscription-Key` trong repo.

## Azure CLI command đã chạy
**Không có.** Không tìm thấy output của `az apim *` trong repository. Lệnh `az apim create` chỉ được
nhắc đến như gợi ý cần bổ sung (`docs/STEPS_BACKEND_INTEGRATION.md:105`) — **chưa được chạy/ghi nhận**.

## Kết quả / output quan trọng thu được
- Commit `973adf3` (2026-08-08, camlylv2021-ai) "sửa đường dẫn để tích hợp API Management" đổi **20 file frontend**:
  ```diff
  - const apiUrl = '../../user.php';
  + const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/user.php';
  ```
- Kiểm đếm hiện tại trong repo: **18 file HTML** + **2 file JS** tham chiếu `tripto-api-management.azure-api.net`
  (`frontend/js/auth.js`, `frontend/js/microsoft-auth.js`).
- `backend/config.php:36-52`: CORS `Access-Control-Allow-Origin` (theo origin), methods GET/POST/PUT/PATCH/DELETE/OPTIONS,
  `Access-Control-Allow-Credentials: true`, tự trả HTTP 204 cho preflight OPTIONS.

## Ý nghĩa của kết quả
- Frontend TripTo **đã được chuyển sang gọi qua gateway** (mức (c): code ứng dụng gọi) và backend có CORS
  tương thích cross-origin với gateway (mức (b)).
- Tuy nhiên đây chỉ là bằng chứng **ở lớp code/URL** — chưa có log/response nào trong repo chứng minh
  gateway thực tế nhận và chuyển tiếp request (không có request thật, không có response thật của APIM).

## Dịch vụ đang được chứng minh ở mức nào
- (a) Resource tồn tại: **tham chiếu URL gateway trong code** (không có bằng chứng resource thật đang chạy).
- (b) Cấu hình: **có** (CORS backend phục vụ gateway).
- (c) Được ứng dụng gọi: **có** (toàn bộ frontend gọi `...azure-api.net/tripto/...`).
- (d) End-to-end: **KHÔNG có bằng chứng** (không có log/response gateway).

## Kết luận
**ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END.**

## Liên hệ TripTo
Toàn bộ API user/admin của TripTo được frontend gọi qua gateway `tripto-api-management.azure-api.net/tripto/`
thay vì gọi thẳng backend PHP.

---

# 2. Logic Apps (Consumption)

## Tên dịch vụ
Azure Logic Apps — workflow orchestration, SKU ghi theo đề bài: **Consumption**.

## Resource thực tế đã kiểm tra
**Không có.** Không tìm thấy bất kỳ resource, tên Logic App, URL, workflow, trigger, action nào trong repository.

## Azure CLI command đã chạy
**Không có.** Không tìm thấy output của `az logicapp *` hay `az resource` liên quan Logic Apps.

## Kết quả / output quan trọng thu được
- Không có file khai báo workflow, không có Run History (Succeeded/Failed), không có link Logic App.
- Lưu ý: từ khoá "workflow" trong repo chỉ là **GitHub Actions / Azure Pipelines** (`.github/workflows/*.yml`,
  `azure-pipelines.yml`) — **không liên quan Azure Logic Apps** (`docs/STEPS_BACKEND_INTEGRATION.md:230`).

## Ý nghĩa của kết quả
Không có bằng chứng nào về việc Logic Apps được tạo, cấu hình, hay nhận message từ Service Bus.

## Dịch vụ đang được chứng minh ở mức nào
- (a) Resource tồn tại: **KHÔNG**.
- (b) Cấu hình: **KHÔNG**.
- (c) Được ứng dụng gọi: **KHÔNG**.
- (d) End-to-end: **KHÔNG**.

## Kết luận
**CHƯA CÓ BẰNG CHỨNG** trong repository.

## Liên hệ TripTo
Không có mối liên hệ nào với TripTo được chứng minh (giả định "Service Bus → Logic App" trong đề bài
**không có bằng chứng** trong repo — không tìm thấy consumer nhận `booking-queue`).

---

# 3. Communication Services

## Tên dịch vụ
Azure Communication Services (ACS) — dùng làm **SMTP relay** để gửi email xác nhận đặt tour.

## Resource thực tế đã kiểm tra
- Không có tên resource ACS / domain / sender / region / resource group khai báo trong repo.
- Bằng chứng gián tiếp mạnh: **Message ID trả về chứa domain `...@f7fbfdda-bbcd-443b-8b1c-e3b573539f61.azurecomm.net`**
  → SMTP server thuộc Azure Communication Services.
- Các biến cấu hình SMTP: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM`
  (đọc từ App Settings của Function App — `docs/STEPS_DATABASE_STORAGE.md:574`).

## Azure CLI command đã chạy
**Không có.** Không tìm thấy output của `az communication *` trong repository.

## Kết quả / output quan trọng thu được
Log Function App — `2026-08-08T16-42-53Z-d3c4286ca1.log:62-97` (trích yếu):
```
Executing 'Functions.SendBookingEmail' ...
SMTP_HOST exists: true / SMTP_PORT exists: true / SMTP_USERNAME exists: true / SMTP_PASSWORD exists: true / MAIL_FROM exists: true
✅ ACS SMTP connection successful
Email người nhận: camlylv2021@gmail.com
Accepted: [ 'camlylv2021@gmail.com' ]
Rejected: []
Message ID: <d022cd44-ebc9-705a-4d53-8d253d8bc4d1@f7fbfdda-bbcd-443b-8b1c-e3b573539f61.azurecomm.net>
SMTP Response: 250 2.6.0 8a86daed-f411-4b0e-9e6d-58afcdf4b90b Queued mail for delivery
Executed 'Functions.SendBookingEmail' (Succeeded, ..., Duration=5632ms)
```
Các lần chạy thành công khác cùng nội dung `ACS SMTP connection successful` + `Accepted`:
- `2026-08-08T17:06:53.752` → `Accepted: ['0023411831@student.dthu.edu.vn']`, Succeeded (d3c4286ca1.log:125-133).
- `2026-08-08T17:07:25.692` / `17:07:26.428` → `Accepted: ['camlylv2021@gmail.com']` + `['0023411831@student.dthu.edu.vn']`, Succeeded (d3c4286ca1.log:188-205).
- `2026-08-09T03:00:22.486` → `Accepted: ['0023412018@student.dthu.edu.vn']`, Succeeded, Duration=3624ms (210acc5f17.log:58-66).
- 2 lần chạy trước đó (12:54 ngày 08/08) cũng Succeeded với `Accepted: ['camlylv2021@gmail.com']` (75d6f6edcc.log:44,77).

## Ý nghĩa của kết quả
- Đây là bằng chứng mạnh nhất trong 6 dịch vụ: function **thực thi thật**, kết nối SMTP ACS thành công
  (`✅ ACS SMTP connection successful`), email **được server chấp nhận** (`Accepted`) với `SMTP Response: 250 ... Queued mail for delivery`
  và Message ID thuộc domain `azurecomm.net` → **email xác nhận đặt tour đã được gửi qua ACS end-to-end** (mức d).
- Code gửi: `backend/function/src/functions/SendBookingEmail.js` (nodemailer → `SMTP_HOST/PORT`, `transporter.verify()`, `sendMail()`).
- Frontend gọi thật: `frontend/user/thanhtoan_chitiet.html:1689` gọi
  `POST https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/SendBookingEmail`
  sau khi đặt tour thành công (mức c).

## Dịch vụ đang được chứng minh ở mức nào
- (a) Resource tồn tại: **gián tiếp** (Message ID `azurecomm.net` + cấu hình SMTP). Không có tên resource khai báo.
- (b) Cấu hình: **có** (5 biến `SMTP_*`/`MAIL_FROM` + code nodemailer).
- (c) Được ứng dụng gọi: **có** (frontend gọi `/api/SendBookingEmail` khi đặt tour).
- (d) End-to-end: **CÓ — log Succeeded + Accepted + SMTP 250 + Message ID azurecomm.net**.

## Kết luận
**ĐÃ XÁC NHẬN hoạt động end-to-end (gửi email thật qua SMTP ACS).**
Tạo resource ACS (Portal/CLI), domain, sender chưa có bằng chứng trong repo — chỉ suy ra từ Message ID.

## Liên hệ TripTo
Email "Xác nhận đặt tour thành công" gửi đến khách hàng sau khi đặt tour thành công trên `thanhtoan_chitiet.html`.

---

# 4. Service Bus (Basic)

## Tên dịch vụ
Azure Service Bus — message broker, SKU ghi theo đề bài: **Basic**.

## Resource thực tế đã kiểm tra
- Namespace endpoint: `sb://sb-tripto-backend.servicebus.windows.net/` (`backend/config.php:61-65`).
- Queue: `booking-queue` (`backend/config.php:68-72`).
- Shared Access Policy: `RootManageSharedAccessKey` (`backend/config.php:75-79`).
- Key: đọc từ biến môi trường `SERVICEBUS_KEY` — **không hardcode** (`backend/config.php:82-86`).
- Không có Resource Group / region khai báo trong repo.

## Azure CLI command đã chạy
**Không có.** Không tìm thấy output của `az servicebus *` trong repository. Lệnh `az servicebus ...` chỉ được
nhắc đến như gợi ý (`docs/STEPS_BACKEND_INTEGRATION.md:420`) — **chưa được chạy/ghi nhận**.

## Kết quả / output quan trọng thu được
- Code helper hoàn chỉnh `backend/servicebus/ServiceBus.php`: tự sinh SAS token (HMAC-SHA256),
  `send()` → `POST {queue}/messages` (header `BrokerProperties: {"Label":"TripTo Booking"}`),
  `receive()` → `POST {queue}/messages/head` (Peek-Lock), `deleteMessage($location)` → DELETE.
- Endpoint test: `backend/servicebus/sendMessage.php` (POST, bắt buộc `booking_id, tour_id, user_id, customer_name, email, phone, price`;
  trả `{"success":true,"status":201,"message":"Message sent successfully."}`) và `backend/servicebus/receiveMessage.php`
  (trả `queue_message` + `delete_result`).
- Tích hợp luồng booking thật — `backend/user.php:4076-4089`: sau khi ghi DB, gọi
  `$serviceBus->send([... booking_id, tour_id, user_id, customer_name, email, phone, price, tour_name, depart_date, booking_code, adults, children ...])`.
- Commit liên quan: `30f809d` (02/08), `762bdbb`, `3cbc9ef`, `7db3c34` (05/08), `42183aa` (06/08),
  `c1da73b` (07/08), `5c8a6bf` (08/08 — fix đường dẫn + double-include guard).

## Ý nghĩa của kết quả
- Namespace, queue, policy, SAS, code send/receive/delete đều **đã cấu hình và viết đủ** (mức b).
- `user.php` **gọi `send()` trong luồng đặt tour thật** (mức c).
- **CHƯA có** output/log thực tế trong repo chứng minh message đã xuất hiện trong queue (không có response của
  `send()`, không có ảnh/log Portal Service Bus Explorer, không có consumer nhận message).

## Dịch vụ đang được chứng minh ở mức nào
- (a) Resource tồn tại: **tham chiếu endpoint/queue trong config** (không có bằng chứng resource thật đang chạy).
- (b) Cấu hình: **có** (config + ServiceBus.php).
- (c) Được ứng dụng gọi: **có** (user.php gửi message sau booking).
- (d) End-to-end: **KHÔNG có bằng chứng** (không có log/response gửi-thành-công; không có consumer).

## Kết luận
**ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END.**

## Liên hệ TripTo
Backend TripTo gửi message booking lên queue `booking-queue` của namespace `sb-tripto-backend` sau khi khách đặt tour.
Chưa có bằng chứng consumer nào (Logic App/Function) xử lý message.

---

# 5. Azure SignalR Service

## Tên dịch vụ
Azure SignalR Service — real-time WebSocket push. SKU không khai báo trong repo.

## Resource thực tế đã kiểm tra
- Hub: `triptoHub` (`backend/function/src/functions/negotiate.js:6`, `sendNotification.js:6`).
- App Setting trên Function App: `AzureSignalRConnectionString` (`docs/STEPS_DATABASE_STORAGE.md:575`;
  `negotiate.js:7`, `sendNotification.js:7`).
- Route: `/api/negotiate`, `/api/sendNotification` trên Function App `tripto-function`.
- Không có Resource Group / region / SKU khai báo trong repo.

## Azure CLI command đã chạy
**Không có.** Không tìm thấy output của `az signalr *` trong repository.

## Kết quả / output quan trọng thu được
Log Function App — `2026-08-09T04-10-22Z-03cff5410f.log:592-593`:
```
2026-08-09T05:29:53.853 Executing 'Functions.negotiate' (Reason='This function was programmatically called via the host APIs.', Id=f8171a80-...)
2026-08-09T05:29:54.287 Executed 'Functions.negotiate' (Succeeded, Id=f8171a80-..., Duration=454ms)
```
- Code server: `negotiate.js` (input binding `signalRConnectionInfo`, hub `triptoHub`, trả `{url, accessToken}`),
  `sendNotification.js` (output binding, gửi event `newNotification`).
- Client: `frontend/js/signalr.js` — gọi `/api/negotiate`, `HubConnectionBuilder().withUrl(data.url, { accessTokenFactory })`,
  `connection.on('newNotification', handleNotification)`, log `SignalR connected!`. Được nạp ở 3 trang:
  `frontend/user/TRANGCHU.html`, `thanhtoan_chitiet.html`, `chitiettour.html`.
- Backend trigger: `backend/user.php:4091-4122` — sau booking, `curl POST /api/sendNotification`
  với payload `{ type:'booking_success', bookingCode, tourName, departDate, totalPrice, ... }`.
- Commit liên quan: `0871381`, `b8cfcf7`, `2d80a87`, `e5dd61a`, `b91c313`, `245be02` (09/08).

## Ý nghĩa của kết quả
- **`negotiate` chạy Succeeded với Duration=454ms** → input binding SignalR đã giải quyết được `AzureSignalRConnectionString`
  và **trả về connection info hợp lệ** = connection string SignalR trên Function App **hoạt động thật** (mức d cho bước negotiate).
- Code backend → sendNotification → SignalR → client → Toast đã được viết đầy đủ (mức b, c).

## Dịch vụ đang được chứng minh ở mức nào
- (a) Resource tồn tại: **gián tiếp** — `negotiate` trả connection info thành công nghĩa là SignalR service thật đang phục vụ.
- (b) Cấu hình: **có** (hub `triptoHub`, `AzureSignalRConnectionString`, bindings).
- (c) Được ứng dụng gọi: **có** (negotiate được gọi; sendNotification được backend gọi sau booking).
- (d) End-to-end: **một phần** — negotiate Succeeded; **CHƯA có** log thực thi `sendNotification`
  và chưa có bằng chứng Toast hiển thị trên trình duyệt.

## Kết luận
**ĐÃ XÁC NHẬN (negotiate/connection) NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END (sendNotification + Toast).**

## Liên hệ TripTo
Khi khách đặt tour thành công, backend gọi `/api/sendNotification` để đẩy sự kiện `newNotification`
tới các trình duyệt đang kết nối hub `triptoHub` (dự kiến hiện Toast realtime).

---

# 6. Notification Hubs

## Tên dịch vụ
Azure Notification Hubs — push notification (Web Push/PWA). SKU không khai báo trong repo
(chú thích trong code gợi ý có thể không phải Standard: API outcome *"requires a Standard SKU"* — `notificationHubDebug.js:201`).

## Resource thực tế đã kiểm tra
- Hub name: `tripto-hub` (default trong `backend/function/src/functions/notificationHub.js:10`,
  qua `NOTIFICATION_HUB_NAME || "tripto-hub"`).
- Connection string: `NOTIFICATION_HUB_CONNECTION_STRING` (`notificationHub.js:6-7`).
- VAPID key: `VAPID_PUBLIC_KEY` (`GetVapidPublicKey.js:46`).
- Không có Resource Group / region / SKU khai báo trong repo.

## Azure CLI command đã chạy
**Không có.** Không tìm thấy output của `az notification-hub *` trong repository.

## Kết quả / output quan trọng thu được
- Code server đầy đủ: `notificationHub.js`, `registerNotification.js` (tạo installation `platform: 'browser'`,
  tags `user:<userId>`), `sendNotificationHub.js` (authLevel `function`, `createBrowserNotification`, trả `trackingId`),
  `GetVapidPublicKey.js` (trả `{publicKey}`), `notificationHubDebug.js`.
- Code client: `frontend/js/push-notification.js` (register `sw.js` → `Notification.requestPermission()`
  → lấy VAPID key → `pushManager.subscribe()` → `POST /api/RegisterNotification`), `sw.js` (xử lý `push`, `showNotification`, `notificationclick`).
- **17 file HTML** frontend gọi `window.initPushNotifications()`.
- **Deploy đã xác nhận qua Kudu**: `kudu-src-functions.json` liệt kê trên server
  `notificationHub.js`, `registerNotification.js`, `sendNotificationHub.js` (mtime `2026-08-09T17:46:10+00:00`),
  cùng `GetVapidPublicKey.js`, `SendBookingEmail.js`, `negotiate.js`, `sendNotification.js`.
- Commit liên quan: `9f9b335` (09/08), `54c48df` (10/08 — thêm Notification Hub).

## Ý nghĩa của kết quả
- Code + cấu hình (hub `tripto-hub`, connection string, VAPID) **đầy đủ** (mức b) và **đã deploy lên server** (bằng chứng Kudu).
- **CHƯA có** log Function App nào trong repo ghi nhận `GetVapidPublicKey`, `RegisterNotification` hay `SendNotificationHub`
  được thực thi (đã rà soát toàn bộ `LogFiles/Application/Functions/Host/*.log`).
- **Chưa có** bằng chứng chuỗi `Notification Hub → Web Push → Service Worker → Browser notification` hoạt động end-to-end.
- Chưa tìm thấy nơi trigger `SendNotificationHub` từ luồng nghiệp vụ thật trong website.

## Dịch vụ đang được chứng minh ở mức nào
- (a) Resource tồn tại: **tham chiếu hub `tripto-hub` trong code** (không có bằng chứng resource thật đang chạy).
- (b) Cấu hình: **có** (code + deploy qua Kudu).
- (c) Được ứng dụng gọi: **có ở phía client** (17 trang gọi `initPushNotifications()`); **chưa có** ở luồng gửi nghiệp vụ.
- (d) End-to-end: **KHÔNG có bằng chứng**.

## Kết luận
**ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END.**

## Liên hệ TripTo
PWA TripTo đăng ký Web Push qua `sw.js` + `push-notification.js` để nhận notification nền;
hub dự kiến `tripto-hub`. Việc gửi hiện chỉ có thể test thủ công qua `/api/SendNotificationHub` (cần function key).

---

## TỔNG KẾT CHUNG

| # | Dịch vụ | Bằng chứng code/config | Bằng chứng deploy | Bằng chứng runtime (log/response) | Kết luận |
|---|---|---|---|---|---|
| 1 | API Management | Có (frontend gọi gateway + CORS) | — | Không | **ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END** |
| 2 | Logic Apps | Không | — | Không | **CHƯA CÓ BẰNG CHỨNG** |
| 3 | Communication Services | Có (SMTP_* + nodemailer) | Có (Kudu) | **Có** (Succeeded + Accepted + SMTP 250 + azurecomm.net) | **ĐÃ XÁC NHẬN** |
| 4 | Service Bus | Có (config + ServiceBus.php + user.php) | — | Không | **ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END** |
| 5 | SignalR Service | Có (negotiate + sendNotification + client) | Có (Kudu) | **Có** (negotiate Succeeded) | **ĐÃ XÁC NHẬN (negotiate)** |
| 6 | Notification Hubs | Có (5 function + client + sw.js) | Có (Kudu) | Không | **ĐÃ CẤU HÌNH NHƯNG CHƯA ĐỦ BẰNG CHỨNG END-TO-END** |

### Ghi chú cuối
- Mọi tên resource, Resource Group (không có RG khai báo cho 6 dịch vụ trong repo), endpoint
  (`tripto-api-management.azure-api.net`, `sb://sb-tripto-backend.servicebus.windows.net/`),
  queue (`booking-queue`), hub (`triptoHub`, `tripto-hub`), Function App (`tripto-function`) được giữ nguyên
  theo đúng giá trị trong repository.
- Toàn bộ bằng chứng nêu trên đều là dữ liệu có thật trong repo; các phần thiếu bằng chứng được ghi rõ
  "Không có" / "CHƯA" thay vì suy diễn.
