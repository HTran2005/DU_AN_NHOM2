# Các bước đã thực hiện — Database & Storage (Máy 3)

Người thực hiện: `NgocLan (0023411831@student.dthu.edu.vn)`. Resource Group chính: `DU_AN_NHOM2_RG`.
Dựa trên bằng chứng trong repo: `backend/config.php`, `backend/.env.example`, `backend/redis.php`, `backend/blob/*`, `backend/function/*`, `scripts/runbook-mysql-backup.ps1`, `infrastructure/account2/PROGRESS.md`, lịch sử git.

> **Cách đọc file này**: Mỗi DỊCH VỤ gồm 4 phần: (1) **Ý nghĩa** — dịch vụ dùng để làm gì; (2) **Các bước đã làm** — từng thao tác CỤ THỂ từ Portal/CLI/code kèm lệnh và file bằng chứng; (3) **Kết quả đạt được** — điều đã kiểm chứng được; (4) **Cách cấu hình sau** — hướng dẫn duy trì. Muốn làm lại từ đầu, chỉ cần làm theo phần (2) từng bước.

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
   └── file share `tripto-share` ──(bước 7)──►  [RECOVERY SERVICES VAULT: rsv-tripto]
                                                 backup daily 02:00, giữ 30 ngày, geo-redundant
