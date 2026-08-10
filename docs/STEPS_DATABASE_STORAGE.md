# Các bước đã thực hiện — Database & Storage (Máy 3)

Người thực hiện: `NgocLan (0023411831@student.dthu.edu.vn)`. Resource Group chính: `DU_AN_NHOM2_RG`.
Dựa trên bằng chứng trong repo: `backend/config.php`, `backend/.env.example`, `backend/redis.php`, `backend/blob/*`, `backend/function/*`, `scripts/runbook-mysql-backup.ps1`, `infrastructure/account2/PROGRESS.md`, lịch sử git.

---

## KIẾN TRÚC TỔNG THỂ

```
Trình duyệt (frontend/user/TRANGCHU.html)
   │  POST /api/track-visit
   ▼
[FUNCTION APP: tripto-function]  ──(bước 1)──►  [STORAGE ACCOUNT: sttriptobackup]
   │                                         │   container `web-visits/` (blob JSON lượt truy cập)
   │                                         ▼
   │                              [EVENT GRID: tripto-visit-created]
   │                                         │  Microsoft.Storage.BlobCreated
   │                                         ▼
   │                              [FUNCTION: BlobEventHandler]  ──►  [REDIS: tripto-redis C0]
   │                                                                  key `tripto:visits:total` (INCR)
   │  GET /api/visits (đọc tổng lượt từ Redis)
   ▼
[AZURE DATABASE FOR MYSQL FLEXIBLE SERVER: tripto-mysql-db (B1s)]
   │  DB `tripto_db`, user `nhom2`, SSL bắt buộc, PITR 7 ngày
   ▼
[STORAGE ACCOUNT: sttriptobackup]
   ├── container `tour-images/`  ←  ảnh tour upload từ admin (BlobStorage.php)
   ├── container `web-visits/`   ←  blob theo dõi lượt truy cập (trackVisit)
   ├── container `mysql-backups/`←  log backup MySQL (runbook hằng ngày 02:00)
   └── file share `tripto-share`
```

---

## DỊCH VỤ 1 — Azure Database for MySQL – Flexible Server `tripto-mysql-db` (B1s)

### Ý nghĩa — nó là gì

Azure Database for MySQL **Flexible Server** là dịch vụ cơ sở dữ liệu MySQL được quản lý hoàn toàn trên Azure:
- Tự động **backup & PITR** (Point-In-Time Restore), đã bật retention **7 ngày** (xác nhận trong `infrastructure/account2/PROGRESS.md:202`).
- Bật **SSL/TLS bắt buộc** cho mọi kết nối (bảo mật dữ liệu truyền qua mạng).
- Tier **B1s** (Burstable — CPU linh hoạt, chi phí thấp, phù hợp sinh viên), region **Southeast Asia**.
- Bạn chỉ quản lý dữ liệu, không phải quản lý máy chủ/OS/backup thủ công.

### Các bước đã làm

1. **Tạo server**: Portal Azure → **Azure Database for MySQL** → **Flexible Server** → **Create**.
   - Name: `tripto-mysql-db`
   - Resource Group: `DU_AN_NHOM2_RG`
   - Compute + storage: tier **Burstable (B1s)**, 1 vCore, 2GB RAM.
   - Region: **Southeast Asia**.
   - Backup retention: **7 ngày**.
   - Connect method: chọn **Public access** + cấu hình firewall cho IP cần kết nối (web App Service, máy dev).
2. **Tạo database + user** trong server:
   - Database: `tripto_db` (schema import từ `database/tripto.sql` — xem commit `1b5be69`, `5ef95df`).
   - User: `nhom2` (được cấp quyền trên `tripto_db`).
3. **Cấu hình kết nối trong code** (`backend/config.php:8-11`):
   ```php
   DB_HOST  = tripto-mysql-db.mysql.database.azure.com
   DB_USER  = nhom2
   DB_NAME  = tripto_db
   DB_PASS  = <từ env / Key Vault>
   ```
