# HƯỚNG DẪN HOÀN CHỈNH — DỊCH VỤ AZURE NOTIFICATION HUBS BROWSER PUSH (TRIPTO)

> Tài liệu tổng hợp toàn bộ cách dịch vụ Browser Push của TripTo được xây dựng, triển khai,
> kiểm tra thực tế trên production và cách chứng minh trước giảng viên.
> Mọi thông tin trong tài liệu này đều là những gì đã được kiểm tra và xác nhận trong quá trình triển khai.
>
> **Lưu ý bảo mật:** Tài liệu này KHÔNG chứa private key, Function Key, connection string hoặc bất kỳ secret nào.
> Các secret được lưu trong App Settings của Azure và không được công khai.

---

========================================
## 1. TỔNG QUAN DỊCH VỤ
========================================

### Azure Notification Hubs dùng để làm gì trong TripTo?

Azure Notification Hubs là dịch vụ **đẩy thông báo (push notification)** do Azure quản lý. Trong TripTo,
dịch vụ này dùng để gửi **Browser Push Notification** — tức là các thông báo hệ thống hiện lên trên
**trình duyệt Chrome** (dạng popup Windows), kể cả khi người dùng không mở website ở tab đang hoạt động.

### Vì sao sử dụng Browser Push?

- Website TripTo chạy trên trình duyệt (Web PWA), không phải app di động, nên không dùng APNS/FCM cho thiết bị di động.
- Browser Push sử dụng chuẩn **Web Push PWA + VAPID** do W3C định nghĩa, được Chrome/Firefox/Edge hỗ trợ.
- Cho phép thông báo "Đặt tour thành công" hiện trực tiếp trên màn hình Windows (popup), tạo trải nghiệm realtime tốt hơn.
- Azure Notification Hubs quản lý tập trung danh sách các trình duyệt đã đăng ký (installation/registration).

### Khi nào notification được gửi?

- **Trigger chính:** khi người dùng thực hiện **ĐẶT TOUR thành công** trên website.
- Sau khi backend `user.php` xác nhận booking thành công, nó gọi API `SendNotificationHub` để đẩy thông báo.

### Notification được gửi đến đâu?

- Đến **đúng trình duyệt của người dùng** đã đăng ký (dùng tag `user:<userId>` để định tuyến theo tài khoản).
- Đi qua chuỗi: Function App → Notification Hub `tripto-hub` → FCM (Web Push) → Service Worker → Chrome → Popup.

### Luồng hoàn chỉnh

```
User
→ Website TripTo (mở Chrome, đăng ký push)
→ Đặt tour
→ Backend user.php (xử lý booking thành công)
→ gọi API SendNotificationHub
→ Azure Notification Hub tripto-hub
→ FCM / Browser Push (Web Push PWA + VAPID)
→ Service Worker (sw.js) nhận sự kiện "push"
→ Chrome hiển thị Popup notification
```

---

========================================
## 2. CÁC THÀNH PHẦN ĐÃ XÂY DỰNG
========================================

### FRONTEND

| Thành phần | Vị trí | Vai trò |
|---|---|---|
| `push-notification.js` | `frontend/js/push-notification.js` | Tự động chạy ở mọi trang user (khi `DOMContentLoaded`). Đăng ký Service Worker, xin quyền Notification, tạo Push Subscription, tạo/lấy **installation ID** (lưu localStorage), gọi `RegisterNotification` kèm `userId`. |
| `sw.js` | `sw.js` (gốc website, serve ở `/sw.js`) | **Service Worker**. Lắng nghe sự kiện `push`, parse payload (`title`, `body`), gọi `showNotification()` để Chrome hiển thị popup. Xử lý `notificationclick` để mở lại trang khi người dùng click. |

### BACKEND (hàm trong Function App `tripto-function`, Node.js)