```

---

## DỊCH VỤ 1 — Azure Database for MySQL – Flexible Server `tripto-mysql-db` (B1s)

### Ý nghĩa — nó là gì

Azure Database for MySQL **Flexible Server** là dịch vụ cơ sở dữ liệu MySQL được quản lý hoàn toàn trên Azure:
- Tự động **backup & PITR** (Point-In-Time Restore), đã bật retention **7 ngày** (xác nhận trong `infrastructure/account2/PROGRESS.md:202`).
- Bật **SSL/TLS bắt buộc** cho mọi kết nối (bảo mật dữ liệu truyền qua mạng).
- Tier **B1s** (Burstable — CPU linh hoạt, chi phí thấp, phù hợp sinh viên), region **Southeast Asia**.
- Bạn chỉ quản lý dữ liệu, không phải quản lý máy chủ/OS/backup thủ công.

### Các bước đã làm (chi tiết)

**Bước 1 — Tạo server MySQL Flexible Server trên Portal**

1. Mở https://portal.azure.com và đăng nhập tài khoản (subscription `42e7a0ff-6e78-4530-a021-bf133c012ba2`, Azure for Students).
2. Trên thanh tìm kiếm trên cùng, gõ `Azure Database for MySQL` → chọn **Azure Database for MySQL** → nhấn **Create** → chọn loại **Flexible Server** → **Create**.
3. Trong tab **Basics** điền/đặt:
   - **Subscription**: `Azure for Students`
   - **Resource group**: `DU_AN_NHOM2_RG` (tạo mới nếu chưa có).
   - **Server name**: `tripto-mysql-db`
   - **Region**: `Southeast Asia`
   - **Version**: `8.4` (LTS, ghi trong PROGRESS.md:212).
   - **Workload type**: `Development` (hoặc để mặc định).
4. Trong phần **Compute + storage**, nhấn **Configure server**:
   - **Compute tier**: chọn **Burstable**.
   - **Size**: chọn **B1s** (1 vCore, 2 GB RAM) — rẻ nhất, đủ cho đồ án.
   - **Storage (GiB)**: chọn mức tối thiểu (vd 20–32 GB).
   - **Backup retention period**: đặt **7 ngày** (PITR trong 7 ngày).
   - Nhấn **Save** để quay lại form.
5. Trong phần **Authentication**:
   - Nhập **Admin username**: `nhom2`.
   - Nhập + xác nhận **Password** (bảo mật, không commit vào git).
6. Nhấn **Review + create** → **Create**. Đợi vài phút cho server **Provisioning State = Succeeded**.

**Bước 2 — Bật SSL bắt buộc**

- Vào server `tripto-mysql-db` → menu **Server parameters**.
- Tìm `require_secure_transport` → bật **ON** (bắt buộc mọi kết nối qua SSL/TLS).
- Tìm `ssl_enforcement` → **ENABLED**.
- Nhấn **Save**.
- Tải chứng chỉ CA: https://www.digicert.com/CACerts/DigiCertGlobalRootCA.crt.pem → lưu tên `DigiCertGlobalRootCA.crt.pem` để dùng khi kết nối CLI.

**Bước 3 — Mở firewall cho các IP cần kết nối**

1. Vào server → menu **Networking**.
2. Trong tab **Public access**, bật **Allow public access from any Azure service** (để App Service/Function App trong Azure kết nối được).
3. Nhấn **+ Add current client IP address** để thêm IP máy dev đang dùng (cho phép kết nối CLI/Workbench từ máy).
4. Nhấn **Save**.
   > Lưu ý bảo mật: chỉ giữ IP cần thiết; nếu sau này làm Dịch vụ 4 (VNet) thì chuyển sang **Private access**.

**Bước 4 — Tạo database `tripto_db` và cấp quyền cho user**

Có 2 cách (đã dùng Cloud Shell/Workbench):

- Kết nối bằng mysql client trên máy:
  ```powershell
  mysql -h tripto-mysql-db.mysql.database.azure.com -u nhom2 -p --ssl-ca=DigiCertGlobalRootCA.crt.pem
  ```
- Tạo database + cấp quyền:
  ```sql
  CREATE DATABASE IF NOT EXISTS tripto_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  ALTER USER 'nhom2'@'%' IDENTIFIED BY '<password>';
  GRANT ALL PRIVILEGES ON tripto_db.* TO 'nhom2'@'%';
  FLUSH PRIVILEGES;
  ```
- Import schema từ repo:
  ```powershell
  mysql -h tripto-mysql-db.mysql.database.azure.com -u nhom2 -p --ssl-ca=DigiCertGlobalRootCA.crt.pem tripto_db < database/tripto.sql
  ```
  (Bằng chứng schema trong commits `1b5be69`, `5ef95df`.)

**Bước 5 — Cấu hình kết nối trong code (`backend/config.php:8-11`)**

```php
DB_HOST  = tripto-mysql-db.mysql.database.azure.com
DB_USER  = nhom2
DB_NAME  = tripto_db
DB_PASS  = <từ env / Key Vault>
```

Thứ tự ưu tiên: đọc từ **biến môi trường** trước (`getenv('DB_HOST')`), nếu không có mới dùng giá trị mặc định → không hardcode password trong git.

**Bước 6 — Kết nối SSL + persistent trong `config.php`**

Trong `backend/config.php` (dòng 97–102):
```php
$conn = mysqli_init();
mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);
// 'p:' = persistent connection -> PHP-FPM tái sử dụng connection giữa các request
$conn->real_connect('p:' . DB_HOST, DB_USER, DB_PASS, DB_NAME, 3306, NULL, MYSQLI_CLIENT_SSL);
```
- `mysqli_ssl_set(...)` → kết nối mã hoá bằng SSL.
- `real_connect('p:' . DB_HOST, ..., MYSQLI_CLIENT_SSL)` → dùng **persistent** (`p:`) để tái sử dụng connection → giảm độ trễ bắt tay TCP+TLS mỗi request.
- `set_charset(DB_CHARSET)` với `utf8mb4`.

**Bước 7 — Bật log chậm + audit để giám sát**

Vào server → **Server parameters**, đặt (PROGRESS.md:109, 198):
- `audit_log_enabled = ON`
- `audit_log_events = CONNECTION` (log các phiên kết nối)
- `slow_query_log = ON`
- `long_query_time = 1` (giây)

**Bước 8 — Gắn Diagnostic Setting đẩy log lên Log Analytics**

1. Vào server `tripto-mysql-db` → menu **Diagnostic settings** → **+ Add diagnostic setting**.
2. Tên: `ds-mysql-to-law`.
3. Chọn **Log Analytics workspace** `law-tripto`.
4. Chọn các log/metric: `MySqlSlowLogs`, `MySqlAuditLogs`, `AllMetrics`.
5. **Save**. (Ghi trong PROGRESS.md:105.)

**Bước 9 — Tự động backup hằng ngày bằng runbook**

- Automation Account `aa-tripto` chạy runbook `runbook-mysql-backup` hằng ngày lúc **02:00** (Schedule `schedule-daily-backup`).
- Runbook kiểm tra server sẵn sàng (`Get-AzMySqlFlexibleServer`) + ghi log lên blob (chi tiết ở Dịch vụ 2, Bước 6).
- Bằng chứng: job `faf11d1c` Completed, blob `backup-check-20260731-121925.log` lên container `mysql-backups` (PROGRESS.md:65).

### Kết quả đạt được

- Web (`tripto`, `tripto2`) kết nối `tripto_db` thành công — đọc/ghi dữ liệu tour, tài khoản, đặt tour bình thường.
- Mọi kết nối đều qua SSL (không lỗi `require_secure_transport`).
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

### Các bước đã làm (chi tiết)

**Bước 1 — Tạo Storage Account `sttriptobackup`**

Cách Portal:
1. Portal → tìm `Storage accounts` → **+ Create**.
2. **Subscription**: Azure for Students; **Resource group**: `DU_AN_NHOM2_RG`.
3. **Storage account name**: `sttriptobackup` (tên toàn cầu duy nhất, chỉ chữ thường).
4. **Region**: `Southeast Asia`.
5. **Performance**: `Standard`; **Redundancy**: `Locally-redundant storage (LRS)`.
6. Tab **Advanced**: tắt **Allow enabling anonymous access on individual containers** (`AllowBlobPublicAccess $false`) — bảo mật, không cho ai đọc blob mà không có quyền.
7. **Review + create** → **Create**.

Cách CLI (tương đương lệnh trong `scripts/runbook-mysql-backup.ps1:49-55`):
```powershell
New-AzStorageAccount -ResourceGroupName DU_AN_NHOM2_RG -Name sttriptobackup `
  -Location southeastasia -SkuName Standard_LRS -AllowBlobPublicAccess $false
```
> Lưu ý kinh nghiệm (PROGRESS.md:184): nếu gặp lỗi `SubscriptionNotFound`, phải register provider `Microsoft.Storage` trước.

