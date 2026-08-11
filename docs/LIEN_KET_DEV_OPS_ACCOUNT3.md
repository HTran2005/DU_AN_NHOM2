# 🔗 LIÊN KẾT TOÀN BỘ DỊCH VỤ AZURE LÊN AZURE DEVOPS — ACCOUNT 3 (DevOps & Security)

> **Mục tiêu:** Gom **toàn bộ dịch vụ Azure của 3 account** (Frontend & Backend · Database & Monitoring · DevOps & Security) về **một nơi quản trị duy nhất là Azure DevOps** — org `DuAnNhom2`, project `BAO_CAO` — đồng nhất trên **máy của DevOps** để phục vụ báo cáo đồ án.
>
> **Vai trò Account 3:** Đầu mối **DevOps & Security** — chịu trách nhiệm CI/CD, quản trị pipeline, liên kết dịch vụ và tổng hợp báo cáo.
>
> 🚀 **Muốn thực hiện ngay từng bước một?** Xem bản **RUNBOOK hoàn chỉnh**: `docs/RUNBOOK_HOAN_CHINH_DEV_OPS_ACCOUNT3.md` (kèm script kiểm tra sẵn sàng `infrastructure/account3/preflight-check.ps1`).

---

## 1. Kiến trúc liên kết

```
┌──────────────────────────── AZURE ────────────────────────────┐
│  Account 1 (Frontend & Backend)    App Service, TM, KV,       │
│                                    APIM, SB, SignalR, ACS     │
│  Account 2 (Database & Monitoring) MySQL, Storage, Redis,     │
│                                    LAW, AppInsights, Sentinel │
│  Account 3 (DevOps & Security)     Azure DevOps, CI/CD,       │
│                                    Security governance        │
└──────────────────────────┬──────────────────────────────────┘
                           │ 1 Service Principal (SPN) dùng chung
                           │ + role Reader trên từng subscription
                           ▼
        ┌──────────────────────────────────────┐
        │  AZURE DEVOPS (org: DuAnNhom2)       │
        │  Project: BAO_CAO                    │
        │  ├─ Service Connection: Azure-TripTo │  ← tạo bằng script
        │  └─ Pipeline: azure-pipelines-report │  ← sinh REPORT.md
        └──────────────────────────────────────┘
                           │
                           ▼
        Máy DevOps (Account 3): collect-resources.ps1
        + generate-report.sh → reports/REPORT.md (báo cáo Word)
```

**Nguyên tắc an toàn:** SPN chỉ cấp quyền **Reader** (đủ để đọc tài nguyên, KHÔNG sửa/xoá) — phù hợp mục đích báo cáo, tuân thủ least-privilege.

---

## 2. Thành phần trong repo

| File | Vai trò |
|------|---------|
| `infrastructure/account3/parameters.json` | Cấu hình 3 account: subscription ID, tên, nhãn |
| `infrastructure/account3/create-service-connections.ps1` | Tạo SPN + Service Connection trên Azure DevOps |
| `infrastructure/account3/collect-resources.ps1` | Thu thập tài nguyên local (máy DevOps) |
| `infrastructure/account3/generate-report.sh` | Gộp JSON → `REPORT.md` (dùng chung local + pipeline) |
| `infrastructure/account3/azure-pipelines-report.yml` | Pipeline báo cáo (chế độ Shared - mặc định) |
| `infrastructure/account3/azure-pipelines-report-multi.yml` | Pipeline dự phòng (chế độ PerSubscription - khác tenant) |

---

## 3. Điều kiện cần chuẩn bị

| # | Điều kiện | Ghi chú |
|---|-----------|---------|
| 1 | Tài khoản Azure DevOps có quyền **Project Collection Administrator** (org `DuAnNhom2`) | Để tạo Service Connection |
| 2 | **PAT** Azure DevOps | Scope: `Service Connections (Read & manage)` + `Build (Read & execute)` — tạo tại `User settings → Personal Access Tokens` |
| 3 | Azure CLI (`az`) đã cài trên máy DevOps | `az version` để kiểm tra |
| 4 | Quyền tạo App Registration trong Entra ID | `az ad sp create-for-rbac` yêu cầu quyền này |
| 5 | `jq` + `bash` (Git Bash / WSL) | Chỉ cần nếu chạy báo cáo local; pipeline ubuntu có sẵn |
| 6 | Subscription ID của **cả 3 account** | Lấy từ Azure Portal → Subscription, hoặc Cloud Shell `az account list` |

