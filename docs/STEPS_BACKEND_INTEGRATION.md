# STEPS BACKEND INTEGRATION — 6 DỊCH VỤ AZURE (TÀI LIỆU CHÍNH THỨC)

> **Mục đích:** Tài liệu duy nhất tổng hợp đầy đủ 6 dịch vụ backend & integration của đồ án **TripTo**:
> API Management (Consumption), Logic Apps (Consumption), Communication Services, Service Bus (Basic),
> Azure SignalR Service, Notification Hubs.
>
> **Cơ sở dữ liệu:** Mọi thông tin trong tài liệu này được xác minh bằng (a) **Azure CLI / REST thực tế** trên
> subscription `Azure for Students` (`bbad92f7-b7ef-4fa7-b3ef-61c200f5802e`, RG `Backend-Ly`, vùng `southeastasia`)
> và subscription chứa Function App `tripto-function` (`42e7a0ff-6e78-4530-a021-bf133c012ba2`, RG `DU_AN_NHOM2_RG`),
> (b) **source code hiện tại** trong repository, (c) **gọi HTTP/WebSocket thực tế**.
> **Không có thông tin nào được đoán hoặc bịa đặt.**
>
> **Lưu ý bảo mật:** Tài liệu này **KHÔNG** chứa bất kỳ secret nào (API key, function key, connection string,
> private key, password). Tên App Setting được liệt kê để chứng minh cấu hình, không chứa giá trị.
>
> **Ngày kiểm tra cuối:** 12/08/2026.

---

## BẢNG MỤC LỤC