**Bước 2 — Tạo các container**

Vào Storage account → **Containers** → **+ Container**, tạo 3 container:

| Container | Public access | Mục đích |
|---|---|---|
| `tour-images` | Private (mặc định `config.php:15`) | ảnh tour upload từ admin |
| `web-visits` | Private | blob JSON mỗi lần khách truy cập trang chủ |
| `mysql-backups` | **Off**/private (`runbook-mysql-backup.ps1:72`) | log backup MySQL |

```powershell
New-AzStorageContainer -Name tour-images -Context $ctx -Permission Off
New-AzStorageContainer -Name web-visits  -Context $ctx -Permission Off
New-AzStorageContainer -Name mysql-backups -Context $ctx -Permission Off
```

**Bước 3 — Tạo file share `tripto-share`**

Vào Storage account → **File shares** → **+ File share** → tên `tripto-share` (quota tuỳ ý, vd 100 GiB). Đã tạo trong quá trình test backup (PROGRESS.md:203) và được vault backup ở Dịch vụ 7.

**Bước 4 — Lưu thông tin kết nối (không commit secret)**

1. Vào Storage account → **Access keys** → copy **Connection string** và **key**.
2. Đặt lên App Service (web `tripto`/`tripto2`) qua **Configuration → Application settings**:
   ```
   AZURE_STORAGE_ACCOUNT            = sttriptobackup
   AZURE_STORAGE_CONTAINER          = tour-images
   AZURE_STORAGE_CONNECTION_STRING  = <connection string>
   AZURE_STORAGE_ACCOUNT_KEY        = <key>
   ```
3. `backend/config.php:14-17` đọc các giá trị này bằng `getenv(...)`.

**Bước 5 — Viết class `BlobStorage` tự viết bằng PHP (`backend/blob/BlobStorage.php`)**

Không cài SDK nặng — tự dựng **SharedKey authorization header** (SHA-256 + HMAC) gọi REST API Azure Blob:
- `upload()` — PUT BlockBlob (`x-ms-blob-type: BlockBlob`, `x-ms-date`, `x-ms-version: 2020-10-02`), dùng curl.
- `uploadFromData()` — upload từ chuỗi dữ liệu (dùng file tạm).
- `delete()` — DELETE blob (chấp nhận 202/404).
- `getUrl()` — trả `https://<account>.blob.core.windows.net/<container>/<blob>`.
- `buildAuthorizationHeader()` — xây `StringToSign` (method, content-length, contentType, canonical headers `x-ms-*`, canonicalized resource `/account/container/blob`) → `base64(hmac_sha256(key))` → `SharedKey <account>:<signature>`.

**Bước 6 — Tích hợp upload ảnh tour vào admin (`backend/admin.php`, commit `f43b2f8`)**

1. `addTour()` / `updateTour()` nhận ảnh (file hoặc base64):
   - `sanitizeBlobName()` → đặt tên an toàn (bỏ ký tự đặc biệt, ký tự `/`, v.v.).
   - Gọi `BlobStorage::uploadFromData()` (hoặc `upload()`) lên container `tour-images`.
   - Lưu URL blob vào cột `url_anh_chinh` trong MySQL.
2. Khi đổi ảnh: lấy tên blob cũ bằng `getAzureBlobNameFromUrl()` → gọi `BlobStorage::delete()` để xoá ảnh cũ.
3. `formatTourDataForAPI()` trả thẳng URL blob về frontend.
4. Test local bằng **Azurite** (emulator chạy ngay trên máy): repo có `__azurite_db_blob__.json`, `__azurite_db_queue__.json` → chứng minh đã phát triển/test upload blob cục bộ trước khi lên Azure.

