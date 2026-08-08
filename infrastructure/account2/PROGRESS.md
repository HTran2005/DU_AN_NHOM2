# ACCOUNT 2 — Monitoring & Governance (Máy 4)
## Trạng thái: Hầu hết xong — còn Task A (chờ Dungcute) + kiểm chứng Entra ID trên web

---

## ✅ ĐÃ LÀM XONG

### 1. Azure Monitor + Log Analytics + App Insights
- [x] Resource Group: `rg-tripto-monitoring` — đã deploy
- [x] Log Analytics: `law-tripto`
- [x] Application Insights: `appi-tripto`
- [x] Metric Alerts: `alert-failed-requests`, `alert-slow-response`
- [x] Action Group: `ag-tripto-critical` (email)
- [x] Instrumentation Key đã gắn vào `backend/config.php`
- [x] monitor.php — gửi telemetry qua REST API (không cần Composer)
- [x] user.php — thêm trackEvent cho login, register, booking

### 2. Recovery Services Vault
- [x] Vault: `rsv-tripto` — đã deploy
- [x] Geo-redundancy enabled

### 3. File bridge (frontend → backend)
- [x] `frontend/user.php` → `backend/user.php`
- [x] `frontend/admin.php` → `backend/admin.php`

### 4. Bicep IaC (infrastructure as code)
- [x] `infrastructure/account2/main.bicep`
- [x] `infrastructure/account2/parameters.json`
- [x] `infrastructure/account2/modules/*.bicep` (5 modules)

### 5. CI/CD
- [x] `.github/workflows/deploy-monitoring.yml`

### 6. KQL Queries
- [x] `monitoring/queries/top-slow-requests.kql`
- [x] `monitoring/queries/database-performance.kql`
- [x] `monitoring/queries/security-audit.kql`
- [x] `monitoring/dashboard.json`

### 7. Deployment scripts
- [x] `scripts/deploy-monitoring.ps1`
- [x] `scripts/runbook-mysql-backup.ps1`
- [x] `scripts/runbook-scale-check.ps1`

### 8. Azure Advisor (Portal)
- [x] Đã kiểm tra 5 tab: Cost, Security, Performance, Reliability, Operational Excellence

---

## ✅ ĐÃ LÀM XONG (bổ sung)

### 9. Cost Management
- [x] Budget `budget-500k-vnd` ($20/tháng ≈ 500k VND, grain Monthly)
- [x] Alerts 50% / 80% / 100% → email nggiao01@gmail.com

### 10. Azure Policy
- [x] Policy `policy-storage-encryption` (Storage accounts phải có infrastructure encryption - 4733ea7b)
- [x] Custom policy `custom-nsg-no-internet-admin` (chặn mở port admin 3389/22/5985 ra internet)
- [x] Assigned `policy-nsg-admin-ports`

### 11. Automation Account
- [x] `aa-tripto` (SystemAssigned Managed Identity)
- [x] Runbook `runbook-mysql-backup` [Published] — backup MySQL sang Blob Storage
- [x] Schedule `schedule-daily-backup` (daily 02:00)
- [x] **TEST THÀNH CÔNG 2026-07-31**: Job `faf11d1c` Completed, blob `backup-check-20260731-121925.log` đã lên container `mysql-backups` trong `sttriptobackup`
- [x] RBAC cho Managed Identity: Reader (subscription) + Contributor (rg-tripto-monitoring, DU_AN_NHOM2_RG)

### 12. Defender for Cloud
- [x] Registered provider Microsoft.Security
- [x] 7 plans Standard: VirtualMachines, SqlServers, AppServices, Arm, CloudPosture, Discovery, FoundationalCspm (free trial ~30 ngày)

### 13. Service Health
- [x] Alert `alert-service-health` (activity log) → ag-tripto-critical

### 14. Git Push
- [x] Committed + pushed hết lên https://github.com/HTran2005/DU_AN_NHOM2.git
- [x] Branch main đồng bộ 100% (0 commit chưa push, working tree clean)
- [x] Các file đã lên GitHub main: `PROGRESS.md`, `runbook-mysql-backup.ps1`, `monitor.php`, `config.php`, `main.bicep`, `main.json`, `policies/nsg-no-internet-admin-port.json`, `deploy-monitoring.yml`