---

## 4. Bước 1 — Điền `parameters.json`

Mở `infrastructure/account3/parameters.json` và điền `subscriptionId` cho từng account:

```json
{
  "organization": "DuAnNhom2",
  "project": "BAO_CAO",
  "serviceConnectionName": "Azure-TripTo",
  "servicePrincipalName": "sp-tripto-devops-report",
  "accounts": [
    { "key": "ACC1", "name": "ACCOUNT_1", "label": "Frontend & Backend",
      "subscriptionId": "xxxx-...", "subscriptionName": "" },
    { "key": "ACC2", "name": "ACCOUNT_2", "label": "Database & Monitoring",
      "subscriptionId": "42e7a0ff-6e78-4530-a021-bf133c012ba2", "subscriptionName": "" },
    { "key": "ACC3", "name": "ACCOUNT_3", "label": "DevOps & Security",
      "subscriptionId": "xxxx-...", "subscriptionName": "" }
  ]
}
```

> 💡 Account nào chưa có subscription ID thì để trống — script sẽ **bỏ qua** account đó (không lỗi).

---

## 5. Bước 2 — Chạy script tạo Service Connection

Trên máy DevOps (PowerShell):

```powershell
# 1. Đăng nhập Azure (nếu chưa)
az login

# 2. Đăng nhập Azure DevOps CLI (tuỳ chọn, để script đọc PAT từ env)
$env:AZURE_DEVOPS_EXT_PAT = "PASTE_PAT_TAI_DAY"

# 3. Chạy script — chế độ mặc định: Shared (1 SPN + 1 connection cho tất cả)
cd D:\DU_AN_NHOM2
.\infrastructure\account3\create-service-connections.ps1 -Pat "PASTE_PAT_TAI_DAY"
```

Script thực hiện:
1. ✅ Kiểm tra `az` + đăng nhập
2. ✅ Liệt kê các subscription hợp lệ (account nào chưa có ID thì bỏ qua)
3. ✅ Tạo SPN `sp-tripto-devops-report` + cấp **Reader** trên từng subscription
4. ✅ Tạo Service Connection **`Azure-TripTo`** (loại Azure Resource Manager) trong org `DuAnNhom2` / project `BAO_CAO`
5. 📄 In danh sách kết quả

### ⚠️ Khi nào dùng chế độ PerSubscription?

Nếu các account nằm ở **tenant Entra ID khác nhau** (ví dụ mỗi bạn dùng 1 Microsoft Account riêng), một SPN không thể truy cập subscription thuộc tenant khác. Khi đó chạy:

```powershell
.\infrastructure\account3\create-service-connections.ps1 -Mode PerSubscription -Pat "PAT"
```

Script sẽ tạo **1 SPN + 1 connection mỗi account**: `Azure-TripTo-ACC1` … `Azure-TripTo-ACC3`.
→ Nếu dùng chế độ này, hãy import pipeline **`azure-pipelines-report-multi.yml`** thay vì bản mặc định.

> 🔁 Muốn tạo lại từ đầu (đổi secret SPN): thêm tham số `-Force`.

---

## 6. Bước 3 — Xác minh trên Azure DevOps Portal

1. Vào `https://dev.azure.com/DuAnNhom2/BAO_CAO`
2. **Project Settings** (góc trái dưới) → **Service connections**
3. Thấy connection **`Azure-TripTo`** với trạng thái ✅ (xanh) — nếu đỏ, bấm **Edit → Verify** hoặc xem mục Xử lý sự cố bên dưới
4. Kiểm tra `az account list` chạy được với SPN: dùng pipeline ở bước 4 là bằng chứng chắc chắn nhất

---

## 7. Bước 4 — Tạo + chạy Pipeline báo cáo

1. **Pipelines → New Pipeline**
2. Chọn **Azure Repos Git** → chọn repo `DU_AN_NHOM2`
3. Chọn **Existing Azure Pipelines YAML file** → đường dẫn `infrastructure/account3/azure-pipelines-report.yml`
4. **Run**

Pipeline thực hiện:
- 🔍 Đọc `parameters.json` → lấy danh sách subscription
- 📥 Chạy `az resource list` cho **từng account** (qua connection `Azure-TripTo`)
- 📝 Chạy `generate-report.sh` → **`REPORT.md`** (thống kê + chi tiết từng account)
- 📦 Công bố artifact **`BaoCaoToanBoDichVu`**

