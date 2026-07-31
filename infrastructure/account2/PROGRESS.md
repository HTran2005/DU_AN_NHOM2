# ACCOUNT 2 — Monitoring & Governance (Máy 4)
## Trạng thái: Đang triển khai

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
- [x] Committed `cf83fe7` → https://github.com/HTran2005/DU_AN_NHOM2.git

---

## 🔄 ĐANG LÀM / CHỜ

### A. Redeploy web có monitoring
- [ ] **BLOCKED**: Webapp thuộc subscription của Dungcute, không deploy từ account này được
- [ ] Web deploy hiện chạy code cũ (chưa có monitor.php) → App Insights chưa nhận request từ web
- [ ] Cần nhờ Dungcute redeploy từ GitHub (hoặc kiểm tra Deployment Center)

### C. Recovery Services Vault backup
- [x] Vault `rsv-tripto` (Standard, southeastasia)
- [x] Policy `policy-tripto-afs` (daily 02:00, retention 30 ngày)
- [x] Backup item: Azure Files share `tripto-share` (trong `sttriptobackup`)
- [x] **TEST THÀNH CÔNG 2026-07-31**: Backup on-demand Completed → recovery point `2261472391260650739` (FileSystemConsistent)
- [x] Ghi chú: MySQL Flexible Server dùng built-in PITR 7 ngày (không qua vault này); vault bảo vệ Azure Files

---

## ⚠️ LƯU Ý KHI CHẠY SAU
- Đã register resource provider `Microsoft.Storage` (thiếu → lỗi "SubscriptionNotFound" khi tạo storage)
- Runbook backup dùng log check (không dùng mysqldump vì sandbox không có)
- Azure Subscription: `42e7a0ff-6e78-4530-a021-bf133c012ba2`