4. **Kết nối SSL + persistent** trong `config.php`:
   - `mysqli_ssl_set(...)` → kết nối mã hoá.
   - `real_connect('p:' . DB_HOST, ..., MYSQLI_CLIENT_SSL)` → dùng kết nối **persistent** (`p:`) để PHP-FPM tái sử dụng connection → giảm độ trễ bắt tay TCP+TLS mỗi request.
5. **Đẩy log lên giám sát**: Diagnostic Setting `ds-mysql-to-law` → Log Analytics `law-tripto` (các log `MySqlSlowLogs`, `MySqlAuditLogs`, `AllMetrics`) — ghi trong `PROGRESS.md:105`.
6. **Backup tự động bằng runbook**: Automation Account `aa-tripto` chạy `runbook-mysql-backup` hằng ngày lúc **02:00** để kiểm tra server sẵn sàng + ghi log backup lên blob (chi tiết Dịch vụ 2).

### Kết quả đạt được

- Web (`tripto`, `tripto2`) kết nối `tripto_db` thành công — đọc/ghi dữ liệu tour, tài khoản, đặt tour bình thường.
- Mọi kết nối đều qua SSL (không lỗi require_secure_transport).
- Backup tự động 7 ngày + PITR → có thể khôi phục về bất kỳ thời điểm nào trong 7 ngày nếu sự cố.
- Runbook backup test thành công: job `faf11d1c` Completed, log `backup-check-20260731-121925.log` đã lên blob (PROGRESS.md:65).

### Cách cấu hình sau (hướng dẫn duy trì)

- **Đổi password / thêm user**: Portal → server → **Server parameters** hoặc dùng lệnh `az mysql flexible-server parameter set`.
- **Mở firewall cho IP mới** (vd máy dev): Portal → server → **Networking** → **+ Add firewall rule**.
- **Khôi phục dữ liệu**: Portal → server → **Restore** → chọn điểm thời gian trong 7 ngày.
- **Nâng cấp tier**: thay đổi **Compute + storage** khi cần (B1s → B2s…).
- **Kết nối thử bằng CLI**:
  ```powershell
  mysql -h tripto-mysql-db.mysql.database.azure.com -u nhom2 -p --ssl-ca=DigiCertGlobalRootCA.crt.pem tripto_db
  ```

---

## DỊCH VỤ 2 — Storage Account `sttriptobackup`

### Ý nghĩa — nó là gì

Azure **Storage Account** là nơi lưu trữ "vô hạn" các loại dữ liệu phi cấu trúc trên Azure. Trong hệ thống này nó cung cấp:
- **Blob Storage**: lưu ảnh tour (`tour-images`), blob theo dõi lượt truy cập (`web-visits`), log backup (`mysql-backups`).
- **File Share**: chia sẻ file qua SMB (`tripto-share`) — dùng chung giữa các app.
- Kết hợp **Event Grid**: khi blob mới được tạo → tự động bắn sự kiện (xem Dịch vụ 5).

### Các bước đã làm

