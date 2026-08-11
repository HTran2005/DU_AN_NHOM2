# VERIFY BACKEND & INTEGRATION SERVICES (Azure CLI - thực tế)

- **Ngày kiểm tra:** 11/08/2026
- **Subscription:** `Azure for Students` (`bbad92f7-b7ef-4fa7-b3ef-61c200f5802e`)
- **Cách kiểm tra:** 100% bằng Azure CLI (`az`) + gọi HTTP thực tế. Không sửa cấu hình, không tạo thêm tài nguyên.
- **Tổng quan resource tìm thấy trong subscription (Backend & Integration):**

| Resource | Type | RG | Location | SKU |
|---|---|---|---|---|
| `tripto-api-management` | Microsoft.ApiManagement/service | Backend-Ly | southeastasia | **Consumption** |
| `tripto-logicapp` | Microsoft.Logic/workflows | Backend-Ly | southeastasia | Consumption (Logic App) |
| `tripto-communication` | Microsoft.Communication/CommunicationServices | Backend-Ly | global | — |
| `tripto-email` + `tripto-email/AzureManagedDomain` | EmailServices / Domains | Backend-Ly | global | — |
| `sb-tripto-backend` | Microsoft.ServiceBus/namespaces | Backend-Ly | southeastasia | **Basic** |
| `tripto-signalr` | Microsoft.SignalRService/SignalR | Backend-Ly | southeastasia | **Free_F1** |
| `tripto-notification` + `tripto-notification/tripto-hub` | NotificationHubs namespaces/notificationHubs | Backend-Ly | southeastasia | **Free** |

> Ghi chú: Resource `servicebus` trong RG `Backend-Ly` không phải Service Bus namespace, mà là Logic App connector (`Microsoft.Web/connections`) — chính là connection `servicebus` mà Logic App dùng để trigger queue.

---

## 1. API Management (Consumption)

### Resource thực tế
- **Azure Resource:** `/subscriptions/bbad92f7-b7ef-4fa7-b3ef-61c200f5802e/resourceGroups/Backend-Ly/providers/Microsoft.ApiManagement/service/tripto-api-management`
- **Location:** Southeast Asia
- **SKU:** `Consumption` (capacity 0)
- **Gateway URL:** `https://tripto-api-management.azure-api.net`
- **ProvisioningState:** `Succeeded`
- **Publisher:** `Nhom2` (`camlylv2021@gmail.com`)
- **Created:** 2026-08-04T14:31:12Z

### Lệnh Azure CLI đã dùng
```bash
az apim show --name tripto-api-management --resource-group Backend-Ly
az apim api list --service-name tripto-api-management --resource-group Backend-Ly
az apim api show --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto
az apim api operation list --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto
az apim api operation show --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto --operation-id 6a72064ebde74dcc519a5712
az apim api revision list --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto
# Policy + backend lấy qua REST (az apim không có subcommand policy/backend):
az rest --url "https://management.azure.com/subscriptions/.../apis/tripto/policies/policy?api-version=2022-08-01&format=raw"
az rest --url "https://management.azure.com/subscriptions/.../backends?api-version=2022-08-01"
```

### Kết quả thực tế từ Azure CLI
- API duy nhất: **`tripto`** — path `/tripto`, protocol `https`, subscriptionRequired=`False`, revision 1 (`IsOnline: True`).
- 8 operations được tạo tự động cho mọi HTTP method: `tripto_GET`, `tripto_POST`, `tripto_PUT`, `tripto_DELETE`, `tripto_PATCH`, `tripto_HEAD`, `tripto_OPTIONS`, `tripto_TRACE`, **urlTemplate = `/*`** (pass-through proxy cho mọi path).
- API policy: `set-backend-service ... backend-id="WebApp_tripto"` → backend `WebApp_tripto` có `url: https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net` trỏ vào **Web App `tripto`** (RG `Frontend-Dung`, state `Running`).
- Subscription: `master` (Built-in all-access, scope toàn service) — active.

