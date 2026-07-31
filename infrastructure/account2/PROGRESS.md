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

## 🔄 ĐANG LÀM / CHỜ

### 9. Cost Management
- [ ] Tạo Budget 500k VND — alert 50%, 80%, 100%

### 10. Azure Policy
- [ ] Gán built-in policy (Storage encryption)
- [ ] Custom policy NSG rules

### 11. Automation Account
- [ ] Tạo Automation Account
- [ ] Import Runbook backup
- [ ] Schedule daily

### 12. Defender for Cloud
- [ ] Enable Defender
- [ ] Regulatory compliance (PCI DSS, ISO 27001)

### 13. Git Push
- [ ] Push code lên GitHub repo: https://github.com/HTran2005/DU_AN_NHOM2.git

---

## ⚠️ LƯU Ý KHI CHẠY SAU
- Backend chưa có DB nên chưa test data App Insights được
- Khi có backend -> pull code -> chạy XAMPP -> data tự động về App Insights
- Azure Subscription: `42e7a0ff-6e78-4530-a021-bf133c012ba2`
