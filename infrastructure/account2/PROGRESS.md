# ACCOUNT 2 — Monitoring & Governance (Máy 4)
## Trạng thái: Hầu hết xong — còn Task A (chờ Dungcute) + fix email Action Group

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

---

## 🔄 ĐANG LÀM / CHỜ

### A. Redeploy web có monitoring
- [ ] **BLOCKED**: Webapp `tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net` thuộc subscription của Dungcute (sub của mình có 0 webapp)
- [ ] Web deploy hiện chạy code cũ (chưa có monitor.php) → App Insights chưa nhận request từ web (Log Analytics chỉ có 2 AppEvents test)
- [ ] **Dungcute cần làm**: Azure Portal → webapp → Deployment Center → kết nối GitHub repo `HTran2005/DU_AN_NHOM2` → branch `main` → Save (tự deploy). Hoặc pull code mới từ GitHub rồi deploy lại.
- [ ] Sau khi deploy: truy cập web vài lần, rồi kiểm tra Log Analytics có `AppRequests` mới chưa

### B. Sửa email Action Group ✅
- [x] Sửa `infrastructure/account2/parameters.json` → `nggiao01@gmail.com`
- [x] Redeploy main.bicep thành công 2026-08-02 → email Action Group `ag-tripto-critical` = `nggiao01@gmail.com` (đã verify bằng `az monitor action-group show`)

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

### Tài nguyên chính
- Subscription: `42e7a0ff-6e78-4530-a021-bf133c012ba2` (Azure for Students, currency USD, $20 ≈ 500k VND)
- Tenant: `27089f51-910a-4704-8f1d-47c335d11e1c`, user: `nggiao01@gmail.com`
- MySQL Flexible Server `tripto-mysql-db` (8.4, PITR 7 ngày) nằm ở `DU_AN_NHOM2_RG` (trong sub của mình)
- Storage `sttriptobackup` (tạo backup logs + file share `tripto-share`)
- Automation Managed Identity principalId: `7203b57b-888b-4bdf-963d-85caa992abda`