### Bằng chứng dịch vụ được cấu hình
- APIM có API `tripto` + 8 operations + policy gắn backend `WebApp_tripto` (webapp `tripto`) — cấu hình hoàn chỉnh.

### Bằng chứng dịch vụ thực sự được ứng dụng sử dụng / hoạt động
Request thực tế qua gateway APIM:

| Request (qua `https://tripto-api-management.azure-api.net`) | Kết quả |
|---|---|
| `GET /tripto` | **200** — trả HTML `<meta http-equiv="refresh" content="0; url=frontend/user/TRANGCHU.html">` |
| `GET /tripto/frontend/user/TRANGCHU.html` | **200** — ContentLength 140.973, Title `Tripto - ... Chuyến Du Lịch Việt Nam` |
| `GET /tripto/user.php?endpoint=get_locations` | **200** — JSON `{"success":true,"data":[{"id":31,"ten":"An Giang",...}]}` (dữ liệu thật) |
| `GET /tripto/user.php?endpoint=get_tours&limit=2&offset=0` | **200** — JSON `{"success":true,"data":[{"id":587,...}]}` (tour thật) |

- Trong repo: **20+ file frontend HTML/JS** gọi `https://tripto-api-management.azure-api.net/tripto/...` (ví dụ `frontend/user/TRANGCHU.html:2258`, `frontend/admin/ThanhToan.html:966`, `frontend/js/auth.js:66`, `frontend/js/microsoft-auth.js:115`).
- Backend webapp `tripto` nhận request thông qua APIM (request `/api/ping` trực tiếp tới webapp trả 404 vì không tồn tại endpoint đó, không phải lỗi APIM).

### Giải thích vai trò trong Tripto
APIM là **gateway duy nhất** phía trước toàn bộ backend PHP (`user.php`, `admin.php`). Mọi request từ frontend user/admin đều đi qua `https://tripto-api-management.azure-api.net/tripto/...` → APIM proxy tới Web App `tripto`. Đây là lớp reverse-proxy + điểm kiểm soát API của hệ thống.

### Kết quả test
**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG HOÀN CHỈNH.** APIM proxy request thật thành công (200, trả dữ liệu thật), được frontend sử dụng rộng rãi.

---

## 2. Logic Apps (Consumption)

### Resource thực tế
- **Azure Resource:** `/subscriptions/.../resourceGroups/Backend-Ly/providers/Microsoft.Logic/workflows/tripto-logicapp`
- **Location:** southeastasia
- **State:** `Enabled`, ProvisioningState: `Succeeded`
- **Access endpoint:** `https://prod-15.southeastasia.logic.azure.com:443/workflows/d9b7dafe89f740f3987b24cbb2ffe04f`

### Cấu hình workflow (từ `az logic workflow show`)
- **Trigger:** `When one or more messages arrive in a queue (auto-complete)` — Service Bus connection `servicebus` → queue **`booking-queue`**, poll mỗi **3 phút**, `maxMessageCount=20`, `splitOn` triggerBody.
- **Action:** `Send_booking_email` — HTTP POST tới Function App `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/SendBookingEmail` với body gồm `booking_code, depart_date, email, customer_name, phone, price, tour_name`.

### Lệnh Azure CLI đã dùng
```bash
az logic workflow show --name tripto-logicapp --resource-group Backend-Ly
# (az logic extension chỉ hỗ trợ workflow show/integration-account, không có run/trigger — dùng REST qua az rest)
az rest --url "https://management.azure.com/subscriptions/.../workflows/tripto-logicapp/runs?api-version=2019-05-01"
az rest --url "https://management.azure.com/subscriptions/.../workflows/tripto-logicapp/runs/<runId>/actions?api-version=2019-05-01"
az rest --url "https://management.azure.com/subscriptions/.../workflows/tripto-logicapp/triggers/When_one_or_more_messages_arrive_in_a_queue_%28auto-complete%29/histories?api-version=2019-05-01"
```