1. **Tạo Storage Account** `sttriptobackup`:
   - SKU: **Standard_LRS** (dự phòng cục bộ — rẻ, đủ cho dự án sinh viên), region **southeastasia**.
   - **Tắt truy cập public** blob: `-AllowBlobPublicAccess $false` (bảo mật — không cho ai đọc ảnh nếu không có quyền).
   - Lệnh tương đương (trong `scripts/runbook-mysql-backup.ps1:49-55`):
     ```powershell
     New-AzStorageAccount -ResourceGroupName DU_AN_NHOM2_RG -Name sttriptobackup `
       -Location southeastasia -SkuName Standard_LRS -AllowBlobPublicAccess $false
     ```
2. **Tạo các container**:
   - `tour-images` — ảnh tour (mặc định trong `config.php:15`).
   - `web-visits` — blob JSON mỗi lần khách truy cập trang chủ.
   - `mysql-backups` — log backup MySQL (Permission **Off**/private, `runbook-mysql-backup.ps1:72`).
3. **Tạo file share** `tripto-share` (đã tạo trong quá trình test backup, PROGRESS.md:203).
4. **Lưu thông tin kết nối**:
   - `config.php:14-17`: `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_CONTAINER`, `AZURE_STORAGE_CONNECTION_STRING`, `AZURE_STORAGE_ACCOUNT_KEY`.
   - Đặt qua **biến môi trường** trên App Service (không hardcode secret trong git).
5. **Viết class BlobStorage** tự viết bằng PHP (`backend/blob/BlobStorage.php`):
   - Tự dựng **SharedKey authorization header** (SHA-256 + HMAC) gọi REST API Azure Blob — không cần cài SDK nặng.
   - Các hàm: `upload()` (PUT BlockBlob), `uploadFromData()`, `delete()`, `getUrl()`.
6. **Tích hợp upload ảnh tour** vào admin (`backend/admin.php`, commit `f43b2f8`):
   - `addTour()` / `updateTour()`: nhận ảnh (file hoặc base64) → `sanitizeBlobName()` đặt tên an toàn → upload lên `tour-images` → lưu URL blob vào cột `url_anh_chinh` trong MySQL.
   - Khi đổi ảnh: xoá blob cũ bằng `getAzureBlobNameFromUrl()` + `delete()`.
   - `formatTourDataForAPI()` trả thẳng URL blob về frontend.
7. **Test local bằng Azurite** (emulator chạy ngay trên máy): repo có các file `__azurite_db_blob__.json`, `__azurite_db_queue__.json` → chứng minh đã phát triển/test upload blob cục bộ trước khi lên Azure.
8. **Đẩy log lên giám sát**: Diagnostic Setting `ds-storage-to-law` → Log Analytics `law-tripto` (`Transaction` + `Capacity` metrics). Đã verify: **AzureMetrics về liên tục** (276+ dòng 08/02, PROGRESS.md:107).

### Kết quả đạt được

- Upload ảnh tour qua admin thành công → ảnh lưu trên Azure, URL blob trả về cho frontend.
- Luồng theo dõi lượt truy cập: mỗi lần mở trang chủ → 1 blob JSON vào `web-visits/` (test qua `backend/blob/testBlob.php`).
- Runbook backup MySQL ghi log hằng ngày vào `mysql-backups/` — đã verify blob thật trên Azure (`backup-check-*.log`).
- Storage metrics đã stream về Log Analytics để giám sát.

### Cách cấu hình sau (hướng dẫn duy trì)

- **Upload file bằng tool**: Portal → Storage account → **Containers** → chọn container → **Upload**.
- **Cấp quyền đọc ảnh cho web**: nếu cần hiển thị ảnh công khai → bật **public access level = Blob** cho container `tour-images`, HOẶC cấp role **Storage Blob Data Reader** cho web (khuyến nghị — an toàn hơn).
- **Lấy connection string / key**: Portal → **Access keys** (hoặc **az storage account keys list**).
- **Xoá file cũ**: tự động bởi runbook (retention 14 ngày với log backup), hoặc xoá tay trong container.
- **Giám sát**: xem metric trong Portal → **Monitoring**, hoặc truy vấn Log Analytics bằng `AzureMetrics`.

---

## DỊCH VỤ 3 — Azure Cache for Redis `tripto-redis` (C0)

### Ý nghĩa — nó là gì

Azure **Cache for Redis** là dịch vụ **bộ nhớ đệm trong RAM** (in-memory cache) do Azure quản lý, dựa trên Redis.
- **C0** = tier Basic nhỏ nhất: **250 MB** RAM, 1 node (không HA), chi phí thấp — đủ cho dự án sinh viên.
- Dữ liệu đọc/ghi **siêu nhanh** (không qua đĩa cứng) → phù hợp: đếm lượt truy cập, trạng thái online của user, cache dữ liệu.
- Kết nối bằng **TLS** với access key (password) — cổng mặc định Azure Redis là **6380 (TLS)**, dự án cấu hình port **10000** trong `.env.example`/`redis.php` theo thông số server được cấp.

### Các bước đã làm

1. **Tạo cache**: Portal → **Azure Cache for Redis** → **Create**.
   - Name: `tripto-redis` (`infrastructure/account2` config; host `tripto-redis.southeastasia.redis.azure.net`).
   - SKU: **Basic C0** (250MB), region **Southeast Asia**.
   - Bật **SSL (TLS)** cho truy cập.
2. **Lấy thông tin kết nối**: host, port, primary access key (password) từ Portal → **Access keys**.
3. **Cấu hình code**:
   - `backend/.env.example:1-6`:
     ```
     REDIS_HOST=tripto-redis.southeastasia.redis.azure.net
     REDIS_PORT=10000
     REDIS_PASSWORD=<access key>
     REDIS_TLS=true
     ```
   - `backend/redis.php:3-7`: đọc host/port/password từ env, mặc định port `10000`.
   - `backend/RedisClient.php`: wrapper hỗ trợ cả **Predis** (composer) và **phpredis** (extension); tự fallback khi 1 cái không có. Dùng scheme `tls://`.
   - Trên App Service: đặt 3 biến env `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`.