| Thành phần | Vai trò |
|---|---|
| `GetVapidPublicKey` | HTTP GET, trả về **VAPID public key** (đọc từ App Setting `VAPID_PUBLIC_KEY`). Frontend dùng key này để tạo Push Subscription. |
| `RegisterNotification` | HTTP POST. Nhận `installationId`, `endpoint`, `p256dh`, `auth`, `userId`. Tạo/ghi installation vào Notification Hub với tag `user:<userId>`. |
| `SendNotificationHub` | HTTP POST (authLevel = function, cần `x-functions-key`). Nhận `{ title, body, tag }`, tạo `createBrowserNotification` và gửi qua Notification Hub tới installation (khi tag là `$InstallationId:<id>`) hoặc theo `tagExpression` (khi tag là `user:<id>`). Trả về `trackingId`. |
| `user.php` | Backend PHP (deploy trên web app `tripto`). Xử lý đặt tour; **sau khi booking thành công**, gọi `POST /api/SendNotificationHub` với `tag: user:<id_nguoi_dung>`. |

### AZURE

| Thành phần | Thông tin | Vai trò |
|---|---|---|
| Function App | `tripto-function` — subscription `42e7a0ff-…`, RG `DU_AN_NHOM2_RG`, URL `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net` | Host các function `GetVapidPublicKey`, `RegisterNotification`, `SendNotificationHub`, `sendNotification` (SignalR), `SendBookingEmail`, `negotiate`, … |
| Notification Hub Namespace | `tripto-notification` — RG `Backend-Ly` | Namespace chứa hub. |
| Notification Hub | `tripto-hub` (SKU Free) — trong `tripto-notification` | Lưu các **installation/registration** của trình duyệt (có tag `user:<id>`), nhận lệnh gửi và đẩy ra PNS. |
| VAPID credentials | Lưu trong **App Settings của Function App** (`VAPID_PUBLIC_KEY`, private key tương ứng). KHÔNG công khai private key. | Xác thực việc gửi Web Push tới Chrome. |
| APIM | `tripto-api-management.azure-api.net/tripto/user.php` | Cổng trung gian: frontend gọi booking qua APIM → `user.php` trên web app `tripto`. |
| Web App | `tripto` — RG `Frontend-Dung` | Serve frontend + backend PHP production. Có App Setting `FUNCTION_APP_KEY` (key gọi function), `SERVICEBUS_KEY`, `DB_*` (qua Key Vault). |

---

========================================
## 3. CÁCH HOẠT ĐỘNG
========================================

Từng bước từ lúc người dùng mở website:

1. **Browser đăng ký Service Worker** — Mỗi trang user load `push-notification.js`; ở `DOMContentLoaded`, gọi `initPushNotifications()` → `navigator.serviceWorker.register('/sw.js')`.
2. **Browser xin quyền Notification** — `Notification.requestPermission()`; nếu người dùng đồng ý (granted), tiếp tục.
3. **Browser tạo Push Subscription** — Gọi `pushManager.subscribe()` với VAPID public key lấy từ `GetVapidPublicKey`. Kết quả là một subscription có `endpoint` (URL FCM Web Push), `p256dh`, `auth`.
4. **Frontend lấy installation ID** — Tạo mới hoặc đọc lại từ `localStorage` (key `tripto_notification_installation_id`) → `installationId`.
5. **RegisterNotification đăng ký browser vào Notification Hub** — Frontend gọi `POST /api/RegisterNotification` với `{ installationId, endpoint, p256dh, auth, userId }`. Function lưu installation vào hub `tripto-hub` với tag `user:<userId>`.
6. **Khi user đặt tour, backend xử lý booking** — Frontend gọi `user.php?endpoint=create_booking` (qua APIM). Backend ghi booking vào bảng `dat_tour`.
7. **Sau khi booking thành công, user.php gọi SendNotificationHub** — Sau khi trả response 201 + flush về client, backend chạy tác vụ nền và gọi `POST /api/SendNotificationHub` với body `{ title: "TripTo", body: "Đặt tour thành công! …", tag: "user:<id_nguoi_dung>" }` kèm `x-functions-key` (lấy từ App Setting `FUNCTION_APP_KEY`).
8. **Function gửi notification đến Notification Hub** — `SendNotificationHub` dùng SDK `@azure/notification-hubs`, tạo browser notification và gọi `sendNotification` tới hub theo tag.
9. **Notification Hub gửi tới FCM/browser** — Hub tìm các installation khớp tag `user:<id>` và đẩy payload Web Push qua FCM.
10. **Service Worker nhận notification** — Trình duyệt nhận push, đánh thức Service Worker `sw.js`; handler `push` parse `title`/`body` và gọi `showNotification`.
11. **Chrome hiển thị popup** — Popup Windows xuất hiện: `"TripTo — Đặt tour thành công! Thông tin đặt tour của bạn đã được ghi nhận."`