### Kết quả thực tế từ Azure CLI
- **Run history (REST):** 30+ run, **toàn bộ `Succeeded`**, ví dụ:
  - `08584151890707141972322598287CU33` — start 2026-08-11T03:10:14, end 03:10:21, **Succeeded**
  - `08584151896121788785606293084CU06` — 2026-08-11T03:01:13, **Succeeded**
  - `08584151914196719566890958430CU34` — 2026-08-11T02:31:05, **Succeeded**
  - ... (các run từ 2026-08-07 đến 08-11 đều Succeeded)
- **Action `Send_booking_email` trong run `...CU33`:** `status=Succeeded`, `code=OK`, start 03:10:15 → end 03:10:21.
- **Trigger history:** có 2 lần `fired=true` với `status=Succeeded` (03:10:14, 03:01:13 ngày 11/08), các lần còn lại `Skipped` (poll không có message). Trigger đang `Enabled`.

### Bằng chứng dịch vụ được cấu hình
- Workflow definition đầy đủ: trigger Service Bus + action gửi email HTTP. Connection `servicebus` → connector `Microsoft.Web/locations/southeastasia/managedApis/servicebus`.

### Bằng chứng dịch vụ thực sự được ứng dụng sử dụng / hoạt động
- Có **run Succeeded thật** liên tục từ 07/08 đến 11/08, trong đó 2 run bắt nguồn từ trigger **fired thật** (message đến từ queue `booking-queue`).
- Action gửi email hoàn tất với code `OK`.

### Giải thích vai trò trong Tripto
Logic App là mắt xích giữa **Service Bus** và **email**: mỗi khi có booking mới, backend `user.php` đẩy message vào queue `booking-queue` → Logic App (poll 3 phút) nhận message → gọi Function `SendBookingEmail` (Communication Services SMTP) gửi email xác nhận đặt tour cho khách.

### Kết quả test
**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG.** Nhiều run Succeeded, action email Succeeded, trigger đã fired từ message Service Bus thật.

---

## 3. Communication Services (Email)

### Resource thực tế
- **Communication Service:** `/subscriptions/.../resourceGroups/Backend-Ly/providers/Microsoft.Communication/CommunicationServices/tripto-communication`
- **HostName:** `tripto-communication.unitedstates.communication.azure.com` (dataLocation: United States, location global)
- **ProvisioningState:** `Succeeded`
- **linkedDomains:** `/.../emailServices/tripto-email/domains/AzureManagedDomain`
- **EmailService:** `tripto-email` (Succeeded, dataLocation United States)
- **Email Domain:** `tripto-email/AzureManagedDomain` (domainManagement: `AzureManaged`, fromSenderDomain: `f7fbfdda-bbcd-443b-8b1c-e3b573539f61.azurecomm.net`)

### Lệnh Azure CLI đã dùng
```bash
az communication show --name tripto-communication --resource-group Backend-Ly
az communication list --resource-group Backend-Ly
az communication email list --resource-group Backend-Ly
az communication email domain show --email-service-name tripto-email --resource-group Backend-Ly --domain-name AzureManagedDomain
az rest --url "https://management.azure.com/subscriptions/.../emailServices/tripto-email/domains?api-version=2023-04-01"
```

### Kết quả thực tế từ Azure CLI
- Communication Service `tripto-communication` liên kết domain `AzureManagedDomain` — **sẵn sàng nhận mail**.
- Email Domain **Azure Managed** (`AzureManaged`) — DNS do Azure quản lý, không cần verify TXT của khách.
- **Trạng thái xác minh domain: tất cả `Verified`** — `Domain`, `SPF`, `DKIM`, `DKIM2`, `DMARC` đều `status: Verified`.

### Bằng chứng dịch vụ được cấu hình
- Resource ACS + EmailService + Domain AzureManaged với toàn bộ bản ghi xác minh **Verified** — cấu hình hợp lệ.