### 15. CI/CD Pipeline (GitHub Actions)
- [x] Workflow `deploy-monitoring.yml` hoạt động — **run gần nhất SUCCESS** (run `30631467315`, commit `98c8358`)
- [x] 3 jobs đều pass: Validate Bicep (build + what-if) → Deploy to Azure → Verify Deployment
- [x] Secret `AZURE_CREDENTIALS` đã tạo (service principal `sp-github-actions-tripto`, Contributor trên rg-tripto-monitoring)
- [x] Đã fix 2 lỗi: (1) job validate thiếu bước Azure Login, (2) syntax YAML bị vỡ dòng
- [x] `infrastructure/account2/main.json` (ARM template build từ bicep) đã commit

### 16. Entra ID App Registration (tripto-app)
- [x] Tạo App Registration `tripto-app` 2026-08-02 (clientId `9ecd3cd7-2387-41e0-ad77-c22884b2df9b`)
- [x] Sign-in audience: `AzureADandPersonalMicrosoftAccount`, ID token issuance: bật
- [x] Redirect URI loại **SPA** (đã chuyển từ web sang spa):
  - `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net/frontend/user/TRANGCHU.html`
  - `https://tripto2-e3g2epfdaahzaqaa.southeastasia-01.azurewebsites.net/frontend/user/TRANGCHU.html`
- [x] `frontend/user/msal-config.js` (đã bỏ gitignore 2026-08-02) = clientId + authority `common` + redirectUri TRANGCHU
- [x] **Bỏ qua Dungcute** 2026-08-02: clientId (không phải bí mật) được fallback ngay trong `backend/config.php`, `msal-config.js` được commit lên git → GitHub Actions (`main_tripto.yml`/`main_tripto2.yml`) tự deploy lên web, không cần set env vars hay zip thủ công
- [ ] Kiểm chứng: web → Đăng Nhập → "Tiếp tục với Microsoft" → popup đăng nhập → thành công

### 17. Microsoft Sentinel (SIEM)
- [x] **Bật Microsoft Sentinel** trên `law-tripto` 2026-08-02 (State: Succeeded)
- [x] Solution `SecurityInsights(law-tripto)` trong RG `rg-tripto-monitoring`
- [x] Đã register thêm provider `Microsoft.OperationsManagement` (bắt buộc)
- [x] Lưu ý: onboard qua `Microsoft.SecurityInsights/onboardingStates` api-version `2023-02-01-preview` (cách cũ dùng solutions đã deprecated → lỗi BadGateway)
- [x] Data connector **Azure Activity** (diagnostic setting subscription `ds-activity-to-sentinel`: Administrative/Security/ServiceHealth/Policy) 2026-08-06
- [x] Analytic rule `rule-high-failed-requests` (Scheduled, query trên `AppRequests` phát hiện HTTP 5xx, severity Medium, enabled) 2026-08-06

### 18. Diagnostic Settings → Log Analytics (data cho Sentinel)
- [x] `ds-mysql-to-law`: MySQL `tripto-mysql-db` → law-tripto (MySqlSlowLogs + MySqlAuditLogs + AllMetrics) 2026-08-02
- [x] `ds-storage-to-law`: Storage `sttriptobackup` → law-tripto (Transaction + Capacity metrics) 2026-08-02
- [x] Verify: **AzureMetrics đã về liên tục** (276+ dòng 08/02) → storage metrics stream OK
- [x] Bật `audit_log_enabled=ON`, `slow_query_log=ON`, `long_query_time=1`, `audit_log_events=CONNECTION` trên MySQL 2026-08-06
- [ ] Chờ log MySqlSlowLogs/AuditLogs về (cần chạy query chậm thật + đợi vài phút)

### 19. Azure Advisor
- [x] Dịch vụ tự chạy (provider Microsoft.Advisor Registered)
- [x] Verify 2026-08-02: **25 khuyến nghị** (17 Security + 8 HighAvailability)
- [x] File báo cáo: `monitoring/advisor-service-health-report.md`

### 20. Azure Service Health
- [x] Service health events: 0 (không sự cố — bình thường)
- [x] Resource health `law-tripto`: **Available** ✅ (đã register provider Microsoft.ResourceHealth)
- [x] Alert `alert-resource-health` (category=ResourceHealth) → ag-tripto-critical 2026-08-02
- [x] Đã có sẵn `alert-service-health` (category=ServiceHealth)
- [x] File báo cáo: `monitoring/advisor-service-health-report.md`