> Kết quả xem ở: build run → tab **Artifacts** → tải `REPORT.md`.
> Trigger để `none` (chạy tay) — chạy lại bất cứ lúc nào để cập nhật số liệu mới.

---

## 8. Bước 5 — Chạy báo cáo local trên máy DevOps (offline)

Không cần vào DevOps portal — mọi thứ chạy ngay trên máy:

```powershell
# Thu thập tài nguyên (cần az login đủ 3 account)
.\infrastructure\account3\collect-resources.ps1

# Kết quả:
#   reports/inventory/resources-ACC1.json ... meta-ACC3.json
#   reports/REPORT.md  ← báo cáo tổng hợp
```

Nếu muốn chạy lại chỉ riêng bước sinh báo cáo từ dữ liệu cũ:

```bash
bash infrastructure/account3/generate-report.sh -i reports/inventory -o reports/REPORT.md
```

> 💡 `reports/` là thư mục local — không commit lên git (đã nằm ngoài .gitignore mặc định; có thể thêm `reports/` vào .gitignore nếu muốn).

---

## 9. Bước 6 — Đưa báo cáo vào đồ án

Nội dung `REPORT.md` cung cấp bằng chứng **thời gian thực** cho Chương 3 của báo cáo:

| Phần trong REPORT.md | Dùng cho mục nào của báo cáo |
|----------------------|-------------------------------|
| Bảng tổng quan (số tài nguyên/account) | Mục 3.6 — Bảng tổng kết tài nguyên theo Account |
| Chi tiết từng account (tên, loại, region, RG, SKU) | Từng mục 3.x.y của mỗi dịch vụ (khung chuẩn mục 3) |
| Top loại dịch vụ | Chương 2 — Kiến trúc tổng thể |

Kết hợp với `docs/CAU_TRUC_BAO_CAO.md` (khung báo cáo Word) và các `docs/STEPS_*.md` để viết phần tương ứng.

---

## 10. Bảng ánh xạ dịch vụ → Account (tham khảo)

| Account | Nhóm | Dịch vụ chính |
|---------|------|---------------|
| ACC1 | Frontend & Backend | App Service tripto/tripto2, Traffic Manager, DNS, Key Vault, Azure Maps, Entra ID, API Management, Service Bus, SignalR, Notification Hubs, Communication Services |
| ACC2 | Database & Monitoring | MySQL Flexible, Storage Account, Redis Cache, Function App, Event Grid, Backup Vault, Log Analytics, App Insights, Sentinel, Automation, Policy, Defender, Cost Management |
| ACC3 | DevOps & Security | Azure DevOps (org `DuAnNhom2`), GitHub Actions, Azure Pipelines, Service Connection `Azure-TripTo`, báo cáo tổng hợp |

> 💡 **Lưu ý ACC3 (DevOps & Security):** account này thường **không có Azure subscription** (tài nguyên DevOps nằm trong Azure DevOps: pipelines, service connections, repo). Vì vậy `REPORT.md` (sinh từ `az resource list`) sẽ chỉ thể hiện tài nguyên của **ACC1 + ACC2**. Bằng chứng của ACC3 được ghi nhận riêng: pipeline run trên Azure DevOps, danh sách Service Connection `Azure-TripTo`, và các file CI/CD trong repo (`.github/workflows/*`, `azure-pipelines.yml`, `infrastructure/account3/*`).

---

## 11. URL truy cập nhanh — Nhóm Monitoring & Governance (ACC2)

> Danh sách **đường dẫn trực tiếp** trên Azure Portal cho các dịch vụ thuộc nhóm **Monitoring & Governance**, dùng để giao cho DevOps xem/giám sát.
> Subscription mặc định: `42e7a0ff-6e78-4530-a021-bf133c012ba2` (ACC2).
> Mẹo: đăng nhập Portal rồi dán URL; nếu muốn đổi subscription, chọn bộ lọc subscription ở góc trên. Để lấy URL đúng tenant của bạn, thay `@/` bằng `@<tenant-id>/`.