### Bằng chứng dịch vụ thực sự được ứng dụng sử dụng / hoạt động
- **Test gửi email thật qua Function `SendBookingEmail`** (SMTP ACS):
  ```
  POST https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/SendBookingEmail
  {"name":"Test Verification","email":"test.noreply.verification@gmail.com","tour":"Test Tour",...}
  → HTTP 200 {"success":true,"message":"Đã gửi email xác nhận thành công.",
               "email":"...","accepted":["test.noreply.verification@gmail.com"],"rejected":[]}
  ```
  → SMTP ACS **chấp nhận email** (accepted, không có rejected).
- Trong repo: `backend/function/src/functions/SendBookingEmail.js` dùng `nodemailer` với `SMTP_HOST/PORT/USERNAME/PASSWORD/MAIL_FROM` (ACS), `transporter.verify()` + `sendMail()`. Frontend `frontend/user/thanhtoan_chitiet.html:1689` gọi `POST /api/SendBookingEmail` sau khi đặt tour.
- Docs trước đó (`TEST_DICHVU_MAY2.md`) ghi nhận log Function App: `Accepted: ['camlylv2021@gmail.com']`, `SMTP Response: 250 ... Queued mail for delivery`, Message ID thuộc `@f7fbfdda-....azurecomm.net` — **email đã gửi qua ACS end-to-end**.

### Giải thích vai trò trong Tripto
Communication Services cung cấp kênh **email xác nhận đặt tour**. Flow: booking → (Logic App) → Function `SendBookingEmail` → SMTP Azure Communication Services (domain `azurecomm.net`) → email đến khách hàng.

### Kết quả test
**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG HOÀN CHỈNH.** Resource + EmailService + Domain Verified + gửi email thực tế thành công (accepted, rejected rỗng).

---

## 4. Service Bus (Basic)

### Resource thực tế
- **Azure Resource:** `/subscriptions/.../resourceGroups/Backend-Ly/providers/Microsoft.ServiceBus/namespaces/sb-tripto-backend`
- **Location:** southeastasia
- **SKU:** `Basic` (tier Basic)
- **Endpoint:** `https://sb-tripto-backend.servicebus.windows.net:443/`
- **Status:** `Active`, ProvisioningState: `Succeeded`, MinimumTlsVersion 1.2
- **Queue:** `booking-queue` (status `Active`, max size 1024 MB, lock 1 phút, `messageCount=0`, dead-letter 0)

### Lệnh Azure CLI đã dùng
```bash
az servicebus namespace show --name sb-tripto-backend --resource-group Backend-Ly
az servicebus queue list --namespace-name sb-tripto-backend --resource-group Backend-Ly
az servicebus queue authorization-rule list --namespace-name sb-tripto-backend --resource-group Backend-Ly --queue-name booking-queue
az monitor metrics list --resource /subscriptions/.../Microsoft.ServiceBus/namespaces/sb-tripto-backend --metric "IncomingMessages" --aggregation Total --start-time 2026-08-01T00:00:00Z --end-time 2026-08-11T23:59:59Z --interval PT6H
```

### Kết quả thực tế từ Azure CLI
- Namespace Basic hoạt động, queue `booking-queue` tồn tại. Queue chỉ có rule mặc định `RootManageSharedAccessKey` (cấp namespace) — phù hợp Basic tier (không hỗ trợ topics).
- **Metric `IncomingMessages` (message thực tế vào queue):** tổng **44 message** trong khoảng 01/08 → 11/08, phân bố:
  - 08-01: 1 | 08-06: 1 | 08-07: 9+7=16 | 08-08: 5+4+3=12 | 08-09: 1+4=5 | 08-10: 3 | 08-11: 6
- `messageCount` hiện tại = 0 — phù hợp với việc Logic App poll 3 phút và **tiêu thụ hết message** (khớp với run Succeeded ở mục 2).

### Bằng chứng dịch vụ được cấu hình
- Namespace Basic + queue `booking-queue` + SAS policy mặc định. Logic App connection `servicebus` trỏ vào namespace này.