---

## 🔄 ĐANG LÀM / CHỜ

### A. Redeploy web có monitoring ✅
- [x] **HẾT BLOCKED (2026-08-05)**: Web `tripto` đã chạy code mới có monitor.php (bằng chứng: 2 event `booking_created` 2026-08-03 15:16 về Log Analytics) — Dungcute đã kết nối Deployment Center.
- [x] **Bug duration format**: ban đầu `monitor.php` gửi `duration="1234.0"` → App Insights trả `400` (yêu cầu TimeSpan `dd.hh:mm:ss.fffffff`) nên `AppRequests` luôn = 0. Đã sửa bằng hàm `monitorMsToTimeSpan()` (monitor.php:60) + cast `responseCode` string. Verify end-to-end: azure `itemsAccepted:1`, AppRequests đã có dòng `DurationMs=1234`, `ResultCode=200`, `Success=True`.
- [x] Sau khi deploy: truy cập web vài lần, rồi kiểm tra Log Analytics có `AppRequests` mới chưa

### B. Sửa email Action Group ✅
- [x] Sửa `infrastructure/account2/parameters.json` → `nggiao01@gmail.com`
- [x] Redeploy main.bicep thành công 2026-08-02 → email Action Group `ag-tripto-critical` = `nggiao01@gmail.com` (đã verify bằng `az monitor action-group show`)

---

---

## 📅 NHẬT KÝ — 2026-08-02 (hôm nay đã làm gì)

### 1. Cập nhật code mới nhất từ git
- [x] Pull bản mới nhất `aaf8662` (Entra ID login + workflow tripto/tripto2 + STEPS_ACCOUNT1.md)

### 2. Sửa email Action Group
- [x] `parameters.json` → `nggiao01@gmail.com`, redeploy `main.bicep` thành công, verify email đã đổi

### 3. Entra ID — Đăng nhập bằng Microsoft (hoàn tất, không cần chờ Dungcute)
- [x] Tạo App Registration `tripto-app` (clientId `9ecd3cd7-2387-41e0-ad77-c22884b2df9b`), SPA redirect URI cho tripto + tripto2
- [x] Tạo `frontend/user/msal-config.js` + bỏ gitignore → commit lên git
- [x] Fallback clientId trong `backend/config.php` (không cần env vars)
- [x] Push `82e4da5` → GitHub Actions deploy lên cả 2 webapp **success**
- [x] Verify: `msal-config.js` có trên web, backend `login_microsoft` phản hồi đúng

### 4. Microsoft Sentinel (SIEM) — dịch vụ mới
- [x] Onboard Sentinel lên `law-tripto` (State: Succeeded), provider `Microsoft.OperationsManagement` đã register
- [x] Kinh nghiệm: dùng `onboardingStates` api-version `2023-02-01-preview` (cách cũ solutions → lỗi BadGateway)

### 5. Diagnostic Settings → Log Analytics (data cho Sentinel)
- [x] `ds-mysql-to-law` (MySQL) + `ds-storage-to-law` (Storage) → law-tripto
- [x] Verify: **AzureMetrics về liên tục** (276+ dòng) → storage metrics stream OK

### 6. Azure Advisor — dịch vụ mới (subscription-level)
- [x] Verify: **25 khuyến nghị** (17 Security + 8 HighAvailability)
- [x] Tạo báo cáo `monitoring/advisor-service-health-report.md`

### 7. Azure Service Health — dịch vụ mới (subscription-level)
- [x] Resource health `law-tripto` = **Available**, register provider `Microsoft.ResourceHealth`
- [x] Tạo alert `alert-resource-health` (category=ResourceHealth) → ag-tripto-critical

### 8. Commit + push
- [x] `82e4da5`: Entra ID + email Action Group + msal-config + fallback backend
- [x] `34d6869`: PROGRESS.md + báo cáo Advisor/Service Health
- [x] Branch main đồng bộ 100%

### Kết quả: tổng cộng **12 dịch vụ chính thức** cho Account 2 (xem mục 1–20 phía trên)

---

## ⚠️ LƯU Ý KHI CHẠY SAU