| # | Dịch vụ | Vị trí trên Portal | URL truy cập nhanh |
|---|---------|--------------------|--------------------|
| 1 | **Log Analytics Workspaces** | Monitor → Log Analytics workspaces | `https://portal.azure.com/#view/Microsoft_OperationsManagementSuite_Workspace/LogAnalyticsWorkspaces/Overview` |
| 2 | **Application Insights** | Monitor → Application Insights | `https://portal.azure.com/#view/Microsoft_AppInsights_DevCenter/AppInsights/Overview` |
| 3 | **Diagnostic Settings** | Monitor → Diagnostic settings | `https://portal.azure.com/#view/Microsoft_Azure_Monitoring/DiagnosticsSettingsV2/Overview` |
| 4 | **Metric Alerts** | Monitor → Alerts (Alert rules) | `https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AlertsV2/AlertsV2` |
| 5 | **Action Groups** | Monitor → Alerts → Action groups | `https://portal.azure.com/#view/Microsoft_Insights_ActionGroups/...` |
| 6 | **Microsoft Sentinel** | Monitor → Microsoft Sentinel | `https://portal.azure.com/#view/Microsoft_Azure_Sentinel/WorkspaceBlade/~/Overview` |
| 7 | **Automation Account** | Monitor → Automation → Automation accounts | `https://portal.azure.com/#view/Microsoft_Automation_AutomationAccount/Overview` |
| 8 | **Azure Policy** | Azure Policy (không thuộc Monitor) | `https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyMenuBlade/~/Overview` |
| 9 | **Defender for Cloud** | Microsoft Defender for Cloud | `https://portal.azure.com/#view/Microsoft_Azure_Security/DefenderForCloudMenuBlade/~/overview` |
| 10 | **Azure Advisor** | Azure Advisor | `https://portal.azure.com/#view/Microsoft_Azure_Advisor/AdvisorMenuBlade/~/Overview` |
| 11 | **Cost Management** | Cost Management + Billing | `https://portal.azure.com/#view/Microsoft_Azure_CostManagement/MenuBlade/~/Overview` |
| 12 | **Service Health** | Service Health | `https://portal.azure.com/#view/Microsoft_Azure_Health/ServiceHealthMenuBlade/~/overview` |

> ⚠️ Lưu ý: Một số "view" (Action Groups, Diagnostic Settings) có thể khác nhau theo bản Portal — nếu URL không mở được, hãy đi theo **Vị trí trên Portal** (cột 3) để vào đúng trang tương ứng.
> Nguồn tham chiếu đầy đủ: `https://portal.azure.com/#home` → chọn subscription `42e7a0ff-...` rồi dùng thanh tìm kiếm tên dịch vụ.

---

## 12. Xử lý sự cố

| Triệu chứng | Nguyên nhân & cách xử lý |
|-------------|--------------------------|
| `Tạo Service Connection thất bại: 401` | PAT thiếu scope **Service Connections (Read & manage)** → tạo PAT mới |
| Connection hiện **trạng thái đỏ** trên Portal | SPN chưa có quyền hoặc sai tenant → chạy lại script với `-Force`; kiểm tra role Reader cấp đúng subscription |
| `Cấp role Reader thất bại` | Subscription thuộc tenant khác (chế độ Shared) → chuyển `-Mode PerSubscription` |
| `az account show` không thấy subscription | Máy chưa `az login` bằng tài khoản sở hữu account đó → đăng nhập rồi chạy lại |
| `Tạo SPN thất bại` | Tài khoản không có quyền tạo App Registration trong Entra ID → nhờ admin cấp quyền hoặc tạo SPN thủ công |
| Pipeline báo lỗi `jq: command not found` | Chỉ xảy ra khi chạy local — cài jq: `choco install jq` / `winget install jq` (ubuntu agent có sẵn) |
| Báo cáo thiếu 1 account | Subscription ID để trống trong `parameters.json` hoặc SPN chưa được cấp Reader cho account đó |

---

## 13. Checklist hoàn tất

- [ ] `parameters.json` có đủ subscriptionId 3 account
- [ ] Chạy `create-service-connections.ps1` thành công (hoặc `-Mode PerSubscription`)
- [ ] Connection `Azure-TripTo` (hoặc `Azure-TripTo-ACC1..3`) xanh trên DevOps
- [ ] Pipeline báo cáo chạy **thành công** → có artifact `BaoCaoToanBoDichVu/REPORT.md`
- [ ] Chạy local `collect-resources.ps1` → có `reports/REPORT.md`
- [ ] Đối chiếu số tài nguyên trong báo cáo với danh mục ~30 dịch vụ (docs/CAU_TRUC_BAO_CAO.md)
- [ ] Cập nhật `infrastructure/account3/PROGRESS.md` + commit lên GitHub
