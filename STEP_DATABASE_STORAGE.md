# STEP_DATABASE_STORAGE — Kiểm tra & Hướng dẫn triển khai Database & Storage (Nhóm 2 — TripTo)

> **Phạm vi:** 5 dịch vụ **Database & Storage** của website TripTo:
> 1. Azure Database for MySQL – Flexible Server (`tripto-mysql-db`, tier **B1s**)
> 2. Azure Storage Account (`sttriptobackup`)
> 3. Azure Cache for Redis (`tripto-redis`, SKU **C0**) — **tổng hợp YÊU THÍCH** (write-back) + counter lượt truy cập + online user
> 4. Azure Event Grid (system topic + subscription `tripto-visit-created`) — **ĐẾM LƯỢT TRUY CẬP**
> 5. Backup Vault / Recovery Services Vault (`rsv-tripto`)
>
> Mỗi dịch vụ viết đủ **8 mục theo khung chuẩn báo cáo** (khớp `docs/CAU_TRUC_BAO_CAO.md` mục 3.0):
> 1. Ý nghĩa của dịch vụ
> 2. Vai trò trong hệ thống
> 3. Các bước tạo trên Azure
> 4. Cấu hình sau khi tạo
> 5. Tích hợp vào code
> 6. Cách kiểm thử thực tế
> 7. Kết quả đạt được & trạng thái
> 8. Chi phí & lưu ý phản biện
>
> **Nguồn dữ liệu (chỉ dùng bằng chứng có thật trong repo):** `backend/config.php`, `backend/.env.example`,
> `backend/redis.php`, `backend/RedisClient.php`, `backend/blob/BlobStorage.php`, `backend/function/src/functions/*.js`,
> `scripts/runbook-mysql-backup.ps1`, `infrastructure/account2/PROGRESS.md`, `infrastructure/account2/modules/recovery-vault.bicep`,
> `docs/STEPS_DATABASE_STORAGE.md`, lịch sử git.
>
> **Quy ước trạng thái:** ✅ đã hoạt động end-to-end có bằng chứng · ⚠️ một phần / chờ kiểm chứng · ❌ chưa đủ bằng chứng.

---

## KIẾN TRÚC TỔNG THỂ (Database & Storage)

```
Trình duyệt (frontend/user/TRANGCHU.html)
   │  POST /api/track-visit (mỗi lần mở trang chủ)
   ▼
[FUNCTION APP: tripto-function]
   │ trackVisit
   ▼
[STORAGE ACCOUNT: sttriptobackup]  (Standard_LRS, private)
   ├── container `tour-images/`   ← ảnh tour (BlobStorage.php)
   ├── container `web-visits/`    ← blob JSON mỗi lượt truy cập
   ├── container `mysql-backups/` ← log backup (runbook 02:00)
   └── file share `tripto-share`  ← backup qua vault
          │  Microsoft.Storage.BlobCreated
          ▼
   [EVENT GRID: tripto-visit-created]  ──► đếm lượt truy cập
          │  đẩy sự kiện blob mới (web-visits/)
          ▼
   [FUNCTION: BlobEventHandler] ──►  [REDIS: tripto-redis C0]
                                      • key `tripto:visits:total` (INCR) — do Event Grid kích hoạt
                                      • key `tripto:favorite:user:{id}` — tổng hợp YÊU THÍCH (SADD/SREM/SISMEMBER/SCARD)
                                      • key `online:user:{id}` — trạng thái online (setex 60s)
   │
   ▼
[AZURE DATABASE FOR MYSQL FLEXIBLE SERVER: tripto-mysql-db (B1s, 8.4)]
   │  DB `tripto_db` = SOURCE OF TRUTH (tour, user, booking, yeu_thich...)
   │  user `nhom2`, SSL bắt buộc, PITR 7 ngày, log audit/slow
   ▼
[STORAGE ACCOUNT] ──► [RECOVERY SERVICES VAULT: rsv-tripto (Backup Vault)]
                        Backup file share `tripto-share` daily 02:00, giữ 30 ngày, GeoRedundant
```

**Phân vai chính xác giữa Redis và Event Grid:**
- **Event Grid** = dịch vụ **ĐẾM LƯỢT TRUY CẬP** (visit counter): bắt sự kiện blob mới trong `web-visits/` → gọi Function
  `BlobEventHandler` → tăng `tripto:visits:total` trong Redis.
- **Redis (C0)** = dịch vụ **TỔNG HỢP YÊU THÍCH (favorites)**: mọi thao tác ❤️ thêm/xoá/số lượng chạy trên Redis SET
  (`SADD`/`SREM`/`SCARD`/`SISMEMBER`) → **write-back** đồng bộ batch về DB `yeu_thich` mỗi `REDIS_FAVORITE_FLUSH_SECONDS`
  giây; ngoài ra còn lưu **counter lượt truy cập** (ghi bởi Function qua Event Grid) và **trạng thái online** user.

---

# 1. AZURE DATABASE FOR MYSQL — FLEXIBLE SERVER `tripto-mysql-db`

## 1.1. Ý nghĩa của dịch vụ

Azure Database for MySQL **Flexible Server** là dịch vụ **DBaaS (Database as a Service)** do Azure quản lý,
nền tảng MySQL mã nguồn mở nhưng Azure lo toàn bộ phần hạ tầng (OS, vá lỗi, update, backup, giám sát).
- Bạn **không quản lý máy chủ/VM**, chỉ quản lý dữ liệu (schema, quyền, query).
- Tier **B1s** = **Burstable** (1 vCore, 2 GB RAM): CPU có thời lượng "tăng tốc" linh hoạt, chi phí thấp nhất,
  phù hợp dự án sinh viên ít tải.
- Version **8.4 (LTS)**, region **Southeast Asia**, backup **PITR 7 ngày** tự động.
- **SSL bắt buộc** — mọi kết nối được mã hoá (bằng chứng `require_secure_transport = ON`, `PROGRESS.md:109`).

## 1.2. Vai trò trong hệ thống