4. **Test kết nối**:
   - `backend/test_env.php` — kiểm tra env đã load chưa.
   - `backend/test_predis.php` — `PING`, `SETEX tripto:test`, `GET tripto:test` qua TLS.
   - `backend/test_redis.php` — test qua wrapper `RedisClient`.
5. **Tích hợp nghiệp vụ**:
   - **Trạng thái online user** (`backend/user.php`): heartbeat cập nhật key `online:<user_id>` + timestamp; `online_users` endpoint đọc danh sách đang online từ Redis (`redis_available` trong JSON response).
   - **Đếm lượt truy cập** (phối hợp Function + Event Grid): key `tripto:visits:total` tăng bằng lệnh `INCR` (xem Dịch vụ 5–6).

### Kết quả đạt được

- Kết nối Redis qua TLS thành công (PING/SET/GET trả đúng).
- Đếm được tổng lượt truy cập web thật qua key `tripto:visits:total` — tăng 1 mỗi lần có blob visit mới.
- Chức năng **online/offline user** hoạt động dựa trên Redis (từng là dữ liệu volatile — đúng mục đích của Redis).

### Cách cấu hình sau (hướng dẫn duy trì)

- **Xem dữ liệu**: Portal → **Redis console** (chạy lệnh Redis như `GET tripto:visits:total`, `KEYS *`).
- **Đổi password**: Portal → **Access keys** → **Regenerate** (nhớ cập nhật env trên web).
- **Kết nối thử ngoài**:
  ```powershell
  redis-cli -h tripto-redis.southeastasia.redis.azure.net -p 10000 -a <password> --tls PING
  ```
- **Nâng tier**: Basic C0 → Standard/Enterprise khi cần HA, persistence, hoặc nhiều bộ nhớ hơn.
- **Theo dõi**: Portal → **Metrics** (Cache Hits/Misses, Server Load).

---

## DỊCH VỤ 4 — Virtual Network (VNet)

### Ý nghĩa — nó là gì

**Azure Virtual Network (VNet)** là "mạng riêng ảo" của bạn trên Azure: các tài nguyên trong VNet có **IP riêng**, **cô lập hoàn toàn với internet**, chỉ giao tiếp nội bộ (hoặc qua các rule firewall/routing được phép). Mục đích: **bảo mật** — DB, Redis, Storage không lộ ra public, chỉ service trong cùng VNet gọi được.

### Vị trí trong dự án

- Với cấu hình hiện tại, MySQL `tripto-mysql-db` dùng **Public access** (có firewall theo IP) — tiện cho sinh viên, đúng mức cần thiết.
- Azure Advisor đã khuyến nghị hạn chế truy cập mạng bằng VNet cho Storage Account (`monitoring/advisor-service-health-report.md:28`).
- **Chưa có VNet riêng được đưa vào repo** — đây là bước nâng cấp bảo mật nên làm sau.

### Các bước cấu hình VNet (hướng dẫn chuẩn để làm sau)

1. **Tạo VNet**: Portal → **Virtual networks** → **Create**.
   - Name: `vnet-tripto`, RG `DU_AN_NHOM2_RG`, region Southeast Asia.
   - Dải IP: `10.0.0.0/16`; tạo subnet: `subnet-db` (10.0.1.0/24), `subnet-functions` (10.0.2.0/24), `subnet-app` (10.0.3.0/24).