**Bước 7 — Gắn Diagnostic Setting đẩy log lên Log Analytics**

1. Vào Storage account → **Diagnostic settings** → **+ Add diagnostic setting**.
2. Tên: `ds-storage-to-law`.
3. Chọn Log Analytics workspace `law-tripto`.
4. Chọn metrics: `Transaction`, `Capacity`.
5. **Save**. Đã verify: **AzureMetrics về liên tục** (276+ dòng 08/02, PROGRESS.md:107).

### Kết quả đạt được

- Upload ảnh tour qua admin thành công → ảnh lưu trên Azure, URL blob trả về cho frontend.
- Luồng theo dõi lượt truy cập: mỗi lần mở trang chủ → 1 blob JSON vào `web-visits/` (test qua `backend/blob/testBlob.php`).
- Runbook backup MySQL ghi log hằng ngày vào `mysql-backups/` — đã verify blob thật trên Azure (`backup-check-*.log`).
- Storage metrics đã stream về Log Analytics để giám sát.

### Cách cấu hình sau (hướng dẫn duy trì)

- **Upload file bằng tool**: Portal → Storage account → **Containers** → chọn container → **Upload**.
- **Cấp quyền đọc ảnh cho web**: nếu cần hiển thị ảnh công khai → bật **public access level = Blob** cho container `tour-images`, HOẶC cấp role **Storage Blob Data Reader** cho web (khuyến nghị — an toàn hơn).
- **Lấy connection string / key**: Portal → **Access keys** (hoặc `az storage account keys list`).
- **Xoá file cũ**: tự động bởi runbook (retention 14 ngày với log backup), hoặc xoá tay trong container.
- **Giám sát**: xem metric trong Portal → **Monitoring**, hoặc truy vấn Log Analytics bằng `AzureMetrics`.

---

## DỊCH VỤ 3 — Azure Cache for Redis `tripto-redis` (C0)

### Ý nghĩa — nó là gì

Azure **Cache for Redis** là dịch vụ **bộ nhớ đệm trong RAM** (in-memory cache) do Azure quản lý, dựa trên Redis.
- **C0** = tier Basic nhỏ nhất: **250 MB** RAM, 1 node (không HA), chi phí thấp — đủ cho dự án sinh viên.
- Dữ liệu đọc/ghi **siêu nhanh** (không qua đĩa cứng) → phù hợp: đếm lượt truy cập, trạng thái online của user, cache dữ liệu.
- Kết nối bằng **TLS** với access key (password) — cổng mặc định Azure Redis là **6380 (TLS)**, dự án cấu hình port **10000** trong `.env.example`/`redis.php` theo thông số server được cấp.

### Các bước đã làm (chi tiết)

**Bước 1 — Tạo cache**

1. Portal → tìm `Azure Cache for Redis` → **Create**.
2. **Subscription**: Azure for Students; **Resource group**: `DU_AN_NHOM2_RG`.
3. **DNS name**: `tripto-redis` → host tạo ra: `tripto-redis.southeastasia.redis.azure.net`.
4. **Location**: `Southeast Asia`.
5. **Cache type (SKU/Size)**: `Basic` / `C0 (250 MB)`.
6. **Enable non-TLS access port**: để tắt (chỉ cho phép TLS).
7. **Review + create** → **Create**.

**Bước 2 — Lấy thông tin kết nối**

1. Vào cache `tripto-redis` → menu **Access keys** (hoặc **Settings → Access keys**).
2. Copy **Host name**, **Port** (dùng **SSL port** `10000` theo cấu hình được cấp) và **Primary access key**.

**Bước 3 — Cấu hình code**

1. `backend/.env.example:1-6`:
   ```
   REDIS_HOST=tripto-redis.southeastasia.redis.azure.net
   REDIS_PORT=10000
   REDIS_PASSWORD=<access key>
   REDIS_TLS=true
   ```
2. `backend/redis.php:3-7` — trả config đọc từ env, mặc định port `10000`:
   ```php
   return [
       'host' => $_ENV['REDIS_HOST'] ?? '',
       'port' => (int)($_ENV['REDIS_PORT'] ?? 10000),
       'password' => $_ENV['REDIS_PASSWORD'] ?? '',
   ];
   ```
3. `backend/RedisClient.php` — wrapper hỗ trợ **Predis** (composer) hoặc **phpredis** (extension), tự fallback:
   - Thử Predis trước (scheme `tls://`, timeout 2s, PING test).
   - Không có Predis → thử phpredis với prefix `tls://` (`$r->connect('tls://host', port, 2.0)`).
   - Các helper: `setex`, `exists`, `del`, `mget` + `available()` báo trạng thái.