### Bằng chứng dịch vụ thực sự được ứng dụng sử dụng / hoạt động
- **44 message thật đã đi vào queue** (metric IncomingMessages) — nghĩa là backend có gửi message.
- Backend repo: `backend/config.php:64` `SERVICEBUS_ENDPOINT = sb://sb-tripto-backend.servicebus.windows.net/`, `SERVICEBUS_QUEUE = booking-queue`; `backend/user.php:4076` gọi `$serviceBus->send([...booking_id, email, price...])` sau khi tạo booking thành công; `backend/servicebus/ServiceBus.php` + `sendMessage.php`/`receiveMessage.php` là client.
- Message được tiêu thụ (messageCount=0) bởi Logic App `tripto-logicapp` (bằng chứng run Succeeded) → chứng minh chuỗi **Service Bus → Logic App → email** hoạt động.

### Giải thích vai trò trong Tripto
Service Bus là **hàng đợi tin cậy cho luồng đặt tour (booking)**: backend đặt tour thành công → push message `booking-queue` → Logic App tiêu thụ → gửi email xác nhận. Giúp booking không bị mất nếu hàm gửi email tạm lỗi (hàng đợi giữ message đến khi xử lý).

### Kết quả test
**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG.** 44 message thực tế vào queue, được Logic App tiêu thụ (0 message tồn), chuỗi end-to-end đã chạy.

---

## 5. Azure SignalR Service

### Resource thực tế
- **Azure Resource:** `/subscriptions/.../resourceGroups/Backend-Ly/providers/Microsoft.SignalRService/SignalR/tripto-signalr`
- **Location:** southeastasia
- **SKU:** `Free_F1` (Free, capacity 1)
- **HostName:** `tripto-signalr.service.signalr.net`
- **ServiceMode:** `Serverless`, **CORS:** `allowedOrigins: ["*"]`
- **Network ACL:** defaultAction `Deny` nhưng ipRules Allow `0.0.0.0/0` + `::/0`; publicNetwork Allow ClientConnection/ServerConnection/RESTAPI/Trace
- **ProvisioningState:** `Succeeded`, version 1.0

### Lệnh Azure CLI đã dùng
```bash
az signalr show --name tripto-signalr --resource-group Backend-Ly
az signalr key list --name tripto-signalr --resource-group Backend-Ly
az monitor metrics list --resource /subscriptions/.../SignalR/tripto-signalr --metric "MessageCount" --aggregation Total --start-time 2026-08-09T00:00:00Z --end-time 2026-08-11T23:59:59Z --interval P1D
az monitor metrics list --resource /subscriptions/.../SignalR/tripto-signalr --metric "ConnectionCount" --aggregation Maximum --start-time 2026-08-09T00:00:00Z --end-time 2026-08-11T23:59:59Z --interval P1D
# Test HTTP thực tế:
Invoke-WebRequest POST https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/negotiate
# Test WebSocket handshake thực tế (ClientWebSocket tới wss://tripto-signalr.service.signalr.net/client/?hub=triptohub)
# Test gửi broadcast:
Invoke-WebRequest POST https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/sendNotification
```

### Kết quả thực tế từ Azure CLI + HTTP test
- **Negotiate** (qua Function App): `POST /api/negotiate` → **200** `{"url":"https://tripto-signalr.service.signalr.net/client/?hub=triptohub","accessToken":"eyJhbGciOiJIUzI1NiIs..."}` — token hợp lệ, hub `triptohub`.
- **WebSocket handshake thực tế:** connect `wss://tripto-signalr.service.signalr.net/client/?hub=triptohub` với Bearer token → **`WebSocket State: Open`** (CONNECTION OPEN) — client endpoint của SignalR phản hồi thành công.
- **Send notification (broadcast qua Function output binding):** `POST /api/sendNotification` `{type:"test_signalr_verify",...}` → **200** `{"success":true,"message":"Notification sent through SignalR"}`.
- **Metric `MessageCount`:** 08-09: 3, 08-10: 1, 08-11: 1 — **có message thật** đã đi qua SignalR.
- **Metric `ConnectionCount` (max):** 08-09: 5, 08-10: 6, 08-11: 2 — **có client thật đã kết nối**.
- **CORS hiện tại:** `allowedOrigins: ["*"]` → **KHÔNG bị chặn CORS** ở thời điểm kiểm tra.