> Tóm tắt 1 câu: *"Người dùng đặt tour → backend xác nhận thành công → gọi SendNotificationHub → hub đẩy qua FCM → Service Worker → popup Chrome."*

---

========================================
## 4. CÁCH TEST THỰC TẾ TRÊN WEBSITE
========================================

Hướng dẫn từng bước (sinh viên tự thực hiện trên máy):

**Bước 1 — Mở website production (dùng Chrome):**
```
https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net/frontend/user/TRANGCHU.html
```

**Bước 2 — Cho phép Browser Notification:**
- Lần đầu mở, Chrome sẽ hiện hộp thoại *"tripto-…azurewebsites.net muốn gửi thông báo"* → chọn **Cho phép**.
- (Nếu không thấy hộp thoại: bấm icon 🔔 bên phải thanh địa chỉ → chọn **Cho phép**, rồi tải lại trang.)

**Bước 3 — Đăng nhập tài khoản:**
- Bấm Đăng nhập trên website và đăng nhập tài khoản của bạn.
- (Việc đăng nhập quan trọng vì lúc này trình duyệt tự **re-register** với tag `user:<id>` của bạn.)

**Bước 4 — Chọn một tour:**
- Trên trang chủ, chọn bất kỳ tour nào → xem chi tiết tour.

**Bước 5 — Nhấn Đặt tour:**
- Bấm nút Đặt tour → đến trang thanh toán.

**Bước 6 — Điền thông tin và xác nhận đặt tour:**
- Điền số người, ngày khởi hành, phương thức thanh toán → bấm nút **Xác nhận**.

**Bước 7 — Chờ khoảng 1–2 giây.**

### Kết quả mong đợi

Trên Chrome/Windows sẽ hiện popup:

```
TripTo
Đặt tour thành công! Thông tin đặt tour của bạn đã được ghi nhận.
```

Đây chính là **bằng chứng TEST END-TO-END thực tế**: thao tác trên website → backend → Azure Notification Hub → FCM → Service Worker → popup trên máy thật.

> **Mẹo kiểm chứng nhanh trong DevTools (F12):** mở tab *Console* trước khi đặt tour.
> Sau khi đặt tour thành công, nếu Service Worker nhận push sẽ in `[sw] push received: TripTo …`.
> Tab *Application → Service Workers* cho thấy sw.js `activated`, mục *Push* hiện subscription đang hoạt động.

---

========================================
## 5. CÁCH CHỨNG MINH TRÊN AZURE
========================================

Hướng dẫn vào Azure Portal để chứng minh dịch vụ đang chạy.

### A. Notification Hub

1. Đăng nhập https://portal.azure.com.
2. Tìm **Resource Groups** → chọn `Backend-Ly`.
3. Mở namespace **`tripto-notification`** → mở Notification Hub **`tripto-hub`**.

**Cần chụp màn hình:**
- Trang **Overview** của `tripto-notification` và `tripto-hub` (chứng minh resource tồn tại).
- Trang **Metrics** (mục D bên dưới) có biểu đồ `notificationhub.pushes` / `outgoing.allpns.success` khác 0.
- (Danh sách registration/installation nếu portal cho phép; ngược lại dùng metric `registration.all` / `installation.all` làm bằng chứng có device đăng ký.)

### B. Browser / VAPID