2. **Chuyển MySQL sang private**:
   - Portal → `tripto-mysql-db` → **Networking** → đổi **Connectivity method** sang **Private access (VNet)** → chọn `subnet-db`.
   - Kết nối công khai sẽ bị chặn; chỉ app trong VNet gọi được qua IP nội bộ.
3. **Chuyển Storage sang private endpoint**:
   - Storage account → **Networking** → **Private endpoint connections** → **+ Private endpoint** cho blob vào `subnet-functions`.
   - Tắt **Public network access**.
4. **Chuyển Function App vào VNet** (hoặc dùng VNet Integration) để nó gọi được MySQL/Storage private:
   - Function App → **Networking** → **VNet integration** → chọn `vnet-tripto`.
5. **Kiểm tra sau khi chuyển**: web vẫn đọc/ghi DB + upload ảnh; track-visit vẫn tạo blob; không còn ai ngoài VNet truy cập được tài nguyên.

### Kết quả dự kiến khi làm xong

- DB/Storage/Redis **không còn lộ IP public** → giảm rủi ro bị tấn công, đáp ứng khuyến nghị của Azure Advisor.
- Toàn bộ liên lạc nội bộ đi qua mạng riêng Azure (an toàn hơn, độ trễ thấp hơn).

> Lưu ý: chưa triển khai trong repo — nếu giáo viên hỏi, đây là khuyến nghị bảo mật đang chờ thực hiện.

---

## DỊCH VỤ 5 — Event Grid (system topic + subscription `tripto-visit-created`)

### Ý nghĩa — nó là gì

**Azure Event Grid** là dịch vụ **event routing** (định tuyến sự kiện): khi một tài nguyên xảy ra sự kiện (vd: **blob mới được tạo trong Storage**), Event Grid nhận sự kiện đó và **gửi (push) tới các endpoint đăng ký** (vd: Azure Function) gần như **tức thời** — theo mô hình publish/subscribe. Không cần polling, không cần code dò tìm.

Trong dự án: mỗi khi `trackVisit` tạo 1 blob vào container `web-visits`, Event Grid phát hiện `Microsoft.Storage.BlobCreated` → gửi tới Function `BlobEventHandler` → tăng biến đếm trong Redis. Đây là luồng **serverless, tự động hoá**.

### Các bước đã làm

1. **Kích hoạt Event Grid cho Storage Account**: Storage `sttriptobackup` tự có **system topic** — Portal → Storage account → **Events** → bật.
2. **Tạo Event Subscription** `tripto-visit-created` (tên lưu trong `backend/azure-config.ps1:44`):
   - Event types: chỉ chọn **Blob created** (`Microsoft.Storage.BlobCreated`) — các sự kiện khác bỏ qua.
   - Lọc theo subject: chỉ sự kiện có subject chứa `/containers/web-visits/` (xử lý trong code BlobEventHandler).
   - Endpoint type: **Azure Function** → chọn Function App `tripto-function` → trigger `BlobEventHandler`.
3. **Viết handler trong Function** (`backend/function/src/functions/BlobEventHandler.js`):
   - Nhận mảng event từ Event Grid (có thể batch).
   - **Bắt buộc xử lý `SubscriptionValidationEvent`**: Event Grid gửi event validation khi tạo subscription → handler phải trả về `validationCode` để xác nhận endpoint hợp lệ (code dòng 67-79).
   - Với `Microsoft.Storage.BlobCreated`:
     - Lọc `subject.includes('/containers/web-visits/')` — không phải web-visits thì bỏ qua.
     - Kết nối Redis (TLS, port 10000) → `redis.incr('tripto:visits:total')`.
   - Bằng chứng có trong commit `f43b2f8` + `8769b0d` ("Event Grid").

### Kết quả đạt được

- Mỗi lượt truy cập trang chủ → blob JSON vào `web-visits/` → Event Grid đẩy sự kiện về Function chỉ trong vài giây → Redis `tripto:visits:total` tăng đúng 1.
- Endpoint validation thành công (nếu không, Event Grid sẽ báo subscription Delivery failed ngay lúc tạo).
- Hệ thống "đếm lượt truy cập" **không cần DB**, nhẹ và realtime.

### Cách cấu hình sau (hướng dẫn duy trì)