4. Trên App Service (web): đặt 3 biến env `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`.

**Bước 4 — Test kết nối**

- `backend/test_env.php` — kiểm tra env đã load chưa.
- `backend/test_predis.php` — `PING`, `SETEX tripto:test`, `GET tripto:test` qua TLS.
- `backend/test_redis.php` — test qua wrapper `RedisClient`.
- CLI ngoài:
  ```powershell
  redis-cli -h tripto-redis.southeastasia.redis.azure.net -p 10000 -a <password> --tls PING
  ```

**Bước 5 — Tích hợp nghiệp vụ**

1. **Trạng thái online user** (`backend/user.php`): heartbeat cập nhật key `online:<user_id>` + timestamp; endpoint `online_users` đọc danh sách đang online từ Redis (`redis_available` trong JSON response).
2. **Đếm lượt truy cập** (phối hợp Function + Event Grid): key `tripto:visits:total` tăng bằng lệnh `INCR` (xem Dịch vụ 5–6).

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

**Bước 1 — Tạo VNet**

1. Portal → tìm `Virtual networks` → **Create**.
2. **Name**: `vnet-tripto`; **Resource group**: `DU_AN_NHOM2_RG`; **Region**: `Southeast Asia`.
3. **IP addresses**: dải `10.0.0.0/16`.
4. Tạo 3 subnet (tab **Subnets**):
   - `subnet-db` → `10.0.1.0/24`
   - `subnet-functions` → `10.0.2.0/24`
   - `subnet-app` → `10.0.3.0/24`
5. **Review + create** → **Create**.

**Bước 2 — Chuyển MySQL sang private**

- Portal → `tripto-mysql-db` → **Networking** → đổi **Connectivity method** sang **Private access (VNet)** → chọn VNet `vnet-tripto` + subnet `subnet-db`.
- Kết nối công khai sẽ bị chặn; chỉ app trong VNet gọi được qua IP nội bộ.

**Bước 3 — Chuyển Storage sang private endpoint**

- Storage account `sttriptobackup` → **Networking** → **Private endpoint connections** → **+ Private endpoint** cho blob → chọn VNet `vnet-tripto` + subnet `subnet-functions`.
- Tắt **Public network access**.

**Bước 4 — Chuyển Function App vào VNet**

- Function App `tripto-function` → **Networking** → **VNet integration** → chọn `vnet-tripto` để nó gọi được MySQL/Storage private.

**Bước 5 — Kiểm tra sau khi chuyển**

- Web vẫn đọc/ghi DB + upload ảnh; track-visit vẫn tạo blob; không còn ai ngoài VNet truy cập được tài nguyên.

### Kết quả dự kiến khi làm xong

- DB/Storage/Redis **không còn lộ IP public** → giảm rủi ro bị tấn công, đáp ứng khuyến nghị của Azure Advisor.
- Toàn bộ liên lạc nội bộ đi qua mạng riêng Azure (an toàn hơn, độ trễ thấp hơn).

> Lưu ý: chưa triển khai trong repo — nếu giáo viên hỏi, đây là khuyến nghị bảo mật đang chờ thực hiện.

---

## DỊCH VỤ 5 — Event Grid (system topic + subscription `tripto-visit-created`)

### Ý nghĩa — nó là gì

**Azure Event Grid** là dịch vụ **event routing** (định tuyến sự kiện): khi một tài nguyên xảy ra sự kiện (vd: **blob mới được tạo trong Storage**), Event Grid nhận sự kiện đó và **gửi (push) tới các endpoint đăng ký** (vd: Azure Function) gần như **tức thời** — theo mô hình publish/subscribe. Không cần polling, không cần code dò tìm.

Trong dự án: mỗi khi `trackVisit` tạo 1 blob vào container `web-visits`, Event Grid phát hiện `Microsoft.Storage.BlobCreated` → gửi tới Function `BlobEventHandler` → tăng biến đếm trong Redis. Đây là luồng **serverless, tự động hoá**.

### Các bước đã làm (chi tiết)

**Bước 1 — Kích hoạt Event Grid cho Storage Account**

- Storage `sttriptobackup` tự có **system topic** (Storage account tạo sẵn topic nội bộ cho Event Grid).
- Portal → Storage account → menu **Events** → hệ thống hiện sẵn trang tạo event subscription.

**Bước 2 — Tạo Event Subscription `tripto-visit-created`**