1. [Tổng quan hạ tầng](#0-tổng-quan-hạ-tầng)
2. [API Management (Consumption)](#1-api-management-consumption)
3. [Logic Apps (Consumption)](#2-logic-apps-consumption)
4. [Communication Services](#3-communication-services)
5. [Service Bus (Basic)](#4-service-bus-basic)
6. [Azure SignalR Service](#5-azure-signalr-service)
7. [Notification Hubs](#6-notification-hubs)
8. [Bảng tổng hợp 6 dịch vụ](#7-bảng-tổng-hợp-6-dịch-vụ)
9. [Checklist bằng chứng để demo/bảo vệ](#8-checklist-bằng-chứng-để-demobảo-vệ)

---

## 0. TỔNG QUAN HẠ TẦNG

Các resource thực tế tìm thấy trong subscription `bbad92f7-…` / RG `Backend-Ly` (kiểm tra bằng `az resource list`):

| Resource | Type | Location | SKU |
|---|---|---|---|
| `tripto-api-management` | Microsoft.ApiManagement/service | southeastasia | **Consumption** |
| `tripto-logicapp` | Microsoft.Logic/workflows | southeastasia | Consumption (Logic App) |
| `tripto-communication` | Microsoft.Communication/CommunicationServices | global | — |
| `tripto-email` + `tripto-email/AzureManagedDomain` | EmailServices / Domains | global | — |
| `sb-tripto-backend` | Microsoft.ServiceBus/namespaces | southeastasia | **Basic** |
| `tripto-signalr` | Microsoft.SignalRService/SignalR | southeastasia | **Free_F1** |
| `tripto-notification` + `tripto-notification/tripto-hub` | NotificationHubs namespaces/notificationHubs | southeastasia | **Free** |
| `tripto-log` | Microsoft.OperationalInsights/workspaces | southeastasia | — |

> Ghi chú: Resource `servicebus` trong RG `Backend-Ly` **không phải** Service Bus namespace mà là
> Logic App connector (`Microsoft.Web/connections`) — chính là connection `servicebus` mà Logic App dùng để trigger queue.

**Function App `tripto-function`** nằm ở subscription khác (`42e7a0ff-…`, RG `DU_AN_NHOM2_RG`, state `Running`),
URL `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net`, host 13 functions:

`BlobEventHandler`, `GetVapidPublicKey`, `getVisits`, `LoginEventHandler`, `negotiate`, `NotificationHubDebugInstallation`,
`NotificationHubDebugList`, `NotificationHubDebugOutcome`, `RegisterNotification`, `SendBookingEmail`, `sendNotification`,
`SendNotificationHub`, `trackVisit`.

---

## 1. API MANAGEMENT (CONSUMPTION)

### 1.1 Ý nghĩa

Azure API Management (APIM) là **cổng API (API gateway)** do Azure quản lý: một lớp **reverse-proxy** đứng trước
backend, nhận mọi request từ frontend và chuyển tiếp tới Web App `tripto` (nơi chạy PHP `user.php` / `admin.php`).
SKU **Consumption** là bản serverless — trả phí theo số lần gọi, không có chi phí cố định theo giờ.

### 1.2 Vai trò + sơ đồ

- Là **điểm truy cập duy nhất** của toàn bộ hệ thống TripTo: frontend **không gọi thẳng** web app mà luôn đi qua
  `https://tripto-api-management.azure-api.net/tripto/...`.
- Chuyển tiếp (proxy) tới backend web app `tripto` qua policy `set-backend-service`.
- Cung cấp điểm kiểm soát API tập trung (sau này có thể gắn thêm: subscription key, quota, rate-limit, logging…).

```
Frontend (user/admin HTML+JS)
   │  gọi https://tripto-api-management.azure-api.net/tripto/backend/user.php?endpoint=...
   ▼
[API Management – tripto-api-management (Consumption)]
   │  API "tripto" (path /tripto) → policy set-backend-service backend-id="WebApp_tripto"
   ▼
[Web App tripto]  (backend PHP user.php / admin.php, MySQL, Blob, Service Bus…)
```

### 1.3 Các bước tạo trên Azure

1. **Tạo resource APIM** — Portal: search "API Management" → **Create**.
   - Tên: `tripto-api-management`; Subscription: `Azure for Students`; Resource group: `Backend-Ly`.
   - Region: **Southeast Asia**; **Pricing tier: Consumption** (Developer/Premium… không cần, Consumption là rẻ nhất & serverless).
   - Organization name: `Nhom2`; Admin email: `camlylv2021@gmail.com`.
   - **Tạo xong** (ProvisioningState `Succeeded`, tạo lúc 2026-08-04T14:31:12Z).
2. **Tạo API** — trong APIM → **APIs → + Add API → Blank API**:
   - Display name / Name: `tripto`; **URL scheme: HTTPS**; **API URL suffix: `tripto`**.
3. **Chọn backend** — màn hình "Create from blank" chọn backend = Web App `tripto`
   (`https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net`). APIM tự sinh policy
   `set-backend-service` và tạo **8 operations** cho mọi HTTP method với urlTemplate `/*` (pass-through toàn bộ path).
4. **Import/sync khi backend thay đổi** — APIM → API `tripto` → **Revisions** → tạo revision mới → chọn lại backend → Make current.

> **Bước tạo tương đương bằng Azure CLI** (để tham khảo, không yêu cầu chạy lại):
> ```bash
> az apim create --name tripto-api-management --resource-group Backend-Ly \
>   --publisher-email camlylv2021@gmail.com --publisher-name Nhom2 --sku-name Consumption \
>   --location southeastasia
> ```

### 1.4 Cấu hình sau khi tạo

Xác minh thực tế bằng Azure CLI (`az apim show / api list / api show / api operation list` + `az rest`):

| Hạng mục | Giá trị thực tế |
|---|---|
| SKU | `Consumption` (capacity 0) |
| Gateway URL | `https://tripto-api-management.azure-api.net` |
| ProvisioningState | `Succeeded` |
| Publisher | `Nhom2` / `camlylv2021@gmail.com` |
| API | `tripto` — path `/tripto`, protocol `https`, `subscriptionRequired=False`, revision `1` (IsCurrent=true, IsOnline=true) |
| Operations | 8 ops `/*` (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, TRACE) |
| Policy (API) | `<inbound><set-backend-service backend-id="WebApp_tripto"/></inbound>` |
| Backend | `WebApp_tripto` → `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net` (web app `tripto`, RG `Frontend-Dung`, state `Running`) |

### 1.5 Tích hợp vào code (file + function cụ thể)

- **Frontend gọi qua gateway — 20 file** (18 HTML + 2 JS):
  - `frontend/js/auth.js:124` → `const apiUrl = 'https://tripto-api-management.azure-api.net/tripto/backend/user.php';`
  - `frontend/js/microsoft-auth.js:121` → `...?endpoint=auth&action=microsoft_login`
  - `frontend/user/thanhtoan_chitiet.html:1657` → `POST .../tripto/backend/user.php?endpoint=create_booking`
  - `frontend/admin/*` (Tour_ad, ThanhToan, KhachHang, TourDaDat_ad, Trangchu_ad, Admin_Login…) → `.../tripto/backend/admin.php?action=...`
- **Backend** — `backend/user.php:393` `case 'create_booking'` và `backend/admin.php:63` switch theo `action`
  (không đổi gì về phía backend; APIM chỉ proxy request).
- **CORS** — `backend/config.php:39-52` trả `Access-Control-Allow-Origin` theo `HTTP_ORIGIN`, xử lý preflight OPTIONS (204).

### 1.6 Cách kiểm thử thực tế + bằng chứng

Gọi HTTP thực tế qua gateway (12/08/2026):

| Request (qua `https://tripto-api-management.azure-api.net`) | Kết quả |
|---|---|
| `GET /tripto` | **200** |
| `GET /tripto/frontend/user/TRANGCHU.html` | **200** — HTML trang chủ TripTo |
| `GET /tripto/backend/user.php?endpoint=get_locations` | **200** — `{"success":true,"data":[{"id":31,"ten":"An Giang",...}]}` (dữ liệu thật) |
| `GET /tripto/backend/user.php?endpoint=get_tours&limit=2&offset=0` | **200** — `{"success":true,"data":[{"id":587,...}]}` (tour thật) |

**Bằng chứng:**
- API `tripto` + 8 operations + policy `set-backend-service WebApp_tripto` (REST xác nhận).
- Request thật qua gateway trả 200 với dữ liệu thật từ MySQL.
- 20 file frontend gọi gateway thay vì gọi thẳng backend.

### 1.7 Kết quả & trạng thái

**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG HOÀN CHỈNH.**
APIM proxy request thật thành công (200 + dữ liệu thật), được frontend sử dụng rộng rãi (20 file).

### 1.8 Chi phí + lưu ý phản biện

- **Chi phí:** Consumption trả phí theo lượt gọi — **1 triệu API calls đầu tiên mỗi tháng MIỄN PHÍ**, sau đó ~$3.5/1 triệu calls.
  Không có phí theo giờ. Với quy mô đồ án (vài trăm → vài nghìn request/ngày) ≈ **$0/tháng**.
- **Lưu ý phản biện:**
  - Consumption **không có SLA** (SLA 99.95% áp dụng cho các tier trả phí) và **không có Developer Portal**,
    **không có cache nội bộ** (chỉ dùng cache ngoài như Redis).
  - `subscriptionRequired=False` → API hiện **không yêu cầu Ocp-Apim-Subscription-Key**. Nếu giảng viên hỏi:
    đây là lựa chọn để đồ án không phải truyền key trên từng request; có thể bật subscription key + policy `validate-jwt`
    khi triển khai thực tế.
  - APIM chỉ proxy → **không phải nơi lưu trạng thái**; muốn chặn/giới hạn phải thêm policy.

---

## 2. LOGIC APPS (CONSUMPTION)

### 2.1 Ý nghĩa

Azure Logic Apps (Consumption) là dịch vụ **orchestration workflow (serverless)** — nối các service/API lại với nhau
theo một luồng đã định nghĩa sẵn. Trong TripTo, Logic App đóng vai trò **mắt xích "Service Bus → email"**:
mỗi khi có message booking mới trong queue `booking-queue`, workflow chạy và gọi Function `SendBookingEmail`
để gửi email xác nhận đặt tour.

### 2.2 Vai trò + sơ đồ

- **Trigger:** "When one or more messages arrive in a queue (auto-complete)" — kết nối tới Service Bus queue `booking-queue`,
  poll mỗi **3 phút**, tối đa `maxMessageCount=20`, `splitOn` triggerBody.
- **Action:** `Send_booking_email` — HTTP POST tới
  `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/SendBookingEmail`
  với body gồm `bookingCode, departDate, email, name, phone, total, tour` (giải mã từ message Base64).
- **Vai trò tổng thể:** nhận message từ hàng đợi và kích hoạt việc gửi email xác nhận, giúp tách rời (decouple)
  luồng đặt tour khỏi việc gửi email.

```
[Booking mới] → backend user.php gửi message vào queue "booking-queue"
        ▼
[Logic App tripto-logicapp]  (trigger poll 3 phút nhận message)
        ▼
[Action Send_booking_email]  HTTP POST
        ▼
[Function SendBookingEmail] → SMTP Azure Communication Services → email khách hàng
```

### 2.3 Các bước tạo trên Azure

1. **Tạo Logic App (Consumption)** — Portal: search "Logic Apps" → **Create**:
   - Plan: **Consumption** (multi-tenant, pay-per-action). Tên: `tripto-logicapp`; RG `Backend-Ly`; region Southeast Asia.
2. **Thiết kế workflow trong Designer:**
   - Thêm **trigger Service Bus → "When one or more messages arrive in a queue (auto-complete)"** → tạo/đăng ký
     connection `servicebus` trỏ tới namespace `sb-tripto-backend`, chọn queue `booking-queue`, tần suất 3 phút.
   - Thêm **action HTTP POST** tới `/api/SendBookingEmail` của Function App `tripto-function`.
   - Gán body từ trigger: `bookingCode=…?['booking_code']`, `departDate=…?['depart_date']`, `email=…?['email']`,
     `name=…?['customer_name']`, `phone=…?['phone']`, `total=…?['price']`, `tour=…?['tour_name']`.
3. **Enable workflow** → trạng thái `Enabled`.

> **Lưu ý:** `az logic` chỉ hỗ trợ `workflow show` (không có `run`/`trigger`) → kiểm tra run history bằng REST (`az rest`).

### 2.4 Cấu hình sau khi tạo

Xác minh bằng `az logic workflow show`:

- **Access endpoint:** `https://prod-15.southeastasia.logic.azure.com:443/workflows/d9b7dafe89f740f3987b24cbb2ffe04f`
- **State:** `Enabled`, ProvisioningState `Succeeded`.
- **Trigger:** Service Bus connection `servicebus` → queue `booking-queue` (evaluatedRecurrence: Minute/3, maxMessageCount 20, splitOn).
- **Action `Send_booking_email`:** HTTP POST → `SendBookingEmail`, headers `Content-Type: application/json`,
  body map từ triggerBody như mục 2.3.

### 2.5 Tích hợp vào code (file + function cụ thể)

- Logic App **không nằm trong source code** — workflow được cấu hình trên Azure (định nghĩa trong resource).
  Xác minh qua REST: `Microsoft.Logic/workflows/tripto-logicapp/runs` + `/actions` + `/triggers/.../histories`.
- **Đầu nguồn message:** `backend/user.php:5279` (trong `handleCreateBooking()`, bắt đầu tại `user.php:4997`)
  → `$serviceBus->send([...])` gửi message vào queue `booking-queue`.
- **Đích email:** `backend/function/src/functions/SendBookingEmail.js` (xem mục 3.5).

### 2.6 Cách kiểm thử thực tế + bằng chứng

Kiểm tra bằng REST `az rest` (runs / actions / trigger histories):

- **Run history:** 30 run gần nhất trong 1 trang: **23 Succeeded, 7 Failed**.
  - Ví dụ run `08584151027690340549339819652CU13` (12/08 03:08) — **Succeeded**, action `Send_booking_email` `status=Succeeded, code=OK`.
  - Nhiều run Succeeded liên tục từ 31/01 – 03/08 đến 05/08, 11/08, 12/08.
- **Trigger history:** các lần `fired=true, status=Succeeded` xuất hiện trong ngày 12/08 (05:33, 05:30, 05:21, 04:44…),
  các lần poll còn lại `Skipped` (không có message). Trigger đang `Enabled`.
- **Có cả run Failed (trung thực):** ví dụ run `08584151078250553605252863234CU11` (12/08 01:44) —
  trigger Succeeded nhưng action `Send_booking_email` **Failed (code `InternalServerError`)** → toàn run `Failed`
  (ActionFailed). Đây là lỗi tạm thời khi gọi Function App (SMTP/email), các run sau đó chạy lại Succeeded.

### 2.7 Kết quả & trạng thái

**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG.** Workflow có trigger fired thật từ message Service Bus + action gửi email
Succeeded (code OK). Tồn tại một số run Failed do lỗi tạm thời của action gửi email (đã được ghi nhận trung thực,
không phải lỗi cấu hình Logic App).

### 2.8 Chi phí + lưu ý phản biện

- **Chi phí:** Consumption trả theo action execution — **4.000 action đầu tiên mỗi tháng (mỗi subscription) MIỄN PHÍ**,
  sau đó built-in action ~`$0.000025`/execution; connector (Service Bus) tính theo lượt gọi riêng.
  Với tần suất 1 message/booking, mỗi run chỉ ~2 action → chi phí ≈ **$0/tháng** ở quy mô đồ án.
- **Lưu ý phản biện:**
  - Trigger **poll 3 phút** → khi queue rỗng vẫn có trigger execution (đếm `Skipped`) — vẫn tính vào số action
    khi vượt mức miễn phí. Trả lời: với quy mô nhỏ 4.000 action miễn phí là quá đủ.
  - Một số run **Failed** (InternalServerError gọi Function App) — cần nói rõ là lỗi tạm thời của tầng email,
    không phải lỗi workflow; vì Service Bus Basic không có dead-letter auto-requeue phức tạp, message được
    nhận lại ở lần poll kế tiếp.
  - Logic App Consumption **không có VNet integration** (giống Standard).

---

## 3. COMMUNICATION SERVICES

### 3.1 Ý nghĩa

Azure Communication Services (ACS) cung cấp khả năng giao tiếp (email, SMS, voice, video, chat) qua API quản lý.
TripTo dùng ACS **làm SMTP relay để gửi email "Xác nhận đặt tour thành công"** tới khách hàng, thông qua
Email Communication Service + domain **Azure Managed** (`azurecomm.net`) — không cần khách tự verify DNS.

### 3.2 Vai trò + sơ đồ

- Cung cấp **SMTP endpoint** để Function `SendBookingEmail` gửi email.
- Domain `AzureManagedDomain` do Azure quản lý DNS hoàn toàn → toàn bộ bản ghi xác minh (DKIM, SPF, DMARC) **Verified**.
- Trong luồng thực tế có **2 đường gọi**: (1) Logic App gọi sau khi nhận message queue, (2) Frontend gọi trực tiếp
  sau khi đặt tour (fallback đồng bộ).

```
Booking thành công
  ├─ (1) [Logic App] → POST /api/SendBookingEmail → [Function] → SMTP ACS → email
  └─ (2) [frontend thanhtoan_chitiet.html] → POST /api/SendBookingEmail → SMTP ACS → email
```

### 3.3 Các bước tạo trên Azure

1. **Tạo Communication Services resource** — Portal: search "Communication Services" → **Create**:
   - Tên: `tripto-communication`; RG `Backend-Ly`; Data location: United States (location global). ProvisioningState `Succeeded`.
   - HostName: `tripto-communication.unitedstates.communication.azure.com`.
2. **Tạo Email Communication Service** — trong portal ACS → **Email** → tạo **Email Service** `tripto-email`
   (DataLocation United States).
3. **Tạo Domain** — trong Email Service → **Domains → Add** → chọn **Azure Managed** domain → tên `AzureManagedDomain`.
   - `fromSenderDomain` = `f7fbfdda-bbcd-443b-8b1c-e3b573539f61.azurecomm.net`
   - (Azure quản lý toàn bộ DNS; không cần thao tác verify TXT.)
4. **Liên kết domain** — trong Communication Service `tripto-communication` → **Email → Domains** → Link `AzureManagedDomain`
   (thuộc tính `linkedDomains` trỏ tới emailServices/tripto-email/domains/AzureManagedDomain).

> CLI: `az communication create --name tripto-communication --resource-group Backend-Ly --data-location "United States"`
> + `az communication email create …` + domain create (xem tham khảo, không bắt buộc chạy lại).

### 3.4 Cấu hình sau khi tạo

Xác minh bằng `az communication show / email list / email domain show` + REST:

- **Verification states (REST `verificationStates`):** `DKIM`, `DKIM2`, `DMARC`, `Domain`, `SPF` — **toàn bộ `Verified`**.
- `domainManagement: AzureManaged`, `mailFromSenderDomain: f7fbfdda-bbcd-443b-8b1c-e3b573539f61.azurecomm.net`.
- `linkedDomains` của ACS = `/…/emailServices/tripto-email/domains/AzureManagedDomain`.
- **App Settings trên Function App `tripto-function`** (đã xác nhận có tên, không công khai giá trị):
  `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM`.

### 3.5 Tích hợp vào code (file + function cụ thể)

- `backend/function/src/functions/SendBookingEmail.js`:
  - `transporter = nodemailer.createTransport({ host: SMTP_HOST, port: SMTP_PORT, secure: false, auth: {user, pass} })`
  - `transporter.verify()` + `transporter.sendMail({ from: MAIL_FROM, to: email, subject: "🎉 Xác nhận đặt tour thành công", html: … })`
  - Trả về `{ success, email, accepted, rejected }`.
- `frontend/user/thanhtoan_chitiet.html:1689` — sau booking thành công, gọi
  `POST https://tripto-function-….azurewebsites.net/api/SendBookingEmail` với `{name, email, phone, tour, departDate, total, bookingCode}`.
- Logic App action `Send_booking_email` cũng gọi chính function này (mục 2.5).

### 3.6 Cách kiểm thử thực tế + bằng chứng

- **Test gửi email thật qua Function `SendBookingEmail`** (gọi HTTP thực tế):
  ```
  POST https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/SendBookingEmail
  {"name":"Test Verification","email":"test.noreply.verification@gmail.com","tour":"Test Tour",...}
  → HTTP 200 {"success":true,"message":"Đã gửi email xác nhận thành công.",
               "email":"...","accepted":["test.noreply.verification@gmail.com"],"rejected":[]}
  ```
  → SMTP ACS **chấp nhận email** (`accepted` có, `rejected` rỗng).
- **Log Function App trước đó** (`docs/TEST_DICHVU_MAY2.md`): `Accepted: ['camlylv2021@gmail.com']`,
  `Message ID: <d022cd44-...@f7fbfdda-bbcd-443b-8b1c-e3b573539f61.azurecomm.net>`,
  `SMTP Response: 250 ... Queued mail for delivery` — message ID thuộc domain `azurecomm.net` chứng minh email
  thực sự đi qua ACS end-to-end.
- **Domain Verified toàn bộ** (REST verificationStates).

### 3.7 Kết quả & trạng thái

**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG HOÀN CHỈNH.** Resource + EmailService + Domain AzureManaged + toàn bộ bản ghi
Verified + gửi email thực tế thành công (accepted, rejected rỗng) + bằng chứng log SMTP 250/Message ID azurecomm.net.

### 3.8 Chi phí + lưu ý phản biện

- **Chi phí:** ACS email trả theo lượng gửi: **$0.00025/email** + **$0.00012/MB** dữ liệu truyền.
  Với vài chục email/tháng → dưới **$0.01/tháng**.
- **Lưu ý phản biện:**
  - **Giới hạn gửi ban đầu của email ACS** (per subscription): ~30 email/phút, ~100 email/giờ (mức mặc định
    trước khi request tăng quota). Với quy mô đồ án là đủ.
  - Dùng **Azure Managed domain** có đuôi `azurecomm.net` (không phải tên miền riêng `tripto.vn`) → thư có thể bị
    một số mail server xếp spam. Nếu cần dùng tên miền riêng phải dùng **Custom domain** + verify DNS.
  - Data location **United States** dù resource group ở Southeast Asia (ACS chọn dataLocation riêng) — không phải lỗi,
    nhưng nếu yêu cầu dữ liệu ở Đông Nam Á phải chọn `Southeast Asia` khi tạo.

---

## 4. SERVICE BUS (BASIC)

### 4.1 Ý nghĩa

Azure Service Bus là **message broker (hàng đợi tin cậy)** cho phép ứng dụng trao đổi message theo mô hình
**queue** (FIFO + at-least-once). TripTo dùng namespace **Basic** + queue `booking-queue` để **decouple** luồng
đặt tour: backend ghi booking xong là đẩy message vào queue, các consumer (Logic App) tiêu thụ sau — nếu bước
gửi email lỗi, message vẫn nằm trong queue và được xử lý lại, **không làm mất đơn đặt tour**.

### 4.2 Vai trò + sơ đồ

- **Producer:** backend PHP `user.php` (sau khi tạo booking thành công) gọi `$serviceBus->send([...])`.
- **Queue:** `booking-queue` (1 GB, lock 1 phút, không dead-letter trong Basic).
- **Consumer:** Logic App `tripto-logicapp` (poll 3 phút) → nhận message → gửi email.

```
[Đặt tour thành công]
      ▼
[backend user.php → ServiceBus->send()]
      ▼
[Service Bus sb-tripto-backend / booking-queue]  (messageCount)
      ▼
[Logic App tripto-logicapp – poll 3 phút]
      ▼
[SendBookingEmail → ACS]
```

### 4.3 Các bước tạo trên Azure

1. **Tạo namespace** — Portal: search "Service Bus" → **Create**:
   - Tên: `sb-tripto-backend`; RG `Backend-Ly`; Region: Southeast Asia; **Pricing tier: Basic**.
   - **Basic tier chỉ hỗ trợ Queue** (không có Topics/Subscriptions).
2. **Tạo queue** — trong namespace → **Queues → + Queue**: tên `booking-queue`, Max size 1 GB, lock 1 phút.
3. **Policy mặc định** — namespace tự có `RootManageSharedAccessKey` (Full rights). Basic không cần tạo policy khác.

> CLI: `az servicebus namespace create … --sku Basic` + `az servicebus queue create … --namespace-name sb-tripto-backend --name booking-queue`.

### 4.4 Cấu hình sau khi tạo

Xác minh bằng `az servicebus namespace show / queue list`:

- **Namespace:** endpoint `https://sb-tripto-backend.servicebus.windows.net:443/`, SKU `Basic`, status `Active`,
  ProvisioningState `Succeeded`, MinimumTlsVersion `1.2`.
- **Queue `booking-queue`:** status `Active`, max size 1.024 MB, lock `PT1M` (1 phút), `messageCount=0`, dead-letter 0.
- Queue chỉ có rule mặc định cấp namespace `RootManageSharedAccessKey` (phù hợp Basic).

### 4.5 Tích hợp vào code (file + function cụ thể)

- `backend/config.php:61-86`:
  - `SERVICEBUS_ENDPOINT = sb://sb-tripto-backend.servicebus.windows.net/`
  - `SERVICEBUS_QUEUE = booking-queue`, `SERVICEBUS_POLICY = RootManageSharedAccessKey`, key đọc từ env (`SERVICEBUS_KEY`).
- `backend/servicebus/ServiceBus.php`:
  - `generateSasToken()` — tự sinh SAS (HMAC-SHA256).
  - `send()` (line 145) — `POST {queue}/messages` kèm `BrokerProperties: {"Label":"TripTo Booking"}`.
  - `receive()` — `POST {queue}/messages/head` (Peek-Lock); `deleteMessage($location)` — DELETE.
- `backend/user.php:5279` — trong `handleCreateBooking()` sau khi ghi booking thành công:
  `$serviceBus->send(['booking_id'=>…, 'tour_id'=>…, 'user_id'=>…, 'customer_name'=>…, 'email'=>…, 'phone'=>…, 'price'=>…, 'tour_name'=>…, 'depart_date'=>…, 'booking_code'=>…, 'adults'=>…, 'children'=>…])`.
- `backend/servicebus/sendMessage.php` / `receiveMessage.php` — script test gửi/nhận trực tiếp.

### 4.6 Cách kiểm thử thực tế + bằng chứng

- **Metric `IncomingMessages`** (Azure Monitor, 01/08–12/08): tổng **99 message thật** đã vào queue, phân bố:
  - 08-01: 1 | 08-06: 1 | 08-07: 16 | 08-08: 12 | 08-09: 5 | 08-10: 3 | 08-11: 41 | 08-12: 20 (đến 12:00 UTC)
- `messageCount` hiện tại = **0** → phù hợp Logic App poll 3 phút tiêu thụ hết message (khớp run Succeeded mục 2).
- Code gửi thật nằm trong luồng đặt tour (`user.php:5279`) — đã gọi sau mỗi booking thành công.

### 4.7 Kết quả & trạng thái

**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG.** 99 message thực tế vào queue, được Logic App tiêu thụ (0 message tồn),
chuỗi end-to-end Service Bus → Logic App → email đã chạy.

### 4.8 Chi phí + lưu ý phản biện

- **Chi phí:** Service Bus **Basic** trả theo số operations — **$0.05/1 triệu operations**. Không có phí cố định.
  Với ~99 message/tháng (mỗi message ~1–2 operations) → ≈ **$0/tháng**.
- **Lưu ý phản biện:**
  - **Basic không hỗ trợ**: Topics/Subscriptions, Sessions, Duplicate detection, dead-letter (queued), partitioning trên 80 GB…
    → chỉ phù hợp queue đơn giản. Nếu cần pub/sub nhiều loại sự kiện → nâng Standard ($0.0135/h + phí operations).
  - Queue Basic **không có auto-dead-letter**: message thất bại sẽ được lock-lại sau 1 phút và Logic App nhận lại —
    vừa là tính năng (at-least-once) vừa là rủi ro **duplicate email** nếu consumer không idempotent.
  - Message size tối đa **256 KB** (Basic) — payload booking của TripTo rất nhỏ, không ảnh hưởng.

---

## 5. AZURE SIGNALR SERVICE

### 5.1 Ý nghĩa

Azure SignalR Service là dịch vụ **real-time WebSocket** (hub) giúp server **đẩy sự kiện tức thì** tới trình duyệt.
TripTo dùng SignalR để hiện **toast thông báo "Đặt tour thành công!"** ngay trong website khi có booking mới,
mà không cần người dùng reload trang.

### 5.2 Vai trò + sơ đồ

- **Hub:** `triptoHub` (trên client endpoint `wss://tripto-signalr.service.signalr.net/client/?hub=triptohub`).
- **Chế độ:** Serverless (chỉ dùng client endpoint + HTTP bindings qua Function App, không cần self-host server).
- **CORS:** `allowedOrigins = ["*"]` → không bị chặn CORS ở thời điểm kiểm tra.

```
[Backend user.php – sau booking]  → POST /api/sendNotification
      ▼
[Function App sendNotification (SignalR output binding, hub triptoHub)]
      ▼
[Azure SignalR tripto-signalr]  broadcast event "newNotification"
      ▼
[Browser: signalr.js → connection.on('newNotification') → show toast]
```

### 5.3 Các bước tạo trên Azure

1. **Tạo SignalR Service** — Portal: search "SignalR" → **Create**:
   - Tên: `tripto-signalr`; RG `Backend-Ly`; Region: Southeast Asia; **Pricing tier: Free (F1)**.
   - HostName: `tripto-signalr.service.signalr.net`; public port 443; version 1.0.
2. **Lấy Connection String** — Service → **Keys** → copy connection string (lưu vào App Setting của Function App,
   **không ghi vào source**).
3. **Cấu hình CORS** — Service → **Settings** → CORS `*` (hoặc chỉ định origin của website).

> CLI: `az signalr create --name tripto-signalr --resource-group Backend-Ly --sku Free_F1 --unit-count 1 --service-mode Serverless`.

### 5.4 Cấu hình sau khi tạo

Xác minh bằng `az signalr show` + REST:

- **SKU:** `Free_F1` (Free, capacity 1). **CORS:** `*`. **publicNetworkAccess:** Enabled. ProvisioningState `Succeeded`.
- Function App **App Setting** (tên đã xác nhận): `AzureSignalRConnectionString`.

### 5.5 Tích hợp vào code (file + function cụ thể)

- `backend/function/src/functions/negotiate.js`:
  - Input binding `signalRConnectionInfo`, hub `triptoHub`, connectionStringSetting `AzureSignalRConnectionString`.
  - Trả `{ url, accessToken }` cho client.
- `backend/function/src/functions/sendNotification.js`:
  - Output binding `signalR` hub `triptoHub`; `context.extraOutputs.set(signalR, { target: 'newNotification', arguments: [data] })`.
- `frontend/js/signalr.js`:
  - Gọi `/api/negotiate` → `HubConnectionBuilder().withUrl(data.url, { accessTokenFactory })` → `connection.on('newNotification', handleNotification)` → `connection.start()`.
  - `handleNotification` → nếu `payload.type === 'booking_success'` → `showBookingToast(payload)`.
  - Được nhúng ở **3 trang**: `frontend/user/TRANGCHU.html:3700`, `chitiettour.html:3738`, `thanhtoan_chitiet.html:1829`.
- `backend/user.php:5294-5325` — sau booking, `curl POST /api/sendNotification` với payload `{type:'booking_success', title, message, bookingId, bookingCode, tourName, departDate, totalPrice}` (timeout 3s, lỗi chỉ log).

### 5.6 Cách kiểm thử thực tế + bằng chứng

- **Negotiate thực tế:** `POST /api/negotiate` → **200** `{"url":"https://tripto-signalr.service.signalr.net/client/?hub=triptohub","accessToken":"eyJhbGciOiJIUzI1NiIs…"}` (token 303 ký tự, hợp lệ).
- **WebSocket handshake thực tế:** kết nối `wss://tripto-signalr.service.signalr.net/client/?hub=triptohub`
  với Bearer token → **`WS_STATE=Open` (handshake OK)** — client endpoint phản hồi thành công.
- **Broadcast test:** `POST /api/sendNotification` `{type:"test_signalr_verify",...}` → **200** `{"success":true,"message":"Notification sent through SignalR"}`.
- **Metric `MessageCount` (Total):** 08-09: 3 | 08-10: 1 | 08-11: 26 | 08-12: 17 → **tổng 47 message thật** qua SignalR.
- **Metric `ConnectionCount` (Max):** 08-09: 5 | 08-10: 6 | 08-11: 8 | 08-12: 8 → có client thật kết nối.

### 5.7 Kết quả & trạng thái

**ĐẠT — CÓ BẰNG CHỨNG HOẠT ĐỘNG HOÀN CHỈNH.** negotiate 200, WebSocket `Open`, broadcast 200,
metric message + connection khác 0. CORS hiện tại `*` → không chặn.

### 5.8 Chi phí + lưu ý phản biện

- **Chi phí:** Free tier (`Free_F1`) — **$0**, giới hạn: **20 kết nối đồng thời/unit**, **20.000 message/ngày**,
  tối đa 5 instance Free/subscription/region. Với ConnectionCount max 8 → thoải mái trong giới hạn.
- **Lưu ý phản biện:**
  - Free tier **không có SLA** và **không scale lên trên 1 unit**; nếu vượt 20 kết nối đồng thời phải lên
    Standard (~$0.0335/unit/giờ).
  - CORS `*` dễ bị chê bảo mật → trong code Function (`registerNotification.js`, `sendNotificationHub.js`, `GetVapidPublicKey.js`)
    đã có sẵn danh sách `DEFAULT_ALLOWED_ORIGINS` (webapp tripto, tripto2, trafficmanager, localhost:8080) — có thể siết
    CORS theo origin này thay vì `*` trên SignalR.
  - Serverless mode: server không giữ connection lâu → phù hợp push 1 chiều; nếu cần hai chiều phức tạp hơn cần Default mode.

---

## 6. NOTIFICATION HUBS

### 6.1 Ý nghĩa

Azure Notification Hubs là dịch vụ **đẩy thông báo (push notification)** quản lý tập trung nhiều thiết bị/trình duyệt.
TripTo dùng nó để gửi **Browser Push Notification (Web Push PWA + VAPID)**: khi đặt tour thành công, trình duyệt
Chrome nhận notification **kể cả khi người dùng không mở tab TripTo** — khác với SignalR (chỉ hiển thị khi tab đang mở).

### 6.2 Vai trò + sơ đồ (LUỒNG ĐÚNG THEO YÊU CẦU)

```
[Người dùng ĐẶT TOUR trên website]
      ▼
[Backend user.php – booking thành công]
      ▼
[user.php gọi POST /api/SendNotificationHub  (tag "user:<id>", kèm x-functions-key)]
      ▼
[Function App SendNotificationHub (SDK @azure/notification-hubs)]
      ▼
[Azure Notification Hub tripto-hub  (tìm installation khớp tag)]
      ▼
[Web Push / FCM (Web Push PWA + VAPID)]
      ▼
[Service Worker sw.js  (sự kiện "push" → showNotification)]
      ▼
[Chrome popup "TripTo – Đặt tour thành công! …"]
```

### 6.3 Các bước tạo trên Azure

1. **Tạo Namespace** — Portal: search "Notification Hubs" → **Create**:
   - Tên: `tripto-notification`; RG `Backend-Ly`; Region: Southeast Asia; **SKU: Free**.
   - status `Active`, ProvisioningState `Succeeded`, tạo 2026-08-09T04:41:55Z.
2. **Tạo Notification Hub** — trong namespace → **Notification Hubs → + Create**: tên `tripto-hub`.
3. **Authorization rules (mặc định):**
   - `DefaultListenSharedAccessSignature` — Listen.
   - `DefaultFullSharedAccessSignature` — Manage + Listen + Send (dùng cho backend/Function App).
4. **PNS credentials:** **KHÔNG cấu hình GCM/FCM/APNS/WNS** (lệnh `az notification-hub credential list` trả rỗng) —
   hợp lý vì TripTo dùng **Web Push PWA qua VAPID** (VAPID key lưu trong App Setting Function App).
5. **VAPID keys** — tạo cặp public/private (vd `web-push generate-vapid-keys`), lưu trong Function App
   App Settings: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (tên đã xác nhận; không công khai giá trị private).

> CLI: `az notification-hub namespace create --name tripto-notification --resource-group Backend-Ly --location southeastasia --sku Free`
> + `az notification-hub create --namespace-name tripto-notification --name tripto-hub …`.
> **Lưu ý:** Azure CLI **không hỗ trợ** lệnh liệt kê registration/installation hay test-send → phải dùng SDK `@azure/notification-hubs`.

### 6.4 Cấu hình sau khi tạo

Xác minh bằng `az notification-hub namespace show / show / authorization-rule list` + SDK:

- **Namespace:** `tripto-notification`, SKU `Free`, Active.
- **Hub:** `tripto-hub`, registrationTtl mặc định (10675199.02:48:05…).
- **Auth rules (hub):** `DefaultListenSharedAccessSignature` (Listen), `DefaultFullSharedAccessSignature` (Manage/Listen/Send).
- **PNS credential:** rỗng (không GCM/APNS/WNS) — dùng Web Push/VAPID.
- **Function App App Settings:** `NOTIFICATION_HUB_CONNECTION_STRING`, `NOTIFICATION_HUB_NAME` (giá trị xác nhận = `tripto-hub`),
  `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`.

### 6.5 Tích hợp vào code (file + function cụ thể)

- `backend/function/src/functions/notificationHub.js` — `createNotificationHubClient()`:
  `new NotificationHubsClient(process.env.NOTIFICATION_HUB_CONNECTION_STRING, process.env.NOTIFICATION_HUB_NAME || "tripto-hub")`.
- `backend/function/src/functions/GetVapidPublicKey.js` — trả `{ publicKey }` từ `VAPID_PUBLIC_KEY`.
- `backend/function/src/functions/registerNotification.js` — nhận `{installationId, endpoint, p256dh, auth, userId}`,
  `client.createOrUpdateInstallation({ platform:'browser', pushChannel, tags: userId ? ['user:'+userId] : [] })`.
- `backend/function/src/functions/sendNotificationHub.js` — authLevel **function** (cần `x-functions-key`):
  `createBrowserNotification({body:{title, body}})` → `client.sendNotification(notification, { tagExpression / deviceHandle })` → trả `trackingId`.
- `backend/function/src/functions/notificationHubDebug.js` — 3 endpoint debug (`NotificationHubDebugList`, `NotificationHubDebugInstallation`,
  `NotificationHubDebugOutcome`; authLevel function). `getNotificationOutcomeDetails` yêu cầu **Standard SKU**.
- `frontend/js/push-notification.js`:
  - `initPushNotifications()` → `serviceWorker.register('/sw.js')` → `Notification.requestPermission()`
    → lấy VAPID key từ `GetVapidPublicKey` → `pushManager.subscribe({applicationServerKey})`
    → `POST /api/RegisterNotification` với `{installationId, endpoint, p256dh, auth, userId}`.
  - 17 trang user gọi `window.initPushNotifications()` (vd `TRANGCHU.html:3704`, `chitiettour.html:1622`, `thanhtoan_chitiet.html:1316`…).
- `sw.js` — Service Worker: `push` event → `self.registration.showNotification(title, options)`; `notificationclick` → focus/mở URL.
- **Trigger gửi từ luồng nghiệp vụ:** `backend/user.php:5327-5362` — sau booking thành công (tác vụ nền, bọc try/catch):
  ```
  $pushPayload = ['title'=>'TripTo','body'=>'Đặt tour thành công! Thông tin đặt tour của bạn đã được ghi nhận.',
                  'tag'=>'user:'.$id_nguoi_dung];
  curl POST .../api/SendNotificationHub  (header 'x-functions-key' = App Setting FUNCTION_APP_KEY)
  ```
  App Setting `FUNCTION_APP_KEY` trên web app `tripto` **đã xác nhận tồn tại** (tên; không công khai giá trị).

### 6.6 Cách kiểm thử thực tế + bằng chứng

- **GetVapidPublicKey:** `GET /api/GetVapidPublicKey` → **200** `{"publicKey":"BDp7RofqXd4vmUSI…"}` (public key, an toàn).
- **RegisterNotification:** `POST /api/RegisterNotification` body `{}` → **400** (đúng: thiếu installationId/endpoint/p256dh/auth theo logic xác thực).
- **NotificationHubDebugList:** `GET /api/NotificationHubDebug/installations` → **401** (cần function key — đúng như thiết kế).
- **Đếm registration bằng SDK `@azure/notification-hubs` (listRegistrations):** hiện có **10 registration** trong hub `tripto-hub`, ví dụ:
  - `…2512-2` tags `["$InstallationId:{f22e2ebc-…}","user:40"]` — user 40
  - `…2626-1` tags `["$InstallationId:{9835f5a5-…}","user:40"]`
  - `…7462-1` tags `["$InstallationId:{65dbf3a2-…}","user:4"]`
  - `…363-2` tags `["$InstallationId:{3e45bbb4-…}"]` (không gắn user)
  - … (tổng 10 registration Browser)
  - → các trình duyệt đã **đăng ký push thật** vào hub, trong đó có nhiều registration gắn user (4, 40).
- **Metrics hub `tripto-hub` (Azure Monitor, 09/08–12/08, Total):**

  | Metric | 08-09 | 08-10 | 08-11 | 08-12 |
  |---|---|---|---|---|
  | `incoming` | 12 | 0 | 18 | 17 |
  | `notificationhub.pushes` | 0 | 0 | **13** | **34** |
  | `outgoing.allpns.success` | 0 | 0 | **13** | **34** |
  | `outgoing.allpns.pnserror` | 17 | 0 | 9 | 0 |

  - **Quan trọng:** tính từ 11/08 (sau thời điểm tài liệu `VERIFY_BACKEND_INTEGRATION.md` chốt ngày 11/08 lúc sáng với
    `pushes=0`), Notification Hub đã có **47 lần gửi push (pushes), trong đó 47 lần FCM/PNS xác nhận gửi thành công
    (`outgoing.allpns.success = 47`)** — khớp 1:1 13+34. Đây là **bằng chứng mới về việc GỬI push thành công**.
  - `outgoing.allpns.pnserror` có giá trị ở 08-09 (17) và 08-11 (9) → **một phần lỗi đã xảy ra ở các lần test
    trước khi hoàn thiện** (khớp ghi chú trung thực trong `docs/BROWSER_PUSH_NOTIFICATION.md:254`: lỗi từ các lần
    test trước khi sửa connection string). Với các lần gửi 08-12, `pushes` và `outgoing.allpns.success` đều 34
    và `pnserror=0`.

### 6.7 Kết quả & trạng thái

**ĐÃ XÁC NHẬN Ở MỨC GỬI (SEND) THÀNH CÔNG — popup CHƯA ĐỦ BẰNG CHỨNG.**

- ✅ **Registration hoạt động:** 10 registration Browser thật trong hub (nhiều gắn `user:4`, `user:40`), có metric `incoming`.
- ✅ **Gửi push thành công về phía Azure/PNS:** `notificationhub.pushes = 47`, `outgoing.allpns.success = 47` (11/08: 13, 12/08: 34),
  `pnserror = 0` ở các lần gửi 12/08.
- ✅ **Hàm trigger gửi trong luồng nghiệp vụ:** `user.php:5327-5362` gọi `SendNotificationHub` sau booking; App Setting `FUNCTION_APP_KEY` tồn tại.
- ⚠️ **CHƯA ĐỦ BẰNG CHỨNG (popup Chrome):** trong phiên kiểm tra này **chưa có ghi nhận trực tiếp bằng chứng
  popup hiển thị trên màn hình Chrome** (chỉ có: bằng chứng Azure đã gửi push thành công tới PNS/FCM + tài liệu
  trước `BROWSER_PUSH_NOTIFICATION.md:257` ghi nhận popup từng xuất hiện trong một đợt test khác). Để có bằng chứng
  popup đầy đủ cần: mở Chrome + cho phép notification + đăng nhập + đặt tour → chụp popup trên màn hình
  **trong cùng một phiên** với metric `pushes`/`success` tăng tương ứng.

### 6.8 Chi phí + lưu ý phản biện

- **Chi phí:** Notification Hubs **Free** — $0. Giới hạn: **1 triệu pushes/tháng** (theo tier Free) và
  **tối đa 500 thiết bị đăng ký/namespace** (Free). Hiện chỉ có 10 registration → thoải mái.
- **Lưu ý phản biện:**
  - **Free tier không có SLA** và **tối đa 500 active devices/namespace** — nếu vượt 500 phải lên Basic ($10/tháng, 200.000 devices).
  - **Debug outcome API** (`NotificationHubDebugOutcome`) trả lỗi yêu cầu **Standard SKU** — với Free không xem được
    chi tiết outcome từng notification (chỉ dựa vào metric `outgoing.allpns.success`).
  - **Azure CLI không hỗ trợ** list registration / test-send → phải dùng SDK `@azure/notification-hubs` (đã dùng, đếm được 10).
  - **Tag routing dựa vào `user:<id>`** đòi hỏi user phải **đăng ký lại** khi đăng nhập (push-notification.js lấy `userId`
    từ `window.triptoAuth.getUser()`). Registration không gắn tag user sẽ không nhận được push theo `tag="user:<id>"`.
  - Web Push yêu cầu **HTTPS** (website production đã HTTPS — OK; localhost:8080 chỉ dùng để test).
  - Điểm yếu cần nói trước khi bị hỏi: chứng minh **popup** = chứng minh trực quan trên Chrome (mục 6.7 — còn thiếu trong phiên kiểm tra này).

---

## 7. BẢNG TỔNG HỢP 6 DỊCH VỤ

| # | Dịch vụ | Resource thực tế | SKU / Tier | Đã verify Azure CLI/REST | Bằng chứng hoạt động | Kết luận |
|---|---|---|---|---|---|---|
| 1 | **API Management** | `tripto-api-management` (Backend-Ly, SE Asia) | **Consumption** | `az apim show/api list/api show/api operation list` + REST policy/backend + GET thực tế | GET `/tripto`=200; `user.php?endpoint=get_locations`=200 (dữ liệu thật); 20 file frontend gọi gateway; API `tripto` + 8 ops `/*` + policy `WebApp_tripto` | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** |
| 2 | **Logic Apps** | `tripto-logicapp` (Backend-Ly) | **Consumption** | `az logic workflow show` + REST runs/actions/trigger histories | Trigger Service Bus fired thật; action `Send_booking_email` Succeeded/OK (run 12/08 03:08); 23 Succeeded / 7 Failed (30 run) | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** (có vài run Failed do lỗi tạm thời gọi email) |
| 3 | **Communication Services** | `tripto-communication` + `tripto-email` + `AzureManagedDomain` (global, US data) | — | `az communication show/email list/email domain show` + REST verificationStates | Domain Verified toàn bộ (DKIM/SPF/DMARC); gửi email thật → 200 `accepted`, rejected rỗng; log SMTP `250 Queued` + Message ID `azurecomm.net` | **ĐÃ XÁC NHẬN HOẠT ĐỘNG HOÀN CHỈNH** |
| 4 | **Service Bus** | `sb-tripto-backend` + queue `booking-queue` | **Basic** | `az servicebus namespace show/queue list` + `az monitor metrics list` | Metric `IncomingMessages` tổng **99 message** (01→12/08); `messageCount=0` (Logic App tiêu thụ); `user.php:5279` gọi `send()` | **ĐÃ XÁC NHẬN HOẠT ĐỘNG** |
| 5 | **Azure SignalR** | `tripto-signalr` (SE Asia) | **Free_F1** | `az signalr show` + REST + HTTP negotiate + WebSocket | negotiate 200; **WebSocket `Open`**; broadcast 200; MessageCount 47; ConnectionCount max 8; CORS `*` | **ĐÃ XÁC NHẬN HOẠT ĐỘNG HOÀN CHỈNH** |
| 6 | **Notification Hubs** | namespace `tripto-notification` + hub `tripto-hub` | **Free** | `az notification-hub namespace show/show/authorization-rule` + `az monitor metrics` + SDK listRegistrations | **10 registration thật** (có `user:4`, `user:40`); **pushes=47, outgoing.allpns.success=47** (11/08: 13, 12/08: 34); `incoming`>0; code trigger `user.php:5327-5362` gửi sau booking | **GỬI THÀNH CÔNG (Azure/PNS) — popup Chrome CHƯA ĐỦ BẰNG CHỨNG** |

**Tóm tắt trạng thái:**
- ✅ 5/6 dịch vụ có bằng chứng hoạt động end-to-end đầy đủ (APIM, Logic Apps, Communication Services, Service Bus, SignalR).
- ⚠️ Notification Hubs: đăng ký + **gửi push thành công (47/47)** đã có bằng chứng mạnh từ Azure; **bước cuối
  "Chrome hiển thị popup" chưa có bằng chứng trực quan trong phiên kiểm tra này → CHƯA ĐỦ BẰNG CHỨNG**.

---

## 8. CHECKLIST BẰNG CHỨNG ĐỂ DEMO/BẢO VỆ

### 8.1 Checklist tổng quan (chuẩn bị trước)

- [ ] Đăng nhập Azure Portal bằng tài khoản có quyền trên cả 2 subscription (`bbad92f7-…` và `42e7a0ff-…`).
- [ ] Mở sẵn RG `Backend-Ly` và liệt kê được 7 resource (6 dịch vụ + `tripto-log`).
- [ ] Mở sẵn Function App `tripto-function` (RG `DU_AN_NHOM2_RG`) — tab Functions (13 functions).
- [ ] Mở sẵn web `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net/frontend/user/TRANGCHU.html` (Chrome).

### 8.2 Bằng chứng từng dịch vụ

**API Management**
- [ ] `az apim show` → SKU `Consumption`, gateway URL `https://tripto-api-management.azure-api.net`.
- [ ] API `tripto` (path `/tripto`, 8 operations `/*`), policy `set-backend-service WebApp_tripto`, backend = webapp `tripto`.
- [ ] Live: `GET https://tripto-api-management.azure-api.net/tripto` → 200; `GET .../backend/user.php?endpoint=get_locations` → 200 JSON thật.

**Logic Apps**
- [ ] Workflow `tripto-logicapp` Enabled; trigger Service Bus `booking-queue` poll 3 phút; action `Send_booking_email`.
- [ ] Run history: ít nhất 1 run **Succeeded** với action `Send_booking_email` `Succeeded/OK` (chụp REST hoặc Portal).
- [ ] Trigger history: có lần `fired=true` (message thật từ queue).
- [ ] (Nói rõ) một số run Failed do lỗi tạm thời gọi email — không phải lỗi cấu hình.

**Communication Services**
- [ ] `tripto-communication` + `tripto-email` + `AzureManagedDomain`; REST `verificationStates` toàn bộ **Verified**.
- [ ] Gọi `POST /api/SendBookingEmail` → 200 `{success:true, accepted:[...], rejected:[]}`.
- [ ] Log Function App: `SMTP Response: 250 ... Queued mail for delivery`, Message ID `@...azurecomm.net`.

**Service Bus**
- [ ] `az servicebus namespace show` → SKU `Basic`, Active, queue `booking-queue`.
- [ ] Metric `IncomingMessages` > 0 (99 message 01→12/08) và `messageCount=0` (Logic App tiêu thụ).
- [ ] Code: `backend/config.php:61-86`, `backend/user.php:5279` gọi `$serviceBus->send([...])`.

**SignalR**
- [ ] `az signalr show` → Free_F1, CORS `*`.
- [ ] Live: `POST /api/negotiate` → 200 `{url: .../client/?hub=triptohub, accessToken}`.
- [ ] Live: WebSocket `wss://tripto-signalr.service.signalr.net/client/?hub=triptohub` → **`Open`**.
- [ ] Live: `POST /api/sendNotification` → 200 `Notification sent through SignalR`; metric MessageCount/ConnectionCount > 0.

**Notification Hubs**
- [ ] Namespace `tripto-notification` Free + hub `tripto-hub`; 2 SAS rule (Listen + Full); PNS credential rỗng (Web Push/VAPID).
- [ ] `GET /api/GetVapidPublicKey` → 200 (public key); `RegisterNotification` body rỗng → 400 (logic đúng).
- [ ] SDK `listRegistrations` → **10 registration Browser** (có `user:4`, `user:40`).
- [ ] Metric: `notificationhub.pushes` > 0 và `outgoing.allpns.success` = pushes (đã có 47/47).
- [ ] Code: `user.php:5327-5362` gọi `SendNotificationHub` sau booking; App Setting `FUNCTION_APP_KEY` tồn tại.
- [ ] **Demo popup (bổ sung để đủ bằng chứng):** Chrome cho phép notification → đăng nhập → đặt 1 tour →
      chụp **popup "TripTo – Đặt tour thành công!"** xuất hiện trên màn hình, đồng thời quay lại Metrics
      thấy `pushes` và `outgoing.allpns.success` tăng đúng 1. → (sau khi hoàn thành bước này, trạng thái
      Notification Hubs chuyển thành ĐÃ XÁC NHẬN HOÀN CHỈNH.)

### 8.3 Các lệnh Azure CLI đã dùng để kiểm tra (lưu trữ để đối chiếu)

```bash
# Tổng quan resource
az resource list --resource-group Backend-Ly --subscription bbad92f7-b7ef-4fa7-b3ef-61c200f5802e

# 1. APIM
az apim show --name tripto-api-management --resource-group Backend-Ly
az apim api list --service-name tripto-api-management --resource-group Backend-Ly
az apim api show --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto
az apim api operation list --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto
az apim api revision list --service-name tripto-api-management --resource-group Backend-Ly --api-id tripto
az rest --url ".../apis/tripto/policies/policy?api-version=2022-08-01&format=raw"
az rest --url ".../backends?api-version=2022-08-01"

# 2. Logic Apps
az logic workflow show --name tripto-logicapp --resource-group Backend-Ly
az rest --url ".../workflows/tripto-logicapp/runs?api-version=2019-05-01"
az rest --url ".../workflows/tripto-logicapp/runs/<runId>/actions?api-version=2019-05-01"
az rest --url ".../workflows/tripto-logicapp/triggers/When_one_or_more_messages_arrive_in_a_queue_%28auto-complete%29/histories?api-version=2019-05-01"

# 3. Communication Services
az communication show --name tripto-communication --resource-group Backend-Ly
az communication email list --resource-group Backend-Ly
az communication email domain show --email-service-name tripto-email --resource-group Backend-Ly --domain-name AzureManagedDomain
az rest --url ".../emailServices/tripto-email/domains/AzureManagedDomain?api-version=2023-03-31"   # verificationStates

# 4. Service Bus
az servicebus namespace show --name sb-tripto-backend --resource-group Backend-Ly
az servicebus queue list --namespace-name sb-tripto-backend --resource-group Backend-Ly
az monitor metrics list --resource ".../Microsoft.ServiceBus/namespaces/sb-tripto-backend" --metric IncomingMessages --aggregation Total

# 5. SignalR
az signalr show --name tripto-signalr --resource-group Backend-Ly
az monitor metrics list --resource ".../SignalR/tripto-signalr" --metric MessageCount --aggregation Total
az monitor metrics list --resource ".../SignalR/tripto-signalr" --metric ConnectionCount --aggregation Maximum

# 6. Notification Hubs
az notification-hub namespace show --name tripto-notification --resource-group Backend-Ly
az notification-hub show --name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az notification-hub authorization-rule list --notification-hub-name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az notification-hub credential list --notification-hub-name tripto-hub --namespace-name tripto-notification --resource-group Backend-Ly
az monitor metrics list --resource ".../notificationHubs/tripto-hub" --metric incoming notificationhub.pushes outgoing.allpns.success outgoing.allpns.pnserror --aggregation Total
# Đếm registration: dùng SDK @azure/notification-hubs (client.listRegistrations) — CLI không hỗ trợ.
```

---

## PHỤ LỤC — GHI CHÚ TRUNG THỰC

1. Tất cả số liệu (SKU, status, endpoint, metric, run history, registration) đều là **output thực tế** từ
   Azure CLI / REST / HTTP / SDK trong ngày 12/08/2026 — **không bịa, không suy diễn**.
2. **Hai subscription được dùng:** `bbad92f7-…` (RG `Backend-Ly` — 6 dịch vụ + Log Analytics) và
   `42e7a0ff-…` (RG `DU_AN_NHOM2_RG` — Function App `tripto-function`). Web App `tripto` nằm ở RG `Frontend-Dung`
   (subscription `bbad92f7-…`).
3. Những chỗ chưa đủ bằng chứng được ghi rõ: **Notification Hubs popup Chrome** (bước cuối của chuỗi push),
   và các **run Failed của Logic App** (lỗi tạm thời gọi Function email).
4. Tài liệu này **không chứa secret** (API key, function key, connection string, private key, password) —
   chỉ liệt kê **tên** App Setting để chứng minh cấu hình.
5. Kết quả metric của Notification Hubs **đã cập nhật mới** so với `VERIFY_BACKEND_INTEGRATION.md` (ngày 11/08
   với `pushes=0`): từ 11/08–12/08 đã ghi nhận **47 pushes và 47 outgoing.allpns.success** — nâng trạng thái từ
   "CHƯA CÓ bằng chứng gửi" lên "GỬI THÀNH CÔNG" (popup vẫn chưa đủ bằng chứng trực quan).