### Bằng chứng dịch vụ được cấu hình
- Resource Serverless + ConnectionString có sẵn (az signalr key list). Function `negotiate.js` dùng binding `signalRConnectionInfo` hub `triptoHub` + `AzureSignalRConnectionString`.

### Bằng chứng dịch vụ thực sự được ứng dụng sử dụng / hoạt động
- Frontend `frontend/js/signalr.js` gọi `negotiate` → `.withUrl(data.url, {accessTokenFactory})` → `connection.on('newNotification', ...)` → `connection.start()`. Được nhúng trong `TRANGCHU.html`, `thanhtoan_chitiet.html`, `chitiettour.html`.
- Backend `backend/user.php:4103` gọi `POST .../api/sendNotification` với payload `booking_success` sau khi đặt tour.
- Metric MessageCount + ConnectionCount khác 0 chứng minh lưu lượng thật.

### Giải thích vai trò trong Tripto
SignalR cung cấp **notification realtime**: khi khách đặt tour thành công, backend gửi `booking_success` qua Function `sendNotification` → broadcast tới hub `triptohub` → các client đang mở website nhận toast "Đặt tour thành công!" (thông qua `signalr.js`).

### Kết quả test
**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG HOÀN CHỈNH.** negotiate OK, WebSocket mở thành công, broadcast OK, có metric message + connection thật. CORS hiện tại không chặn (`*`).

---

## 6. Notification Hubs

### Resource thực tế
- **Namespace:** `/subscriptions/.../resourceGroups/Backend-Ly/providers/Microsoft.NotificationHubs/namespaces/tripto-notification`
- **Location:** Southeast Asia, **SKU:** `Free`, Status: `Active`, ProvisioningState: `Succeeded`, created 2026-08-09
- **Notification Hub:** `tripto-hub` (namespace/notificationHubs), RegistrationTtl mặc định (10675199.02:48:05)
- **Auth rules (hub):**
  - `DefaultListenSharedAccessSignature` — Listen
  - `DefaultFullSharedAccessSignature` — Manage, Listen, Send
- **PNS credentials:** lệnh `az notification-hub credential list` trả về **rỗng** (chưa cấu hình credential GCM/FCM/APNS/WNS nào — hợp lý vì dùng Web Push PWA qua VAPID).

### Lệnh Azure CLI đã dùng
```bash
az notification-hub namespace show --name tripto-notification --resource-group Backend-Ly
az notification-hub list --namespace-name tripto-notification --resource-group Backend-Ly
az notification-hub show --name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az notification-hub authorization-rule list --notification-hub-name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az notification-hub authorization-rule list-keys --name DefaultFullSharedAccessSignature --notification-hub-name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az notification-hub credential list --notification-hub-name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az monitor metrics list --resource /subscriptions/.../notificationHubs/tripto-hub --metric "incoming.all.requests" --metric "notificationhub.pushes" --metric "outgoing.allpns.success" --metric "incoming" --aggregation Total --start-time 2026-08-09T00:00:00Z --end-time 2026-08-11T23:59:59Z --interval P1D
# Đếm registration trực tiếp bằng SDK @azure/notification-hubs (cần thiết vì az notification-hub KHÔNG có lệnh list registrations/installations):
#   listRegistrations(client) → đọc từ namespace bằng connection string DefaultFull
```