1. Portal → Storage account `sttriptobackup` → **Events** → **+ Event Subscription**.
2. **Event subscription name**: `tripto-visit-created` (tên lưu trong `backend/azure-config.ps1:44`).
3. **Event Schema**: `Event Grid Schema`.
4. **Event types**: chỉ chọn **Blob created** (`Microsoft.Storage.BlobCreated`) — bỏ chọn các loại khác (Blob deleted, v.v.).
5. **Endpoint type**: `Azure Function`.
6. **Endpoint**: chọn subscription → Resource group `DU_AN_NHOM2_RG` → Function App `tripto-function` → trigger **`BlobEventHandler`**.
7. **Filter** (tab Filters) — có thể đặt thêm subject filter chứa `/containers/web-visits/` để chỉ nhận sự kiện của container này (nếu không, handler tự lọc trong code).
8. Nhấn **Create**. Lúc này Event Grid gửi **SubscriptionValidationEvent** để xác nhận endpoint.

**Bước 3 — Viết handler trong Function (`backend/function/src/functions/BlobEventHandler.js`)**

1. Đăng ký trigger Event Grid:
   ```js
   app.eventGrid('BlobEventHandler', { handler: async (event, context) => { ... } });
   ```
2. Nhận mảng event (Event Grid có thể gửi batch): `const events = Array.isArray(event) ? event : [event];`
3. **Xử lý validation** (dòng 67–79) — BẮT BUỘC:
   ```js
   if (singleEvent.eventType === 'Microsoft.EventGrid.SubscriptionValidationEvent') {
       return { status: 200, jsonBody: { validationResponse: singleEvent.data.validationCode } };
   }
   ```
   → Nếu không trả `validationCode`, Event Grid báo subscription **Delivery failed** ngay lúc tạo.
4. Với `Microsoft.Storage.BlobCreated`:
   ```js
   if (!subject.includes('/containers/web-visits/')) { continue; }  // lọc đúng container
   const redis = await getRedisClient(context);                    // kết nối Redis TLS port 10000
   const totalVisits = await redis.incr('tripto:visits:total');     // tăng counter
   ```
5. `getRedisClient()` dùng `createClient` từ `redis` (npm) với `socket: { host, port: 10000, tls: true }` + `password`.
6. Bằng chứng có trong commits `f43b2f8` + `8769b0d` ("Event Grid").

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

### Các bước đã làm (chi tiết)

**Bước 1 — Tạo Function App `tripto-function`**

1. Portal → tìm `Function App` → **Create**.
2. **Subscription**: Azure for Students; **Resource group**: `DU_AN_NHOM2_RG`.
3. **Function App name**: `tripto-function`.
4. **Runtime stack**: `Node.js` (LTS); **Version**: 20 (LTS).
5. **Region**: `Southeast Asia`.
6. **Operating System**: `Linux` (hoặc Windows tuỳ chọn).
7. **Hosting plan**: `Consumption (Serverless)` — rẻ, tự scale.
8. **Review + create** → **Create**.

**Bước 2 — Viết code local trong `backend/function/`**

1. `package.json` — các dependency:
   ```json
   "dependencies": {
     "@azure/functions": "^4.0.0",
     "@azure/notification-hubs": "^2.1.0",
     "@azure/storage-blob": "^12.33.0",
     "ioredis": "^6.0.0",
     "mysql2": "^3.5.2",
     "nodemailer": "^9.0.4",
     "redis": "^6.2.0"
   }
   ```
2. `local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "FUNCTIONS_WORKER_RUNTIME": "node",
       "AzureWebJobsStorage": "UseDevelopmentStorage=true"
     }
   }
   ```
   → `UseDevelopmentStorage=true` = dùng **Azurite** khi test local (không cần Azure).
3. `host.json`:
   ```json
   {
     "version": "2.0",
     "logging": { "applicationInsights": { "samplingSettings": { "isEnabled": true, "excludedTypes": "Request" } } },
     "extensionBundle": { "id": "Microsoft.Azure.Functions.ExtensionBundle", "version": "[4.*, 5.0.0)" }
   }
   ```
4. Cài dependencies: `npm install` trong `backend/function`.

**Bước 3 — Deploy lên Azure**

Cách 1 — Core Tools (`func`):
```powershell
cd backend/function
func azure functionapp publish tripto-function
```
Cách 2 — ZipDeploy qua Kudu:
```powershell
Compress-Archive -Path * -DestinationPath app.zip -Force
az webapp deployment source config-zip --resource-group DU_AN_NHOM2_RG --name tripto-function --src app.zip
```
Bằng chứng: `publish-log.txt` + deployment `e7c6e917...` Success (2026-08-09), ProjectType **Run-From-Zip**. Xác nhận code trên server qua Kudu VFS (`kudu-src-functions.json`).

**Bước 4 — Cấu hình Application Settings trên Function App (bắt buộc)**