- VAPID key được quản lý bởi **Function App**, không nằm trên hub.
- Vào **Function App `tripto-function`** → **Configuration → Application settings** → thấy các biến `VAPID_PUBLIC_KEY` (public key) và biến chứa private key.
- **KHÔNG chụp giá trị private key / không công khai**. Chỉ cần chụp **danh sách tên App Setting** (che giá trị) hoặc chụp response của function `GetVapidPublicKey` (chỉ có public key, an toàn).
- Minh chứng credential tồn tại: mở URL `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net/api/GetVapidPublicKey` → trả về `{"publicKey":"…"}` (HTTP 200).
- Lưu ý (đã xác nhận): hub không có PNS credential cổ điển (GCM/APNS/WNS) — hợp lý vì TripTo dùng **Web Push PWA qua VAPID**, không cần cấu hình credential thiết bị di động.

### C. Function App

1. Trong portal, chọn **Function App `tripto-function`** (RG `DU_AN_NHOM2_RG`, subscription `Azure for Students` thứ nhất — `42e7a0ff-…`).
2. Mở **Functions** → danh sách có đủ:
   - **GetVapidPublicKey**
   - **RegisterNotification**
   - **SendNotificationHub**

**Cần chụp màn hình:**
- Danh sách Functions (đủ 3 hàm trên) + trạng thái **Enabled/Running**.
- Trang *Code + Test* của từng hàm (chứng minh code tồn tại) — không cần chụp toàn bộ.
- Trang **Overview** có phần *Recent Invocations* nếu đã gọi — bằng chứng hàm được thực thi.

### D. Metrics / Monitoring

Tại Notification Hub `tripto-hub` → chọn **Metrics** (trong Azure Monitor), chọn metric và khoảng thời gian (vd: 7 ngày, aggregation **Sum**):

| Metric | Ý nghĩa | Cách đọc |
|---|---|---|
| `incoming` | Số request gửi đến hub (đăng ký + gửi) | > 0 nghĩa là hub có hoạt động |
| `notificationhub.pushes` | Số lần lệnh **gửi push** được gửi tới hub | Mỗi lần đặt tour thành công → tăng 1 |
| `outgoing.allpns.success` | Số push **được PNS/FCM xác nhận gửi thành công** | Bằng hoặc xấp xỉ `pushes` = delivery thành công |
| `outgoing.allpns.pnserror` | Số push bị PNS trả lỗi | 0 ở luồng đã verify = không lỗi |

**Cách đọc kết quả:** Lấy 1 khoảng thời gian có thao tác đặt tour. Nếu `notificationhub.pushes` tăng đúng 1 khi bạn đặt 1 tour VÀ `outgoing.allpns.success` cũng tăng tương ứng → chứng minh notification đã được gửi và **delivery thành công**.

### E. Logs

- **Function App → Overview → "Application Insights" / LogStream:** chứng minh các function được gọi. Gợi ý mở LogStream rồi đặt tour → thấy request đến `SendNotificationHub`.
- **Application Insights (resource `tripto-function`):** query `requests` / `traces` lọc theo `SendNotificationHub` để thấy invocations trả 200.
- **Cách chứng minh SendNotificationHub được gọi thành công từ luồng đặt tour:**
  1. Mở Notification Hub Metrics → ghi lại `notificationhub.pushes`.
  2. Đặt 1 tour trên website.
  3. Quay lại Metrics → `pushes` tăng đúng 1 và `outgoing.allpns.success` tăng tương ứng.
  4. Trên Chrome xuất hiện popup.
  → Kết hợp 4 bằng chứng này = SendNotificationHub đã được gọi và gửi thành công.

---

========================================
## 6. CÁCH CHỨNG MINH END-TO-END
========================================

Checklist đầy đủ — tất cả đều **PASS** thì dịch vụ đã triển khai hoàn chỉnh:

```
[ ] Browser subscription tồn tại            (Chrome đã subscribe push)
[ ] Registration tồn tại trong Notification Hub   (hub có installation của trình duyệt)
[ ] VAPID credential hợp lệ                  (GetVapidPublicKey trả 200 + public key)
[ ] Function SendNotificationHub hoạt động   (gọi API trả 200 + trackingId)
[ ] Đặt tour thành công                      (create_booking trả 201 success)
[ ] SendNotificationHub được gọi             (backend gọi sau booking)
[ ] Notification Hub ghi nhận push           (metric notificationhub.pushes tăng)
[ ] PNS/FCM delivery thành công              (metric outgoing.allpns.success tăng)
[ ] Service Worker nhận push                 (sw.js handler "push" chạy)
[ ] Chrome hiện popup                        (popup Windows xuất hiện)
```