- **Xem lại subscription**: Portal → Storage account → **Events** → chọn `tripto-visit-created` → xem **Delivery** (message logs, dead-letter).
- **Test thủ công**: upload 1 file bất kỳ vào container `web-visits` → xem Function log "EVENT GRID EVENT RECEIVED" và Redis counter tăng.
- **Đổi endpoint**: sửa subscription → chọn endpoint khác (vd Function khác).
- **Theo dõi lỗi gửi**: Portal → subscription → **Delivery** → nếu fail nhiều, kiểm tra dead-letter / log Function.

---

## DỊCH VỤ 6 — Azure Function App `tripto-function`

### Ý nghĩa — nó là gì

**Azure Functions** là nền tảng **serverless**: viết code (đây là **Node.js**) và Azure tự chạy khi có "trigger" (HTTP, Event Grid, Timer, Queue…), **tự scale**, **chỉ trả tiền khi chạy**. Function App = nơi chứa nhiều function.

- App: `tripto-function` (URL: `https://tripto-function-gmcahcf6embwemaw.southeastasia-01.azurewebsites.net`).
- Deploy: **ZipDeploy / Run-From-Zip** (bằng chứng `tripto-function-logs/deployments/latest.json` — Status Success).
- Runtime: Node.js, `@azure/functions` v4, Extension Bundle 4.x (`host.json`).

### Các function đã có (bằng chứng `kudu-src-functions.json` + thư mục `src/functions/`)

| Function | Trigger | Route | Chức năng |
|---|---|---|---|
| `trackVisit` | HTTP POST | `/api/track-visit` | Ghi 1 blob JSON (timestamp, userAgent, referer) vào container `web-visits/` (`BlobEventHandler.js:149-255`) |
| `getVisits` | HTTP GET | `/api/visits` | Đọc tổng lượt truy cập từ Redis `tripto:visits:total` |
| `BlobEventHandler` | **Event Grid** | — | Nhận sự kiện `BlobCreated` → validate → tăng Redis counter (Dịch vụ 5) |
| `negotiate` | HTTP POST | `/api/negotiate` | Trả connection info **Azure SignalR** cho frontend (real-time) |
| `sendNotification` | HTTP POST | `/api/sendNotification` | Gửi thông báo real-time qua SignalR hub `triptoHub` |
| `SendBookingEmail` | HTTP POST | `/api/SendBookingEmail` | Gửi email xác nhận đặt tour qua SMTP/nodemailer (cũng nhận Event Grid validation + BlobCreated) |
| `notificationHub`, `sendNotificationHub`, `registerNotification`, `GetVapidPublicKey`, `notificationHubDebug` | HTTP | — | Push notification (Notification Hubs + Web Push PWA `sw.js`) |

### Các bước đã làm

1. **Tạo Function App** `tripto-function`:
   - Portal → **Function App** → **Create** → Runtime stack **Node.js** (LTS), region Southeast Asia, plan **Consumption** (serverless — rẻ).
2. **Viết code local** trong `backend/function/`:
   - `package.json` cài: `@azure/functions`, `@azure/storage-blob`, `redis`/`ioredis`, `nodemailer`, `mysql2`, `@azure/notification-hubs`.
   - `local.settings.json`: `FUNCTIONS_WORKER_RUNTIME=node`, `AzureWebJobsStorage=UseDevelopmentStorage=true` (test local bằng Azurite).
   - `host.json`: extension bundle `[4.*, 5.0.0)` + Application Insights sampling.