### Đã fix / kinh nghiệm
- **`Microsoft.Storage` chưa register** → lỗi "SubscriptionNotFound" khi tạo storage. Đã register ✅
- **Module Automation Account**: KHÔNG update lên bản mới (Az.Storage 9.7.1 + Az.Accounts 5.5.1 gây xung đột DLL "Method not found Azure.Core"). Giữ bộ gốc: Az.Accounts 2.15.0 + Az.Storage 6.1.0 + Az.MySql 1.1.1 + Az.Resources 6.13.0
- **`mysqldump` không tồn tại** trong sandbox Automation → runbook dùng log-check + dựa vào built-in PITR 7 ngày của MySQL Flexible Server
- **Managed Identity cần `Set-AzContext -SubscriptionId`** sau `Connect-AzAccount -Identity` mới thấy subscription
- **RBAC cần thời gian propagate** (5-10 phút) sau khi cấp role mới
- **`az backup`** container name phải đúng format: `StorageContainer;storage;<rg>;<account>`; item name: `AzureFileShare;<hex id>`; retain-until ≥ 1 ngày sau
- **Storage blob list cần role** "Storage Blob Data Reader" cho user (đã cấp cho `c5cc23c6-...`)
- **App Insights `duration` format**: trường `duration` của `RequestData` bắt buộc dạng TimeSpan `dd.hh:mm:ss.fffffff`, KHÔNG phải số ms thô → gửi `"1234.0"` bị trả `400` và bỏ toàn bộ envelope. Đã sửa monitor.php bằng `monitorMsToTimeSpan()` (2026-08-05)

### 📅 NHẬT KÝ — 2026-08-06 (fix "tạo nhưng chưa dùng" + cải thiện)
- [x] Thêm `monitorTrackDependency()` trong `backend/monitor.php` → bảng `dependencies` giờ có thể có dữ liệu (trước đó rỗng vì chưa có hàm gửi DependencyData). Schema đúng `RemoteDependencyData`.
- [x] Thêm helper `monitorTrackDbQuery()` trong `backend/config.php` để gói gọn việc track 1 query MySQL (type=SQL) → dùng chung với `database-performance.kql`.
- [x] Xoá `monitoring/alerts.json` (file mẫu alert CPU trỏ VM không tồn tại trong project → gây hiểu nhầm). Alert thật nằm ở `modules/alerts.bicep`.
- [x] Xác nhận lại Recovery Services Vault `rsv-tripto`: **KHÔNG trống** — backup file share `tripto-share` (policy `policy-tripto-afs`, Daily 02:00, giữ 30 ngày) đã chạy Completed liên tục từ 31/07/2026.
- [x] Bật MySQL `audit_log_enabled=ON`, `slow_query_log=ON`, `long_query_time=1`, `audit_log_events=CONNECTION` 2026-08-06 (chờ log chảy).
- [x] Sentinel: gắn data connector Azure Activity (`ds-activity-to-sentinel`) + tạo analytic rule `rule-high-failed-requests` 2026-08-06.

### 📅 NHẬT KÝ — 2026-08-05 (kiểm tra Task A + fix AppRequests)
- [x] Xác nhận Task A đã xong: web tripto chạy code mới (event booking_created về Law), DIAGNOSTIC streaming tốt (AzureMetrics 204.718 dòng)
- [x] Phát hiện bug: `AppRequests` = 0 dù metric alert + events hoạt động
- [x] Root cause: `monitor.php` gửi `duration` sai định dạng (ms thô thay vì TimeSpan) → RequestData bị App Insights từ chối 400
- [x] Fix: thêm `monitorMsToTimeSpan()` (monitor.php:60), cast `responseCode` → string, verify thật qua endpoint (itemsAccepted:1 + 2 dòng AppRequests trong Log Analytics)
- [x] Commit fix + push → GitHub Actions deploy lên web tripto/tripto2
- [ ] (chờ) Kiểm chứng AppRequests có dòng từ web thật sau khi deploy

### Tài nguyên chính
- Subscription: `42e7a0ff-6e78-4530-a021-bf133c012ba2` (Azure for Students, currency USD, $20 ≈ 500k VND)
- Tenant: `27089f51-910a-4704-8f1d-47c335d11e1c`, user: `nggiao01@gmail.com`
- MySQL Flexible Server `tripto-mysql-db` (8.4, PITR 7 ngày) nằm ở `DU_AN_NHOM2_RG` (trong sub của mình)
- Storage `sttriptobackup` (tạo backup logs + file share `tripto-share`)
- Automation Managed Identity principalId: `7203b57b-888b-4bdf-963d-85caa992abda`