Vào Function App → **Configuration → Application settings → + New application setting**:

| Tên biến | Giá trị |
|---|---|
| `VISIT_STORAGE_CONNECTION_STRING` | Connection string của `sttriptobackup` (cho `trackVisit`) |
| `REDIS_HOST` | `tripto-redis.southeastasia.redis.azure.net` |
| `REDIS_PORT` | `10000` |
| `REDIS_PASSWORD` | Access key Redis (cho `BlobEventHandler`, `getVisits`) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAIL_FROM` | SMTP để gửi email (`SendBookingEmail`) |
| `AzureSignalRConnectionString` | Connection string SignalR (cho `negotiate`, `sendNotification`) |
| `AzureWebJobsStorage` | Connection string Storage (bắt buộc của runtime Functions) |

Nhấn **Save** → app khởi động lại.

**Bước 5 — Đặt rule CORS**

Function App → **API → CORS** → thêm origin của web:
- `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net`
- `https://tripto2-e3g2epfdaahzaqaa.southeastasia-01.azurewebsites.net`
→ để trình duyệt gọi các API HTTP từ web không bị chặn cross-origin.

**Bước 6 — Tích hợp frontend**

1. `frontend/user/TRANGCHU.html:1677-1695`: tự gọi `POST /api/track-visit` khi mở trang chủ.
2. `frontend/user/thanhtoan_chitiet.html:1689`: gọi `POST /api/SendBookingEmail` khi đặt tour.
3. `frontend/js/signalr.js`, `frontend/js/push-notification.js`: kết nối SignalR + push notification.

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

## DỊCH VỤ 7 — Backup Center + Recovery Services Vault `rsv-tripto` (Backup Vault)

### Ý nghĩa — nó là gì

**Azure Backup** là dịch vụ **sao lưu dữ liệu do Azure quản lý hoàn toàn**: bạn chỉ định nghĩa "backup gì — khi nào — giữ bao lâu", Azure lo phần lưu trữ, lịch chạy, khôi phục. Trong hệ sinh thái này có 2 khái niệm chính:

- **Backup Center**: là **"một cửa" quản trị tập trung** (single pane of glass) cho *toàn bộ* các bản sao lưu trên Azure — nhìn thấy vault, policy, backup item, job chạy, recovery point ở cùng một màn hình. Backup Center **không tạo tài nguyên mới**, nó chỉ là lớp tổng hợp/giao diện để quản lý các **Backup Vault** bên dưới.
- **Recovery Services Vault** `rsv-tripto` (thường gọi chung là **Backup Vault**): là **nơi lưu trữ thật** các bản sao lưu (recovery points) + chứa **backup policy** (lịch + retention). Đây chính là tài nguyên `Microsoft.RecoveryServices/vaults` được deploy trong repo.

Trong dự án, vault được dùng để **backup file share `tripto-share`** (file share nằm trong Storage Account `sttriptobackup`):

- Loại backup: **Azure Files (file share)** — đây là vai trò thực của vault.
- **KHÔNG dùng vault để backup MySQL**: MySQL Flexible Server đã có **built-in PITR 7 ngày** của riêng nó (Dịch vụ 1) nên không đi qua vault này.
- Chế độ lưu backup: **GeoRedundant** — bản sao lưu được nhân bản sang vùng Azure khác → an toàn kể cả khi cả vùng chính gặp sự cố.

### Các bước đã làm (chi tiết)

**Bước 1 — Tạo Recovery Services Vault bằng Bicep (IaC)** — `infrastructure/account2/modules/recovery-vault.bicep`

1. Nội dung module:
   ```bicep
   resource vault 'Microsoft.RecoveryServices/vaults@2022-10-01' = {
     name: vaultName
     location: location
     sku: { name: 'Standard' }
     properties: { publicNetworkAccess: 'Enabled' }
   }
   resource vaultBackupConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2023-01-01' = {
     parent: vault
     name: 'vaultconfig'
     properties: { storageType: 'GeoRedundant', storageTypeState: 'Locked' }
   }
   ```
2. Tham số gắn từ `main.bicep` + `parameters.json`: tên `rsv-tripto`, RG `rg-tripto-monitoring`, region `southeastasia`.
3. Deploy bằng lệnh (ghi chú ngay đầu `main.bicep`):
   ```powershell
   az deployment group create --resource-group rg-tripto-monitoring --template-file main.bicep --parameters parameters.json
   ```

**Bước 2 — Tạo Backup Policy `policy-tripto-afs`** (thao tác trên Backup Center / Portal, ghi trong `PROGRESS.md:197`)