3. **Deploy lên Azure**: zip toàn bộ folder → `func azure functionapp publish tripto-function` (hoặc ZipDeploy qua Kudu). Bằng chứng: `publish-log.txt` + deployment `e7c6e917...` Success (2026-08-09), ProjectType `Run-From-Zip`.
4. **Cấu hình Application Settings trên Function App** (bắt buộc để function chạy đúng):
   - `VISIT_STORAGE_CONNECTION_STRING` — chuỗi kết nối Storage `sttriptobackup` (cho `trackVisit`).
   - `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` — kết nối Redis (cho `BlobEventHandler`, `getVisits`).
   - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM` — gửi email (cho `SendBookingEmail`).
   - `AzureSignalRConnectionString` — kết nối SignalR (cho `negotiate`, `sendNotification`).
5. **Đặt rule CORS**: cho phép origin của web `tripto`/`tripto2` gọi các API HTTP từ trình duyệt.
6. **Tích hợp frontend**:
   - `frontend/user/TRANGCHU.html:1677-1695`: tự gọi `POST /api/track-visit` khi mở trang chủ.
   - `frontend/user/thanhtoan_chitiet.html:1689`: gọi `POST /api/SendBookingEmail` khi đặt tour.
   - `frontend/js/signalr.js`, `frontend/js/push-notification.js`: kết nối SignalR + push notification.

### Kết quả đạt được

- Mỗi lượt mở trang chủ → `trackVisit` tạo blob → Event Grid → Redis tăng counter (luồng end-to-end đã chạy thật).
- `SendBookingEmail` gửi email xác nhận đặt tour thành công (SMTP verify OK trong log).
- `negotiate` + `sendNotification` bật thông báo **real-time** khi có booking mới (SignalR).
- Push notification cho PWA qua Notification Hubs hoạt động.
- Tất cả deployment gần nhất **Success** (deployments `latest.json`), file code xác nhận trên server qua Kudu VFS.

### Cách cấu hình sau (hướng dẫn duy trì)

- **Xem log**: Portal → Function App → **Functions** → chọn function → **Monitor** (hoặc dùng `func azure functionapp logstream tripto-function`).
- **Sửa function & deploy lại**:
  ```powershell
  cd backend/function
  func azure functionapp publish tripto-function --force
  ```
- **Thêm biến môi trường**: Portal → Function App → **Configuration** → **Application settings** → **+ New application setting**.
- **Gọi thử**: mở URL `https://tripto-function-....azurewebsites.net/api/visits` → trả `{"totalVisits": N}`.
- **Giám sát**: bật Application Insights cho Function App để xem request/exception.

---

## TỔNG KẾT TRẠNG THÁI

| # | Dịch vụ | Tài nguyên | Trạng thái |
|---|---------|-----------|------------|
| 1 | MySQL Flexible Server | `tripto-mysql-db` (B1s, 8.4, PITR 7 ngày) | ✅ Web kết nối SSL, backup runbook chạy 02:00 |
| 2 | Storage Account | `sttriptobackup` (Standard_LRS, private) | ✅ Containers `tour-images`, `web-visits`, `mysql-backups` + share `tripto-share` |
| 3 | Azure Cache for Redis | `tripto-redis` (C0 250MB) | ✅ Đếm lượt truy cập + trạng thái online user |
| 4 | Virtual Network | *(chưa triển khai trong repo)* | ⏳ Khuyến nghị của Azure Advisor — hướng dẫn ở Dịch vụ 4 |
| 5 | Event Grid | subscription `tripto-visit-created` | ✅ BlobCreated → Function → Redis |
| 6 | Azure Function | `tripto-function` (Node.js, Consumption) | ✅ trackVisit / getVisits / BlobEventHandler / email / SignalR / push notification |

### Luồng nghiệp vụ chính (đã kiểm chứng)

1. User mở `TRANGCHU.html` → `POST /api/track-visit`.
2. Function tạo blob JSON trong container `web-visits/`.
3. Event Grid nhận `Microsoft.Storage.BlobCreated` → gọi `BlobEventHandler`.
4. Function `INCR` key `tripto:visits:total` trong Redis.
5. `GET /api/visits` trả tổng lượt truy cập realtime.

### Bằng chứng lưu trong repo

- `backend/config.php` (MySQL + Storage config)
- `backend/redis.php`, `backend/RedisClient.php`, `backend/test_predis.php`, `backend/test_redis.php`
- `backend/blob/BlobStorage.php`, `backend/blob/uploadBlob.php`, `backend/blob/testBlob.php`
- `backend/function/` (source + publish-log + kudu logs + deployment logs)
- `scripts/runbook-mysql-backup.ps1`
- `infrastructure/account2/PROGRESS.md` (MySQL 8.4, storage, diagnostic settings, runbook test thành công)