> Khi tất cả đều PASS → toàn bộ chuỗi từ website → backend → Azure Notification Hubs → FCM → Service Worker → Chrome hoạt động liền mạch.

---

========================================
## 7. BẰNG CHỨNG THỰC TẾ ĐÃ CÓ
========================================

Các số liệu sau được ghi nhận thật trong quá trình kiểm tra (không bịa thêm):

- **2 booking production đã được test** bằng luồng thật (qua APIM → `user.php?endpoint=create_booking`), đều trả `201 success` và mỗi booking kích hoạt đúng **1 lần gửi push**.
- **Notification Hub `pushes = 5`** (metric `notificationhub.pushes`, cửa sổ 48h) — tăng chính xác theo từng lần gửi.
- **`outgoing.allpns.success = 5`** — đúng khớp 1:1 với `pushes` → **5/5 push được FCM xác nhận gửi thành công**.
- **Lỗi PNS ở luồng đã verify: 0** — các lần gửi cuối (test trực tiếp + 2 booking production) đều thành công, không ghi nhận `pnserror`.
  - *Ghi chú trung thực:* metric `outgoing.allpns.pnserror` có hiển thị một số lỗi từ các lần **thử nghiệm trước khi hoàn thiện** (thời điểm 12:30–13:15 UTC cùng ngày, từ các lần test installation/thử lỗi trước khi fix connection string) — không thuộc luồng đang hoạt động và không tái diễn sau khi đã sửa.
- **FCM direct delivery trả `201 Created`** — gửi thẳng Web Push tới subscription của Chrome → FCM xác nhận nhận → chứng minh subscription hợp lệ.
- **`SendNotificationHub` trả `HTTP 200` + `trackingId`** (vd `0ee00ccd-…`, `696c7db2-…`) — function deployed chạy đúng, gửi qua hub thành công.
- **Chrome đã thực tế hiện popup "Đặt tour thành công! Thông tin đặt tour của bạn đã được ghi nhận."** trong quá trình test booking.
- **Hub có 5 registration thật** của các trình duyệt đã đăng ký (trong đó có Chrome đang dùng, installation `f22e2ebc-…`).
- **Function deployed khớp repo**: `sendNotificationHub.js` deploy trên server giống hệt mã nguồn (xác nhận qua Kudu VFS).

---

========================================
## 8. CÁC FILE ĐÃ THAY ĐỔI
========================================

### Các file ĐÃ thay đổi (đã deploy lên production)

| File | Thay đổi |
|---|---|
| `backend/user.php` | Thêm khối gọi `SendNotificationHub` trong `handleCreateBooking()` sau khi booking thành công (chạy trong tác vụ nền, sau khi đã trả response 201) — gửi `{ title: "TripTo", body: "Đặt tour thành công! …", tag: "user:<id_nguoi_dung>" }` với header `x-functions-key` lấy từ App Setting `FUNCTION_APP_KEY`. Đồng thời sync 2 chỉnh sửa đang chạy sẵn trên production (bỏ CORS trùng ở đầu file — đã chuyển về `config.php`; xử lý URL ảnh tuyệt đối bắt đầu bằng `http`). |
| `backend/config.php` | Đồng bộ tên container Blob đúng với production (`tour-images`). |

> Ngoài ra còn **thêm App Setting `FUNCTION_APP_KEY`** trên web app `tripto` (giá trị = Function Key, KHÔNG ghi vào source).

### Các file KHÔNG thay đổi (đã xác nhận deploy khớp repo)

- `frontend/js/push-notification.js` — **không đổi**, đã deploy đúng.
- `sw.js` — **không đổi**, đã deploy đúng.
- `backend/function/src/functions/sendNotificationHub.js` — **không đổi**, deploy trên server khớp 100% repo.

---

========================================
## 9. CÁC AZURE SERVICE KHÁC
========================================

Browser Push được **thêm song song** vào hệ thống, **không thay thế** bất kỳ dịch vụ nào đang chạy.