1. Portal → **Backup Center** → **Backup policies** → **+ Add**.
2. Chọn loại: **Azure Files (Azure Storage)**.
3. Chọn vault `rsv-tripto`.
4. **Schedule**: Daily lúc **02:00** — mỗi ngày sao lưu 1 lần.
5. **Retention**: giữ **30 ngày** (instant restore snapshot + daily backup points).
6. Tạo → policy `policy-tripto-afs`.

**Bước 3 — Đăng ký backup item — Azure Files share `tripto-share`** (Task C trong lịch sử commit `d5a3476`)

1. Portal → **Backup Center** → **+ Backup** (hoặc vault `rsv-tripto` → **+ Backup**).
2. **Datasource type**: `Azure Files (Azure Storage)`.
3. Chọn Storage Account `sttriptobackup` (trong RG `DU_AN_NHOM2_RG`).
4. Chọn file share `tripto-share`.
5. Gán policy `policy-tripto-afs`.
6. **Enable backup**.
   - Bằng chứng kỹ thuật (ghi chú `PROGRESS.md:189`): container quản trị nội bộ có dạng `StorageContainer;storage;DU_AN_NHOM2_RG;sttriptobackup`; backup item có dạng `AzureFileShare;<hex id>`.

**Bước 4 — Test backup on-demand (kiểm chứng thật) — 2026-07-31** (commit `d5a3476`)

1. Portal → **Backup Center** → **Backup instances** → item `tripto-share` → **Backup now**.
2. Retain until: chọn ngày ≥ 1 ngày sau thời điểm hiện tại (bắt buộc theo API).
3. Kết quả: job **Completed**, tạo recovery point `2261472391260650739`, loại **FileSystemConsistent**.

**Bước 5 — Xác nhận vault không trống (2026-08-06)** (`PROGRESS.md:197`)

1. Vào vault `rsv-tripto` → **Backup items** → item `tripto-share`.
2. Quan sát: job backup theo policy chạy **Completed liên tục** từ 31/07 → 06/08.
3. **Protection status**: **Healthy**.
4. Xem **Recovery points**: có các điểm khôi phục hàng ngày.

**Bước 6 — Gắn với giám sát**

- Azure Advisor đưa khuyến nghị bật **Cross Region Restore** cho vault (`monitoring/advisor-service-health-report.md:32`) — là việc nâng cấp bảo mật nên làm sau.

### Kết quả đạt được

- File share `tripto-share` được sao lưu **hàng ngày lúc 02:00**, giữ **30 ngày**.
- Backup on-demand thành công → có recovery point thật (khôi phục được toàn bộ nội dung file share về thời điểm đó).
- Bản sao lưu ở chế độ **GeoRedundant** → dữ liệu an toàn kể cả khi vùng chính gặp sự cố.
- Vault hiển thị đầy đủ trong **Backup Center** — chứng minh trực tiếp được trên Portal khi bảo vệ đồ án.

### Cách cấu hình sau (hướng dẫn duy trì)

- **Xem trạng thái**: Portal → **Backup Center** → **Backup instances** → chọn item `tripto-share` → xem Protection status, Jobs, Recovery points.
- **Backup thủ công**: Backup Center → item `tripto-share` → **Backup now** (retain-until phải ≥ 1 ngày sau thời điểm hiện tại).
- **Khôi phục**: Backup Center → item `tripto-share` → **Restore** → chọn recovery point → khôi phục nguyên file share hoặc từng file cụ thể.
- **Sửa policy**: Backup Center → **Backup policies** → `policy-tripto-afs` → đổi lịch / retention.
- **Thêm backup item khác**: Backup Center → **+ Backup** → chọn loại (Azure Files, VM, Database…) → chọn tài nguyên mới.
- **Nâng cấp bảo mật (chưa làm)**: bật **Cross Region Restore** + **Soft delete** cho vault (theo khuyến nghị Azure Advisor).
- **Thao tác bằng CLI**:
  ```powershell
  az backup vault list -g rg-tripto-monitoring
  az backup item list -v rsv-tripto -g rg-tripto-monitoring --backup-management-type AzureStorage
  az backup job list -v rsv-tripto -g rg-tripto-monitoring --output table
  ```

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
| 7 | Backup Center / Backup Vault | `rsv-tripto` (Recovery Services Vault, Standard, GeoRedundant) | ✅ Backup `tripto-share` daily 02:00, giữ 30 ngày, job Completed liên tục, recovery point on-demand |

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
- `infrastructure/account2/modules/recovery-vault.bicep` (Recovery Services Vault + backupconfig GeoRedundant)
- `infrastructure/account2/PROGRESS.md` (MySQL 8.4, storage, diagnostic settings, runbook test thành công, vault backup `tripto-share` Completed)