### Kết quả thực tế từ Azure CLI
- **Không có lệnh Azure CLI nào để liệt kê registrations/installations hoặc lấy outcome của Notification Hub.** `az notification-hub` chỉ hỗ trợ: namespace create/delete/list/show, hub create/delete/list/update, authorization-rule, credential list. → Ghi nhận: **các thao tác liệt kê registration/bài test gửi (test-send) không được hỗ trợ bởi CLI** (không có `test-send`, không có `registration list`).
- Metric (hub `tripto-hub`):
  - `incoming.all.requests`: 08-09: 36 | 08-10: 38 | 08-11: 5 → **tổng 79 request gửi vào hub**
  - `incoming`: 08-09: **12**
  - `notificationhub.pushes` (tất cả outgoing): **0** ở mọi ngày
  - `outgoing.allpns.success`: **0** ở mọi ngày
- **Đếm registration bằng SDK:** `TOTAL_REGISTRATIONS = 2`:
  - `6365663211390968251-402148781919033103-2` — tags `$InstallationId:{3e45bbb4-abf0-4e5f-83e5-b938b38998df}`, **`user:32`** (etag 16)
  - `8046861134443164395-1526033557901223347-2` — tags `$InstallationId:{654aa474-efba-4385-89e0-0232f07f7ab6}` (etag 1)
  - → đây là 2 device/browser đã **đăng ký thật** vào hub (một registration gắn user id 32).
- HTTP test:
  - `GET /api/GetVapidPublicKey` → **200** `{"publicKey":"BDp7RofqXd4vmUSIUlxrRkrqW6MevpJjXkUncoD9euFfeO1Ci_f1SLur0BBGBE06i-RARB78wZDwHwUohAdJLDw"}`
  - `POST /api/RegisterNotification` với body `{}` → **400** (đúng: thiếu `installationId/endpoint/p256dh/auth` — theo logic xác thực của function)
  - `GET /api/NotificationHubDebug/installations` → **401** (yêu cầu function key — như tài liệu `STEPS_BACKEND_INTEGRATION.md` đã nêu)

### Bằng chứng dịch vụ được cấu hình
- Namespace Free + hub `tripto-hub` + 2 SAS rule (Listen + Full). Function `notificationHub.js` khởi tạo `NotificationHubsClient` với `NOTIFICATION_HUB_CONNECTION_STRING` + `NOTIFICATION_HUB_NAME || 'tripto-hub'`.

### Bằng chứng dịch vụ thực sự được ứng dụng sử dụng / hoạt động
- **CÓ 2 registration thật** trong hub (SDK liệt kê được) — chứng minh phía client (PWA `push-notification.js` + `sw.js`) đã đăng ký push thành công vào hub, trong đó có user thật (id 32).
- Metric `incoming` (12 request 08-09) + `incoming.all.requests` (79) cho thấy có lưu lượng request vào hub (đăng ký/upsert).
- **NHƯNG:** `notificationhub.pushes = 0`, `outgoing.allpns.success = 0` — **chưa có bất kỳ notification nào được gửi thành công ra ngoài** từ hub.
- Trong repo: chưa tìm thấy nơi trigger `SendNotificationHub` từ luồng nghiệp vụ thật (docs `STEPS_BACKEND_INTEGRATION.md:764` ghi nhận điều tương tự).

### Giải thích vai trò trong Tripto
Notification Hubs phục vụ **push notification (Web Push PWA)**: trình duyệt đăng ký subscription (qua `GetVapidPublicKey` + `RegisterNotification`), hub `tripto-hub` lưu installation; function `SendNotificationHub` sẽ gửi browser notification. Hiện tại phần **đăng ký (registration) đã có bằng chứng hoạt động, nhưng phần gửi (send/push) chưa có bằng chứng nào** (pushes = 0).

### Kết quả test
**CHƯA ĐỦ BẰNG CHỨNG (hoạt động gửi notification).** Resource tồn tại + cấu hình hợp lệ + **2 registration thật đã đăng ký vào hub** + có request `incoming` — nhưng **`pushes = 0`, `outgoing.allpns.success = 0`**, không có bằng chứng notification được gửi thành công, và chưa tìm thấy nơi trigger gửi trong luồng nghiệp vụ. Ngoài ra, Azure CLI **không hỗ trợ** lệnh liệt kê registration/test-send nên phải dùng SDK để đếm registration.