### Luồng hiện tại khi đặt tour

```
Đặt tour thành công
├── Service Bus  vẫn chạy    → gửi booking-queue → SendBookingEmail (email xác nhận)
├── SignalR      vẫn chạy    → gửi sự kiện "booking_success" → toast realtime trong website
└── Notification Hub chạy thêm  → Browser Push → popup Chrome   (THÊM MỚI)
```

- **Service Bus** (`sb-tripto-backend`, queue `booking-queue`): vẫn gửi message booking → logic app/function `SendBookingEmail` gửi email. Không bị ảnh hưởng.
- **SignalR** (`tripto-signalr`, hub `triptoHub`): vẫn gửi event `newNotification` → client `signalr.js` hiện toast ngay trong trang. Không bị ảnh hưởng.
- **API Management** (`tripto-api-management`): vẫn là cổng frontend → `user.php`. Không đổi.
- **Notification Hubs** (`tripto-notification` / `tripto-hub`): **thêm vào** như một nhánh bổ sung — chỉ phụ trách Browser Push.
- Các service khác (MySQL `tripto-mysql-db`, Blob Storage, Key Vault `triptokv`, Application Insights, Communication Services) đều giữ nguyên.

> Thiết kế "nhánh bổ sung": code gọi `SendNotificationHub` nằm trong khối tác vụ nền sau khi booking đã thành công và được bọc `try/catch` — nếu push thất bại sẽ chỉ ghi log, **không bao giờ làm hỏng luồng đặt tour** (Service Bus / SignalR / response vẫn hoạt động bình thường).

---

========================================
## 10. CHECKLIST DEMO CHO GIẢNG VIÊN
========================================

Checklist cực ngắn khi thuyết trình:

1. Mở **Azure Portal** → RG `Backend-Ly` → chỉ **Notification Hub** `tripto-notification` / `tripto-hub`.
2. Chỉ **Function App** `tripto-function` → 3 hàm `GetVapidPublicKey`, `RegisterNotification`, `SendNotificationHub`.
3. Chỉ **Browser/VAPID credential** đã cấu hình (tên App Setting + response `GetVapidPublicKey`, KHÔNG lộ private key).
4. Chỉ **Metrics/Monitoring** của hub: `notificationhub.pushes`, `outgoing.allpns.success` (số > 0).
5. Mở **website production** bằng Chrome.
6. **Cho phép notification** + **đăng nhập**.
7. Chọn tour → **Đặt tour** → xác nhận.
8. **Popup xuất hiện** trên Chrome/Windows: "TripTo — Đặt tour thành công! …".
9. Quay lại **Azure Metrics** → chỉ biểu đồ `pushes` và `success` tăng lên → chứng minh push thành công.

---

========================================
## 11. KẾT LUẬN
========================================

> Dịch vụ **Azure Notification Hubs Browser Push** đã được tích hợp thành công vào hệ thống TripTo.
> Dịch vụ được kích hoạt bởi thao tác **đặt tour**: ngay sau khi backend `user.php` xác nhận booking thành công,
> hệ thống gọi API **SendNotificationHub** trên Function App `tripto-function`, thông qua Azure Notification Hub
> **`tripto-hub`** và chuẩn **Web Push PWA + VAPID** để đẩy notification tới đúng trình duyệt đã đăng ký của người dùng.
> Service Worker `sw.js` nhận sự kiện push và **Chrome hiển thị popup** "TripTo — Đặt tour thành công! …" trên Windows.
> Toàn bộ chuỗi đã được **kiểm tra thực tế trên production** với 2 booking thật: Notification Hub ghi nhận
> `pushes = 5` và `outgoing.allpns.success = 5` (5/5 delivery thành công, 0 lỗi PNS ở luồng đã verify),
> FCM xác nhận gửi thành công (HTTP 201), API SendNotificationHub trả HTTP 200 kèm trackingId,
> và popup notification đã thực sự xuất hiện trên Chrome trong quá trình test.
> Dịch vụ được thêm **song song** mà không ảnh hưởng đến Service Bus, SignalR, API Management
> và các dịch vụ Azure đang hoạt động khác của hệ thống.