MySQL là **CSDL chính (source of truth)** của TripTo — nơi lưu toàn bộ dữ liệu nghiệp vụ:
- Backend PHP (`backend/*.php`) đọc/ghi: tài khoản, tour, đặt tour (`dat_tour`), đánh giá, yêu thích, thanh toán.
- **Ở giữa hệ thống**: nhận ghi từ backend, cấp dữ liệu trả về API cho frontend.
- Khác biệt với Redis: MySQL chứa **dữ liệu bền vững (source of truth)** — kể cả yêu thích cuối cùng cũng được flush từ Redis về DB; Redis chỉ là **lớp đệm/tổng hợp tạm** (favorite SET, counter, online).
- Backup: dùng **PITR 7 ngày built-in** của chính server (KHÔNG đi qua Backup Vault — Vault chỉ backup file share).

```
Backend PHP ──(mysqli SSL)──► [tripto-mysql-db] ──► App Insights (MySqlSlowLogs/AuditLogs qua Diagnostic Settings)
```

## 1.3. Các bước tạo trên Azure

**Cách 1 — Portal:**
1. Portal (https://portal.azure.com) → đăng nhập subscription `42e7a0ff-6e78-4530-a021-bf133c012ba2` (Azure for Students).
2. Tìm **Azure Database for MySQL** → **Create** → chọn **Flexible Server** → **Create**.
3. Tab **Basics**:
   - Subscription `Azure for Students`; Resource group `DU_AN_NHOM2_RG`.
   - **Server name**: `tripto-mysql-db`; **Region**: `Southeast Asia`; **Version**: `8.4` (LTS).
   - **Workload type**: `Development`.
4. **Compute + storage → Configure server**:
   - Compute tier **Burstable**; size **B1s** (1 vCore / 2 GB RAM).
   - Storage tối thiểu (~20–32 GiB).
   - **Backup retention period = 7 ngày** (PITR). **Save**.
5. **Authentication**: Admin username `nhom2` + password (bảo mật, KHÔNG commit).
6. **Review + create** → **Create** → đợi `Provisioning State = Succeeded`.

**Cách 2 — CLI (tham khảo):**
```powershell
az mysql flexible-server create `
  --resource-group DU_AN_NHOM2_RG --name tripto-mysql-db `
  --location southeastasia --version 8.4 `
  --sku-name B1s --tier Burstable `
  --admin-user nhom2 --admin-password '<password>' `
  --backup-retention-days 7 `
  --storage-size 32 --public-access Enabled
```

## 1.4. Cấu hình sau khi tạo

| Cấu hình | Giá trị | Ghi chú / bằng chứng |
|---|---|---|
| SSL bắt buộc | `require_secure_transport = ON`, `ssl_enforcement = ENABLED` | Server parameters |
| Firewall | Cho phép Azure services + IP máy dev | Networking → Public access |
| Database | `tripto_db` (utf8mb4 / utf8mb4_unicode_ci) | `CREATE DATABASE tripto_db ...` |
| User | `nhom2`@`%`, `GRANT ALL ON tripto_db.*` | |
| Database logs | `audit_log_enabled=ON`, `audit_log_events=CONNECTION`, `slow_query_log=ON`, `long_query_time=1` | `PROGRESS.md:198` |
| Diagnostic Settings | `ds-mysql-to-law` → Log Analytics `law-tripto` (`MySqlSlowLogs`, `MySqlAuditLogs`, `AllMetrics`) | `PROGRESS.md:106` |

Tạo database + cấp quyền:
```sql
CREATE DATABASE IF NOT EXISTS tripto_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER USER 'nhom2'@'%' IDENTIFIED BY '<password>';
GRANT ALL PRIVILEGES ON tripto_db.* TO 'nhom2'@'%';
FLUSH PRIVILEGES;
```
Import schema: `mysql -h tripto-mysql-db.mysql.database.azure.com -u nhom2 -p --ssl-ca=DigiCertGlobalRootCA.crt.pem tripto_db < database/tripto.sql`

## 1.5. Tích hợp vào code

- **`backend/config.php:8-11`** — đọc config từ env, có fallback mặc định (không hardcode password):
  ```php
  define('DB_HOST', getenv('DB_HOST') ?: 'tripto-mysql-db.mysql.database.azure.com');
  define('DB_USER', getenv('DB_USER') ?: 'nhom2');
  define('DB_PASS', getenv('DB_PASS') ?: '');
  define('DB_NAME', getenv('DB_NAME') ?: 'tripto_db');
  ```
- **`backend/config.php:112-135`** — kết nối SSL + **persistent** (`p:`), có tự **ping()/reconnect** khi connection cũ:
  ```php
  $conn = mysqli_init();
  mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);
  $conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
  $conn->real_connect('p:' . DB_HOST, DB_USER, DB_PASS, DB_NAME, 3306, NULL, MYSQLI_CLIENT_SSL);
  if (!$conn->ping()) { /* close + reconnect */ }
  ```
- **`monitorTrackDbQuery()`** (`config.php:169-171`) gói query gửi telemetry lên App Insights (bảng `dependencies`).

## 1.6. Cách kiểm thử thực tế

1. Kết nối CLI thử (cần CA cert DigiCert):
   ```powershell
   mysql -h tripto-mysql-db.mysql.database.azure.com -u nhom2 -p --ssl-ca=DigiCertGlobalRootCA.crt.pem tripto_db
   ```
2. Test qua web: đăng nhập, thêm tour, đặt tour trên `frontend/` → kiểm tra dữ liệu ghi vào `tripto_db`.
3. Verify SQL logs về Log Analytics: chạy 1 query chậm → truy vấn bảng `MySQLSlowLogs` trong `law-tripto`.
4. Kiểm tra backup: Portal → server → **Server backups** → thấy backup hàng ngày, có tính năng **Restore** (chọn điểm thời gian).

## 1.7. Kết quả đạt được & trạng thái

- ✅ Web `tripto`/`tripto2` kết nối `tripto_db` thành công, đọc/ghi nghiệp vụ bình thường (bằng chứng `config.php` + data thật trên web).
- ✅ Mọi kết nối qua SSL (`require_secure_transport` không còn lỗi).
- ✅ Backup tự động **PITR 7 ngày** + log audit/slow về Log Analytics (`ds-mysql-to-law`).
- ✅ Runbook `runbook-mysql-backup` test thành công (job `faf11d1c` Completed, blob `backup-check-*.log` lên container `mysql-backups` — `PROGRESS.md:65`).
- ✅ Diagnostic + App Insights `dependencies` loại `SQL` hoạt động (`PROGRESS.md:175,194-195`).
- ⚠️ Log `MySqlSlowLogs` cần query chậm thật mới thấy dòng (`PROGRESS.md:110` — chờ).

## 1.8. Chi phí & lưu ý phản biện

- **Chi phí ước tính (cần xác nhận lại bằng Azure Pricing Calculator tại thời điểm viết):**
  - B1s Burstable Southeast Asia ≈ **$5–10/tháng** tuỳ giờ bật + storage ~ $0.115/GiB/tháng (32 GiB ≈ $3.7).
  - Dùng **Azure for Students** miễn phí credit $100 → trong ngân sách budget `$20/tháng` (`budget-500k-vnd`, `PROGRESS.md:53`).
- **Lưu ý phản biện (trả lời giảng viên):**
  - *"Vì sao không dùng MySQL Community tự cài trên VM?"* → B1s managed không tốn công quản trị/backup, có PITR + SSL mặc định; VM tự cài sẽ ngốn thời gian + rủi ro bảo mật.
  - *"B1s có đủ không?"* → Burstable phù hợp tải thấp; khi tải tăng có thể nâng B2s mà không đổi dữ liệu.
  - *"Public access có an toàn không?"* → Đã giới hạn firewall + SSL bắt buộc; khuyến nghị sau này chuyển **Private access (VNet)** (`docs/STEPS_DATABASE_STORAGE.md` Dịch vụ 4).
  - *"Backup thế nào?"* → PITR 7 ngày built-in; runbook tự động ghi log xác nhận hằng ngày.

---

# 2. AZURE STORAGE ACCOUNT `sttriptobackup`

## 2.1. Ý nghĩa của dịch vụ

Azure **Storage Account** là dịch vụ lưu trữ **phi cấu trúc** do Azure quản lý: lưu **Blob** (file/đối tượng),
**File Share** (chia sẻ file qua SMB/NFS), Queue, Table. Trong dự án dùng hai loại:
- **Blob Storage**: ảnh tour, blob theo dõi lượt truy cập, log backup.
- **File Share**: `tripto-share` phục vụ mục tiêu **backup bằng Backup Vault**.

## 2.2. Vai trò trong hệ thống

- **Nơi lưu ảnh tour**: admin upload ảnh → `BlobStorage.php` PUT lên container `tour-images` → URL blob lưu vào MySQL, frontend hiển thị.
- **Nguồn sự kiện của Event Grid**: mỗi blob mới vào `web-visits` → Event Grid bắn `Microsoft.Storage.BlobCreated` → Function tăng Redis.
- **Kho log backup**: runbook upload `backup-check-*.log` vào container `mysql-backups` mỗi ngày.
- **Nguồn dữ liệu backup**: file share `tripto-share` được Backup Vault `rsv-tripto` sao lưu hằng ngày.

## 2.3. Các bước tạo trên Azure

**Portal:**
1. Portal → tìm **Storage accounts** → **+ Create**.
2. Subscription `Azure for Students`; RG `DU_AN_NHOM2_RG`.
3. **Name**: `sttriptobackup` (tên toàn cầu duy nhất, chữ thường).
4. **Region**: `Southeast Asia`; **Performance**: `Standard`; **Redundancy**: `Locally-redundant storage (LRS)`.
5. Tab **Advanced**: tắt **Allow enabling anonymous access on individual containers** (`AllowBlobPublicAccess $false`).
6. **Review + create** → **Create**.

**CLI (khớp `scripts/runbook-mysql-backup.ps1:49-55`):**
```powershell
New-AzStorageAccount -ResourceGroupName DU_AN_NHOM2_RG -Name sttriptobackup `
  -Location southeastasia -SkuName Standard_LRS -AllowBlobPublicAccess $false
```
> Kinh nghiệm: lỗi `SubscriptionNotFound` do provider `Microsoft.Storage` chưa register → phải register trước (`PROGRESS.md:184`).

**Tạo container:**
```powershell
New-AzStorageContainer -Name tour-images -Context $ctx -Permission Off
New-AzStorageContainer -Name web-visits  -Context $ctx -Permission Off
New-AzStorageContainer -Name mysql-backups -Context $ctx -Permission Off
```

## 2.4. Cấu hình sau khi tạo

| Cấu hình | Giá trị |
|---|---|
| Containers | `tour-images`, `web-visits`, `mysql-backups` (đều Private/Off) |
| File share | `tripto-share` (quota vd 100 GiB) |
| Kết nối | Connection string + Account key (Access keys), đặt env trên App Service |
| Public access | Tắt toàn bộ (`AllowBlobPublicAccess $false`) |
| Diagnostic Settings | `ds-storage-to-law` → `law-tripto` (`Transaction`, `Capacity` metrics) — `PROGRESS.md:107` |

Env vars đặt trên App Service: `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_CONTAINER`, `AZURE_STORAGE_CONNECTION_STRING`, `AZURE_STORAGE_ACCOUNT_KEY`.

## 2.5. Tích hợp vào code

- **`backend/config.php:14-17`** — đọc env storage:
  ```php
  define('AZURE_STORAGE_ACCOUNT', getenv('AZURE_STORAGE_ACCOUNT') ?: '');
  define('AZURE_STORAGE_CONTAINER', getenv('AZURE_STORAGE_CONTAINER') ?: 'tour-images');
  define('AZURE_STORAGE_CONNECTION_STRING', getenv('AZURE_STORAGE_CONNECTION_STRING') ?: '');
  define('AZURE_STORAGE_ACCOUNT_KEY', getenv('AZURE_STORAGE_ACCOUNT_KEY') ?: '');
  ```
- **`backend/blob/BlobStorage.php`** — tự xây **SharedKey authorization** (StringToSign → HMAC-SHA256 → `SharedKey` header), gọi REST API Blob:
  - `upload()` / `uploadFromData()` — PUT BlockBlob (`x-ms-blob-type`, `x-ms-version: 2020-10-02`, curl).
  - `delete()` — DELETE blob (chấp nhận 202/404).
  - `getUrl()` — trả `https://<account>.blob.core.windows.net/<container>/<blob>`.
- **`backend/admin.php`** — `addTour()`/`updateTour()` upload ảnh lên `tour-images`, lưu URL vào `tripto_db`; xoá ảnh cũ khi đổi ảnh.
- **Function `trackVisit`** (`BlobEventHandler.js:186-292`) — dùng `@azure/storage-blob` `BlobServiceClient` upload JSON vào `web-visits` khi có lượt truy cập.
- **Runbook** (`scripts/runbook-mysql-backup.ps1`) — `Set-AzStorageBlobContent` upload log backup + dọn log cũ hơn 14 ngày (retention).

## 2.6. Cách kiểm thử thực tế

1. **Upload ảnh qua admin** → mở URL blob trả về xem ảnh hiển thị trên frontend (container private nhưng web có quyền/role).
2. **Track-visit**: mở `TRANGCHU.html` → vào Storage → container `web-visits` → thấy blob JSON mới.
3. **Test local**: dùng **Azurite** (emulator) — repo có `__azurite_db_blob__.json`, `__azurite_db_queue__.json`;
   script `backend/blob/testBlob.php` + `uploadBlob.php`.
4. **Runbook**: chạy `runbook-mysql-backup` → mở container `mysql-backups` → thấy `backup-check-*.log`.
5. **Metrics**: truy vấn Log Analytics `AzureMetrics` (đã verify 276+ dòng 08/02 — `PROGRESS.md:108`).

## 2.7. Kết quả đạt được & trạng thái

- ✅ Upload ảnh tour qua admin thành công → ảnh trên Azure, URL blob về frontend.
- ✅ Track-visit tạo blob JSON mỗi lần mở trang chủ (`web-visits/`).
- ✅ Runbook upload log backup vào `mysql-backups/` hằng ngày (`backup-check-*.log` thật trên Azure).
- ✅ Metrics `AzureMetrics` stream về Log Analytics liên tục.
- ⚠️ Hiển thị ảnh công khai đang phụ thuộc quyền web đọc container (private); nếu cần hiển thị public phải cấp role **Storage Blob Data Reader** hoặc bật public level Blob.

## 2.8. Chi phí & lưu ý phản biện

- **Chi phí ước tính:** Standard_LRS Southeast Asia ≈ **$0.0452/GiB/tháng** (blob hot); dung lượng dự án nhỏ (vài GB) → **chỉ vài cent–$1/tháng**. File share + backup tính thêm nhỏ.
- **Lưu ý phản biện:**
  - *"Vì sao không lưu ảnh ngay trong MySQL?"* → Blob rẻ hơn, không phình DB, đọc nhanh qua CDN/URL; MySQL chỉ lưu URL.
  - *"Container private mà web vẫn hiển thị ảnh?"* → nhờ cấu hình quyền đọc (role) cho web hoặc qua SAS; đã chọn private để bảo mật (không mở public anonymous).
  - *"LRS có đủ không?"* → LRS rẻ nhất, đủ cho đồ án; khi cần HA/geo có thể nâng GRS/ZRS (tốn thêm).
  - *"Azure Advisor khuyến nghị gì?"* → hạn chế truy cập mạng bằng **VNet / private endpoint** (`monitoring/advisor-service-health-report.md:28`) — là bước nâng cấp nên làm sau.

---

# 3. AZURE CACHE FOR REDIS `tripto-redis` (C0)

## 3.1. Ý nghĩa của dịch vụ

Azure **Cache for Redis** là dịch vụ **in-memory data store (bộ nhớ dữ liệu trong RAM)** do Azure quản lý.
- **C0** = SKU **Basic nhỏ nhất**: **250 MB**, 1 node (không HA), chi phí thấp — đủ cho dự án sinh viên.
- Dữ liệu đọc/ghi trên RAM → **siêu nhanh**, hỗ trợ đầy đủ cấu trúc dữ liệu Redis (String, **Set**, Hash…).
- Kết nối **TLS bắt buộc** (cổng Azure Redis mặc định **6380**; dự án dùng **10000** theo thông số được cấp), có access key/password.

## 3.2. Vai trò trong hệ thống (VAI TRÒ CHÍNH = TỔNG HỢP YÊU THÍCH)

**Kiến trúc Redis write-back (trích `backend/user.php:3102-3121`):** Azure Cache for Redis là nơi xử lý **TRƯỚC** (write-back),
Database `yeu_thich` vẫn là **SOURCE OF TRUTH** lâu dài.

```
   WRITE : SADD/SREM vào Redis SET ─► đánh dấu dirty ─► FLUSH BATCH về Database
           (giảm INSERT/DELETE DB khi user bấm ❤️ liên tục)
   READ  : SISMEMBER / SCARD đọc từ Redis; SET chưa có → warm từ Database (1 query)
   FALLBACK : Redis lỗi → thao tác trực tiếp xuống DB (website KHÔNG crash)
```

Công việc cụ thể của Redis trong TripTo:
1. **Tổng hợp yêu thích (favorites) — vai trò chính:**
   - Key `tripto:favorite:user:{userId}` = Redis **SET**, member dạng `tour:{id}` / `combo:{id}` (`user.php:3116-3118`).
   - Thêm ❤️ → `SADD`; bỏ ❤️ → `SREM`; đếm → `SCARD`; kiểm tra → `SISMEMBER` (đều có trong `RedisClient.php:144-199`).
   - **Write-back**: khi thay đổi → key `:dirty` (timestamp) → sau `REDIS_FAVORITE_FLUSH_SECONDS` (mặc định 10s,
     `.env.example:14`) `favoriteFlushToDb()` đồng bộ SET Redis về bảng `yeu_thich` bằng `INSERT`/`DELETE` diff (`user.php:3381-3470`).
   - **Cache-read**: `checkFavoriteCached()` đọc từ Redis, cache HIT/MISS có track telemetry (`user.php:3515-3560`).
   - TTL dữ liệu tạm: `REDIS_FAVORITE_TTL` mặc định 600s (`user.php:3123-3126`).
2. **Lưu counter lượt truy cập** `tripto:visits:total` — GIÁ TRỊ do Function `BlobEventHandler` ghi qua sự kiện **Event Grid**
   (chi tiết Dịch vụ 4); Redis chỉ là nơi chứa số đếm realtime.
3. **Trạng thái online/offline user** — heartbeat `setex online:user:{id} 60` (`user.php:1651-1779`).

> **Kết luận phân vai:** Redis **KHÔNG tự đếm lượt truy cập** — nó là nơi **chứa counter** do Event Grid + Function ghi tăng.
> Vai trò nghiệp vụ cốt lõi của Redis là **tổng hợp/tạm lưu yêu thích** và **online status**.

## 3.3. Các bước tạo trên Azure

**Portal:**
1. Portal → tìm **Azure Cache for Redis** → **Create**.
2. Subscription `Azure for Students`; RG `DU_AN_NHOM2_RG`.
3. **DNS name**: `tripto-redis` → host `tripto-redis.southeastasia.redis.azure.net`.
4. **Location**: `Southeast Asia`.
5. **Cache type (SKU/Size)**: `Basic` / `C0 (250 MB)`.
6. **Enable non-TLS access port**: để tắt (chỉ cho TLS).
7. **Review + create** → **Create**.

## 3.4. Cấu hình sau khi tạo

- Vào cache → **Access keys** → lưu **Host name**, **Port (SSL)** và **Primary access key**.
- Env (trên App Service; Function dùng `REDIS_HOST`/`REDIS_PORT`/`REDIS_PASSWORD`):
  ```
  REDIS_HOST=tripto-redis.southeastasia.redis.azure.net
  REDIS_PORT=10000
  REDIS_PASSWORD=<access key>
  REDIS_FAVORITE_TTL=600          # TTL key yêu thích tạm (giây) — `.env.example:9`
  REDIS_FAVORITE_FLUSH_SECONDS=10 # chu kỳ write-back Redis → Database — `.env.example:15`
  ```

## 3.5. Tích hợp vào code

- **`backend/config` tầng kết nối:**
  - `backend/redis.php:8-12` — trả config từ env (`host`, `port` mặc định 10000, `password`).
  - `backend/RedisClient.php` — wrapper: ưu tiên **Predis** (`scheme tls://`, timeout 2s, PING test); fallback **phpredis**;
    helper `setex/exists/get/del/mget` + **bộ SET cho Favorite/Wishlist**: `sadd/srem/scard/sismember/smembers/expire` (`RedisClient.php:136-211`);
    `getRedisClientInstance()` — singleton (`RedisClient.php:215-221`).
- **Tổng hợp yêu thích (`backend/user.php:3102-3709`):**
  - Hàm `getFavoriteTtl()`, `favoriteCacheKey()`, `favoriteItemKey()`, `favoriteParseItem()`.
  - `favoriteEnsureSet()` / `favoriteWarmFromDb()` — warm SET từ DB khi cache MISS.
  - `favoriteAdd()` (SADD), `favoriteRemove()` (SREM), `favoriteCount()` (SCARD), `favoriteIsMember()` (SISMEMBER).
  - `favoriteMarkDirty()` / `favoriteClearDirty()` / `favoriteMaybeFlush()` / `favoriteFlushToDb()` — chu trình write-back.
  - `checkFavoriteCached()` — đọc cache, track `favorite_cache_hit` / `favorite_cache_miss`.
  - `handleToggleFavorite()` — **Redis-first**: nếu Redis khả dụng xử lý SADD/SREM, fallback thẳng DB nếu Redis lỗi (`user.php:3605-3649`).
- **Counter lượt truy cập:** FUNCTION `BlobEventHandler.js:151-153` gọi `redis.incr('tripto:visits:total')`
  (chỉ chạy khi có sự kiện Event Grid BlobCreated).
- **Online user:** `handleOnline()` heartbeat/status/list (`user.php:1654-1780`).

## 3.6. Cách kiểm thử thực tế

1. Test kết nối cơ bản: `backend/test_predis.php`, `backend/test_redis.php`, `backend/test_env.php`.
2. CLI ngoài (TLS):
   ```powershell
   redis-cli -h tripto-redis.southeastasia.redis.azure.net -p 10000 -a <password> --tls PING
   ```
3. **Test yêu thích (vai trò chính):** đăng nhập user → bấm ❤️ trên tour → mở Redis console →
   `SMEMBERS tripto:favorite:user:{userId}` thấy `tour:{id}`; bấm tiếp → chờ ≥ chu kỳ flush (10s) →
   kiểm tra bảng `yeu_thich` trong MySQL có dòng mới (write-back thành công).
4. **Test đếm lượt truy cập:** mở trang chủ nhiều lần → `GET /api/visits` → `totalVisits` tăng đúng số lần.

## 3.7. Kết quả đạt được & trạng thái

- ✅ Kết nối Redis qua TLS thành công (PING / SADD / SREM / SISMEMBER / SCARD hoạt động — wrapper + code có đầy đủ).
- ✅ **Yêu thích chạy Redis-first**: thao tác ❤️ phản hồi nhanh từ Redis, **write-back** đồng bộ batch về bảng `yeu_thich`
  (file `user.php` + `RedisClient.php` + env `REDIS_FAVORITE_TTL/FLUSH_SECONDS`).
- ✅ **Fallback an toàn**: Redis lỗi → thao tác yêu thích chuyển thẳng xuống Database, website không crash.
- ✅ Counter `tripto:visits:total` tăng đúng 1 mỗi blob visit (luồng **Event Grid → Function → Redis** chạy thật).
- ✅ Online/offline user hoạt động dựa trên key `online:user:{id}`.

## 3.8. Chi phí & lưu ý phản biện

- **Chi phí:** C0 Basic + 250 MB — **rẻ / gần như miễn phí** trong gói Azure for Students (xác nhận lại Pricing Calculator).
- **Lưu ý phản biện:**
  - *"Vì sao dùng Redis cho yêu thích thay vì ghi DB ngay?"* → giảm số lần INSERT/DELETE DB khi user bấm ❤️ liên tục
    (write-back batch 10s), phản hồi nhanh; DB vẫn là source of truth, Redis chỉ là tầng đệm — nếu Redis mất dữ liệu,
    DB vẫn giữ bản cuối.
  - *"C0 không HA, mất data nếu restart?"* → đúng; nhưng dữ liệu Redis là **tạm (favorite SET, counter, online)** —
    có thể tái tạo: favorite warm lại từ DB, counter rebuild từ blob `web-visits`. Data bền nằm ở MySQL + Backup Vault.
  - *"Redis có tự đếm lượt truy cập không?"* → **KHÔNG**. Redis chỉ **chứa counter**; việc **đếm** do **Event Grid** điều phối
    (Dịch vụ 4) — tránh báo cáo sai vai trò dịch vụ khi giảng viên hỏi.
  - *"Port 10000 khác mặc định 6380?"* → theo thông số server được cấp; quan trọng là **TLS** (`tls://`) để không lộ dữ liệu.

---

# 4. AZURE EVENT GRID (system topic + subscription `tripto-visit-created`)

## 4.1. Ý nghĩa của dịch vụ

Azure **Event Grid** là dịch vụ **event routing (publish/subscribe)**: khi tài nguyên phát sinh sự kiện
(vd **blob mới tạo trong Storage**) → Event Grid **đẩy (push)** sự kiện tới endpoint đã đăng ký (vd Function)
gần như **tức thời** — **không cần polling**.
- Dùng **system topic** có sẵn của Storage Account (không tạo topic riêng).
- Event chính: `Microsoft.Storage.BlobCreated`.

## 4.2. Vai trò trong hệ thống (VAI TRÒ CHÍNH = ĐẾM LƯỢT TRUY CẬP)

Event Grid là dịch vụ **ĐẾM LƯỢT TRUY CẬP (visit counter)** của hệ thống. Khi mỗi khách truy cập trang chủ:
```
user mở TRANGCHU.html
   ─(POST /api/track-visit)──► Function trackVisit tạo blob JSON trong container web-visits/
                                  │
         [STORAGE] phát sự kiện Microsoft.Storage.BlobCreated ──► [EVENT GRID: tripto-visit-created]
                                                                        │  push
                                                                        ▼
                                              [FUNCTION: BlobEventHandler]──► Redis INCR `tripto:visits:total`
```
→ Mỗi blob mới = 1 lượt truy cập → Event Grid tự động báo cho Function để **tăng counter** — hoàn toàn **serverless**, realtime,
web không phải gọi DB để đếm, không cần code dò tìm blob.

> **Kết luận phân vai:** *"Event Grid đếm lượt truy cập"* — còn Redis chỉ là nơi **chứa kết quả đếm** (counter) mà Event Grid
> + Function ghi tăng. Đây là luồng tự động hoá không có sự tham gia của backend PHP.

## 4.3. Các bước tạo trên Azure

1. Portal → Storage account `sttriptobackup` → menu **Events** → **+ Event Subscription**.
2. **Event subscription name**: `tripto-visit-created`.
3. **Event Schema**: `Event Grid Schema`.
4. **Event types**: chỉ chọn **Blob created** (`Microsoft.Storage.BlobCreated`).
5. **Endpoint type**: `Azure Function` → chọn Function App `tripto-function` → trigger `BlobEventHandler`.
6. Tab **Filters** (tuỳ chọn): subject filter chứa `/containers/web-visits/` (nếu không handler tự lọc).
7. **Create** → Event Grid gửi **SubscriptionValidationEvent** để xác nhận endpoint.

*System topic là nguồn sẵn có: Storage account tự cung cấp topic nội bộ cho Event Grid.*

## 4.4. Cấu hình sau khi tạo

- Subscription `tripto-visit-created` gắn endpoint = Function `BlobEventHandler` (bằng chứng tên lưu trong `backend/azure-config.ps1:44`).
- Chỉ nhận sự kiện **BlobCreated** (tránh nhiễu BlobDeleted...).
- Xử lý **validation** phải trả `validationCode` — nếu không Event Grid báo **Delivery failed** ngay khi tạo.

## 4.5. Tích hợp vào code

**`backend/function/src/functions/BlobEventHandler.js`:**
- Tạo blob lượt truy cập — `trackVisit` (HTTP POST `/api/track-visit`): dùng `BlobServiceClient` upload JSON
  (`{timestamp, userAgent, referer}`) vào container `web-visits/` (`BlobEventHandler.js:186-292`).
- Đăng ký trigger: `app.eventGrid('BlobEventHandler', { handler: ... })`.
- Xử lý batch: `const events = Array.isArray(event) ? event : [event];`
- **Validation bắt buộc** (`BlobEventHandler.js:66-80`):
  ```js
  if (singleEvent.eventType === 'Microsoft.EventGrid.SubscriptionValidationEvent') {
      return { status: 200, jsonBody: { validationResponse: singleEvent.data.validationCode } };
  }
  ```
- Xử lý `Microsoft.Storage.BlobCreated` (`BlobEventHandler.js:83-174`):
  - Lọc subject chứa `/containers/web-visits/` (chỉ đếm đúng container — line 111).
  - **Idempotent** chống duplicate: `redis.set('tripto:visits:processed:'+eventId, '1', { NX: true, EX: 3600 })` (line 136-139).
  - `redis.incr('tripto:visits:total')` (line 151).
- Trả tổng lượt truy cập — `getVisits` (GET `/api/visits`): đọc `tripto:visits:total` trả về `{totalVisits}` (`BlobEventHandler.js:299-338`).

## 4.6. Cách kiểm thử thực tế

1. Mở `TRANGCHU.html` vài lần (hoặc gọi `POST /api/track-visit`) → upload 1 file bất kỳ vào container `web-visits` → chờ vài giây.
2. Xem log Function `BlobEventHandler` → dòng `EVENT GRID EVENT RECEIVED`, `BLOB CREATED`, `REDIS COUNTER UPDATED`.
3. `GET /api/visits` → `totalVisits` tăng đúng số lần.
4. Portal → Storage → **Events** → subscription `tripto-visit-created` → tab **Delivery** xem message log / dead-letter (nếu fail).

## 4.7. Kết quả đạt được & trạng thái

- ✅ Mỗi lượt truy cập trang chủ → blob JSON → **Event Grid đẩy sự kiện** → Function → Redis tăng đúng 1 (vài giây, realtime).
- ✅ Endpoint **validation thành công** (nếu không subscription đã Delivery failed ngay lúc tạo).
- ✅ Hệ thống "đếm lượt truy cập" **không nạp DB**, nhẹ và realtime.
- ✅ Chống duplicate event bằng key idempotent (`BlobEventHandler.js:129-153`).

## 4.8. Chi phí & lưu ý phản biện

- **Chi phí:** Event Grid tính theo **số operation** (~$0.60/1M operation) + số event gửi đi; lượng sự kiện dự án nhỏ → **gần bằng 0/tháng**, thường nằm trong **100k operation miễn phí/tháng** (xác nhận lại Pricing Calculator).
- **Lưu ý phản biện:**
  - *"Vì sao không để Function tự poll blob?"* → Event Grid push tức thời, tiết kiệm compute, không trễ; polling phức tạp + ngốn quota.
  - *"Mất event nếu Function chết?"* → Event Grid có **retry + dead-letter**; chưa cấu hình dead-letter là điểm cần bổ sung nếu giảng viên hỏi.
  - *"Sao chỉ bắt BlobCreated?"* → đúng nhu cầu (chỉ đếm lượt truy cập khi có blob mới); tránh nhiễu sự kiện khác, giảm chi phí.
  - *"Event có bị đếm trùng?"* → đã xử lý idempotent bằng key Redis `NX` 3600s.
  - *"Vai trò cụ thể?"* → Event Grid **chịu trách nhiệm ĐẾM LƯỢT TRUY CẬP** (điều phối sự kiện blob → tăng counter);
    Redis chỉ **lưu counter**; đừng nhầm lẫn hai vai trò khi báo cáo.

---

# 5. BACKUP VAULT — RECOVERY SERVICES VAULT `rsv-tripto`

## 5.1. Ý nghĩa của dịch vụ

**Azure Backup** là dịch vụ **sao lưu do Azure quản lý hoàn toàn**: bạn chỉ định *backup gì – khi nào – giữ bao lâu*,
Azure lo lưu trữ, lịch chạy, khôi phục. Hai khái niệm liên quan:
- **Backup Center**: "một cửa" quản trị tập trung (không tạo tài nguyên mới) — nhìn vault, policy, backup item, job, recovery point cùng màn hình.
- **Recovery Services Vault** `rsv-tripto` (thường gọi **Backup Vault**): nơi **lưu recovery points thật** + chứa **backup policy** (lịch + retention). Tài nguyên `Microsoft.RecoveryServices/vaults`.

Vai trò thực của vault trong dự án: **backup file share `tripto-share`** (Azure Files) — KHÔNG backup MySQL (MySQL dùng PITR built-in riêng). Chế độ lưu **GeoRedundant** (nhân bản sang vùng khác).

## 5.2. Vai trò trong hệ thống

- Bảo vệ dữ liệu **file share** của Storage `sttriptobackup` — khôi phục được file/share nếu bị xoá/tấn công/sự cố.
- Bổ trợ chiến lược backup 3 lớp của hệ thống:
  1. MySQL → **PITR 7 ngày** (Dịch vụ 1).
  2. Runbook → log backup vào blob (Dịch vụ 2).
  3. File share → **vault `rsv-tripto`** daily 02:00, giữ 30 ngày, GeoRedundant (dịch vụ này).

## 5.3. Các bước tạo trên Azure

**Bước 1 — Tạo vault bằng Bicep (IaC)** — `infrastructure/account2/modules/recovery-vault.bicep`:
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
Deploy:
```powershell
az deployment group create --resource-group rg-tripto-monitoring --template-file main.bicep --parameters parameters.json
```

**Bước 2 — Tạo backup policy `policy-tripto-afs`:**
1. Portal → **Backup Center** → **Backup policies** → **+ Add** → loại **Azure Files (Azure Storage)** → chọn vault `rsv-tripto`.
2. **Schedule**: Daily lúc **02:00**; **Retention**: **30 ngày**.

**Bước 3 — Đăng ký backup item (file share `tripto-share`):**
1. **Backup Center** → **+ Backup** → **Datasource type**: `Azure Files (Azure Storage)`.
2. Chọn Storage `sttriptobackup` → file share `tripto-share` → gán policy `policy-tripto-afs` → **Enable backup**.
   - Định danh nội bộ: container `StorageContainer;storage;DU_AN_NHOM2_RG;sttriptobackup`; item `AzureFileShare;<hex id>` (`PROGRESS.md:189`).

**Bước 4 — Test on-demand (đã làm 2026-07-31, commit `d5a3476`):**
- Backup Center → item `tripto-share` → **Backup now** (Retain until ≥ 1 ngày sau — bắt buộc theo API).
- Kết quả: job **Completed**, recovery point `2261472391260650739`, loại **FileSystemConsistent**.

## 5.4. Cấu hình sau khi tạo

| Cấu hình | Giá trị |
|---|---|
| Vault | `rsv-tripto`, SKU Standard, `storageType = GeoRedundant` (Locked) |
| Policy | `policy-tripto-afs` — Azure Files, Daily 02:00, giữ 30 ngày |
| Backup item | `AzureFileShare;<hex>` trên Storage `sttriptobackup`/`tripto-share` |
| Trạng thái | **Protection status: Healthy**, job Completed liên tục 31/07 → 06/08 (`PROGRESS.md:197`) |

## 5.5. Tích hợp vào code

- **IaC**: `infrastructure/account2/modules/recovery-vault.bicep` (vault + backupconfig GeoRedundant) triển khai qua `main.bicep` + CI/CD `.github/workflows/deploy-monitoring.yml`.
- **CLI kiểm tra / vận hành:**
  ```powershell
  az backup vault list -g rg-tripto-monitoring
  az backup item list -v rsv-tripto -g rg-tripto-monitoring --backup-management-type AzureStorage
  az backup job list -v rsv-tripto -g rg-tripto-monitoring --output table
  ```
- Không có code runtime trực tiếp — backup là cấu hình Azure; code liên quan nằm ở IaC + scripts.

## 5.6. Cách kiểm thử thực tế

1. Portal → **Backup Center** → **Backup instances** → item `tripto-share` → xem **Protection status = Healthy**, **Last backup = nhật ký hằng ngày mới nhất**.
2. Xem **Jobs** — tất cả **Completed**; xem **Recovery points** có các điểm hàng ngày.
3. **Test on-demand**: **Backup now** → job Completed → có recovery point mới.
4. **Test khôi phục** (thực hành nếu cần): **Restore** → chọn recovery point → khôi phục nguyên share hoặc từng file → kiểm tra file về đúng.

## 5.7. Kết quả đạt được & trạng thái

- ✅ File share `tripto-share` backup **daily 02:00**, giữ **30 ngày**, **GeoRedundant**.
- ✅ On-demand backup thành công → có recovery point thật (job Completed, `FileSystemConsistent`).
- ✅ Job theo policy **Completed liên tục** từ 31/07 → 06/08, **Protection status: Healthy** (`PROGRESS.md:197`).
- ✅ Vault xuất hiện trong **Backup Center** → chứng minh trực tiếp trên Portal khi bảo vệ đồ án.
- ⚠️ Chưa bật **Cross Region Restore** + **Soft delete** (khuyến nghị của Advisor) — là nâng cấp nên làm sau.

## 5.8. Chi phí & lưu ý phản biện

- **Chi phí ước tính:** Recovery Services Vault tính theo **protected instance** (~$5/tháng) + **dung lượng GRS backup** ($~0.067/GiB/tháng); với file share nhỏ → **vài $/tháng** (xác nhận lại Pricing Calculator). Trong budget `$20/tháng`.
- **Lưu ý phản biện:**
  - *"Vì sao vault backup file share mà không backup MySQL?"* → MySQL Flexible Server **đã có PITR 7 ngày built-in** (backup riêng); vault chịu trách nhiệm dữ liệu **file/phi cấu trúc** — tránh trả phí 2 lần.
  - *"GeoRedundant có tốn không?"* → tốn hơn LRS nhưng an toàn khi cả region chính gặp sự cố — đánh đổi chấp nhận được.
  - *"Nếu giảng viên hỏi Cross Region Restore?"* → trung thực: chưa bật; đây là khuyến nghị của Advisor (`monitoring/advisor-service-health-report.md:32`), là việc nâng cấp sau.
  - *"Backup Center vs Vault khác gì?"* → Backup Center là **lớp tổng hợp quản trị**, không tạo tài nguyên; Vault mới là nơi lưu thật.

---

# TỔNG KẾT TRẠNG THÁI & BẰNG CHỨNG

| # | Dịch vụ | Tài nguyên | Trạng thái | Bằng chứng |
|---|---|---|---|---|
| 1 | MySQL Flexible Server | `tripto-mysql-db` (B1s, 8.4, PITR 7 ngày, SSL) | ✅ Web kết nối SSL, backup runbook 02:00, audit/slow log về LAW | `config.php:8,112-135`, `PROGRESS.md:106,198` |
| 2 | Storage Account | `sttriptobackup` (Standard_LRS, private) | ✅ 3 container + share `tripto-share`, metrics về LAW | `runbook-mysql-backup.ps1`, `BlobStorage.php`, `PROGRESS.md:107` |
| 3 | Azure Cache for Redis | `tripto-redis` (C0 250MB) | ✅ **TỔNG HỢP YÊU THÍCH** (write-back SET) + chứa counter lượt truy cập + online user | `RedisClient.php:136-211`, `user.php:3102-3709`, `BlobEventHandler.js:151` |
| 4 | Event Grid | subscription `tripto-visit-created` | ✅ **ĐẾM LƯỢT TRUY CẬP**: BlobCreated → BlobEventHandler → Redis INCR | `BlobEventHandler.js:51-292` |
| 5 | Backup Vault | `rsv-tripto` (Standard, GeoRedundant) | ✅ Backup `tripto-share` daily 02:00/30 ngày, Healthy | `recovery-vault.bicep`, `PROGRESS.md:197` |

## Kiểm tra nhanh hệ thống Database & Storage khi bảo vệ đồ án

1. `GET /api/visits` → `totalVisits` tăng khi mở trang chủ (chứng minh **Event Grid đếm lượt truy cập**: Storage → Event Grid → Function → Redis).
2. Bấm ❤️ trên tour → `SMEMBERS tripto:favorite:user:{id}` có `tour:{id}`; đợi ~10s → bảng `yeu_thich` trong MySQL có dòng mới (chứng minh **Redis tổng hợp yêu thích + write-back**).
3. Vào Storage `sttriptobackup` → thấy blob `web-visits/` + log `mysql-backups/` + share `tripto-share`.
4. Vào Backend → mở web đăng nhập/đặt tour → dữ liệu trong MySQL `tripto_db` (verify bằng Workbench/CLI).
5. Backup Center → `rsv-tripto` → item `tripto-share` Protection **Healthy**, job **Completed** mỗi ngày.
6. Log Analytics `law-tripto` → bảng `AzureMetrics`, `MySQLSlowLogs`, `AppRequests` có dòng mới.

## Lệnh kiểm thử CLI gợi ý

```powershell
# Storage + blob
az storage account show -g DU_AN_NHOM2_RG -n sttriptobackup
az storage blob list --account-name sttriptobackup --container-name web-visits --auth-mode login

# MySQL
az mysql flexible-server show -g DU_AN_NHOM2_RG -n tripto-mysql-db

# Vault / backup
az backup vault list -g rg-tripto-monitoring
az backup item list -v rsv-tripto -g rg-tripto-monitoring --backup-management-type AzureStorage

# Redis (test kết nối TLS)
redis-cli -h tripto-redis.southeastasia.redis.azure.net -p 10000 -a <password> --tls PING
```