---

## BẢNG TỔNG KẾT

| Dịch vụ | Resource thực tế | Azure CLI kiểm tra | Có bằng chứng hoạt động | Kết luận |
|---|---|---|---|---|
| **API Management (Consumption)** | `tripto-api-management` (RG Backend-Ly, southeastasia, SKU Consumption), API `tripto`, backend `WebApp_tripto` | `az apim show/api list/api show/api operation list` + `az rest` (policy/backend) + GET thực tế qua `https://tripto-api-management.azure-api.net` | ✅ Có — GET `/tripto` = 200, `/tripto/user.php?endpoint=get_locations` = 200 (JSON dữ liệu thật), 20+ file frontend gọi gateway | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** |
| **Logic Apps (Consumption)** | `tripto-logicapp` (RG Backend-Ly), trigger Service Bus `booking-queue`, action `Send_booking_email` | `az logic workflow show` + `az rest` (runs/actions/trigger histories) | ✅ Có — 30+ run **Succeeded**, action email `Succeeded/OK`, trigger đã `fired` từ message thật | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** |
| **Communication Services** | `tripto-communication` + `tripto-email` + domain `AzureManagedDomain` (global, US data) | `az communication show/list/email list/email domain show` + `az rest` domains | ✅ Có — domain `Verified` toàn bộ (DKIM/SPF/DMARC); test gửi email thật qua `SendBookingEmail` → 200, `accepted`, rejected rỗng | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** |
| **Service Bus (Basic)** | `sb-tripto-backend` (RG Backend-Ly, SKU Basic), queue `booking-queue` | `az servicebus namespace show/queue list` + `az monitor metrics list` (IncomingMessages) | ✅ Có — metric **44 IncomingMessages** thật; messageCount=0 (được Logic App tiêu thụ); `user.php` gọi `$serviceBus->send()` | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** |
| **Azure SignalR Service** | `tripto-signalr` (RG Backend-Ly, SKU Free_F1, Serverless, hub `triptohub`) | `az signalr show/key list` + `az monitor metrics list` + HTTP negotiate + WebSocket handshake | ✅ Có — negotiate 200, WebSocket `Open`, broadcast 200, MessageCount>0, ConnectionCount max 6 | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** (CORS hiện tại `*`, không bị chặn) |
| **Notification Hubs** | namespace `tripto-notification` (SKU Free) + hub `tripto-hub` | `az notification-hub namespace show/list/show/authorization-rule/list-keys/credential list` + `az monitor metrics list` + SDK `listRegistrations` | ⚠️ Một phần — **2 registration thật** đăng ký vào hub (1 gắn `user:32`), 79 incoming requests; **NHƯNG pushes=0, outgoing.allpns.success=0**; CLI **không hỗ trợ** list registration/test-send | **CHƯA ĐỦ BẰNG CHỨNG** (đã đăng ký device, chưa có bằng chứng gửi notification thành công) |

---

## Ghi chú chung
1. Tất cả kết quả đều là **output thực tế** từ Azure CLI / REST / HTTP — không có dữ liệu nào được suy diễn hoặc bịa đặt.
2. Function App `tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net` **không nằm trong subscription này** (không tìm thấy trong `az resource list`/`az functionapp list` của subscription `Azure for Students` hiện tại), nhưng **vẫn đang chạy và trả kết quả thật** cho các endpoint `SendBookingEmail`, `negotiate`, `sendNotification`, `GetVapidPublicKey` — được dùng làm bằng chứng cho Communication Services, SignalR và Notification Hubs.
3. Các lệnh mà Azure CLI **không hỗ trợ** (đã ghi rõ, không bịa kết quả): `az logic` không có `run/trigger` → dùng `az rest`; `az notification-hub` không có lệnh liệt kê registration/installation hay `test-send` → dùng SDK `@azure/notification-hubs` để đếm registration.
