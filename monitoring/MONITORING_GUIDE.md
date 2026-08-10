# HƯỚNG DẪN CHI TIẾT — DỊCH VỤ MONITORING (Account 2 — Máy 4)

> Tài liệu này giải thích **từng dịch vụ Monitoring** của dự án TripTo, bám sát
> **source code & cấu hình thực tế** trong repo. Dùng để học và chuẩn bị bảo vệ đồ án.
>
> Subscription: `42e7a0ff-6e78-4530-a021-bf133c012ba2`
> Resource Group: `rg-tripto-monitoring`
> Vùng: `southeastasia`
> User: `nggiao01@gmail.com`

---

## MỤC LỤC

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Log Analytics `law-tripto` (GỐC)](#2-log-analytics-law-tripto)
3. [Application Insights `appi-tripto`](#3-application-insights-appi-tripto)
4. [Action Group `ag-tripto-critical`](#4-action-group-ag-tripto-critical)
5. [Metric Alerts (alert-failed-requests, alert-slow-response)](#5-metric-alerts)
6. [Diagnostic Settings → Log Analytics](#6-diagnostic-settings)
7. [Recovery Services Vault `rsv-tripto`](#7-recovery-services-vault-rsv-tripto)
8. [Azure Automation `aa-tripto` + Runbook](#8-azure-automation-aa-tripto)
9. [Microsoft Sentinel](#9-microsoft-sentinel)
10. [Azure Policy](#10-azure-policy)
11. [Microsoft Defender for Cloud](#11-microsoft-defender-for-cloud)
12. [Azure Advisor](#12-azure-advisor)
13. [Azure Cost Management (Budget)](#13-azure-cost-management)
14. [Azure Service Health / Resource Health](#14-azure-service-health)
15. [Microsoft Entra ID (App Registration)](#15-microsoft-entra-id)
16. [CI/CD — GitHub Actions](#16-cicd--github-actions)
17. [Các bảng dữ liệu trong Log Analytics](#17-các-bảng-dữ-liệu)

---

## 1. TỔNG QUAN KIẾN TRÚC

```
[WEB PHP backend - tripto/tripto2]
   config.php ──► include monitor.php ──► REST POST ──► dc.services.visualstudio.com/v2/track
        │                                                    │ (ikey 2c156544-...)
        ▼                                                    ▼
   user.php: monitorTrackEvent('booking_created','user_login',...)
                                                            │
                                              [Application Insights appi-tripto]
                                                            │ (WorkspaceResourceId = law-tripto)
                                                            ▼
[Storage sttriptobackup] ── ds-storage-to-law ──►  [LOG ANALYTICS law-tripto]  ◄── AppRequests/AppEvents/AppExceptions
[MySQL tripto-mysql-db]  ── ds-mysql-to-law ───►   (GỐC - kho dữ liệu trung tâm)  ◄── MySqlSlowLogs/MySqlAuditLogs
[Subscription activity]  ── ds-activity-to-sentinel ►   │
                                                       ├──► Metric Alerts ──► Action Group ──► email
                                                       ├──► Microsoft Sentinel (chạy TRÊN workspace)
                                                       └──► Dashboard / KQL queries

[Automation aa-tripto] ── runbook-mysql-backup ──► Storage blob (container mysql-backups)
[Recovery Vault rsv-tripto] ── backup tripto-share (file share)
```

**Vì sao Log Analytics là GỐC?**
Mọi telemetry từ web (qua App Insights đã **gắn liền workspace**), metric từ Storage/MySQL
(qua Diagnostic Settings), và log hoạt động (qua connector Azure Activity) đều **đổ về
`law-tripto`**. Sentinel chạy ngay trên workspace này; Metric Alerts đọc từ đây. Nếu workspace
chết → toàn bộ giám sát mất dữ liệu.

---

## 2. LOG ANALYTICS `law-tripto`

### Làm gì trong dự án
Là **kho dữ liệu trung tâm** lưu mọi log & metric. Đây là nơi duy nhất bạn "tra cứu" bằng KQL.

### Bằng chứng cấu hình — `infrastructure/account2/modules/log-analytics.bicep`
```bicep
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  properties: {
    sku: { name: 'PerGB2018' }        // trả theo dung lượng dùng
    retentionInDays: 30               // giữ dữ liệu 30 ngày
    workspaceCapping: { dailyQuotaGb: 5 }  // giới hạn 5GB/ngày tránh vượt chi phí
  }
}
```

### Giải thích từng mục cấu hình
| Cấu hình | Giá trị | Ý nghĩa / vì sao chọn |
|----------|---------|------------------------|
| `sku PerGB2018` | PerGB2018 | Thanh toán theo GB nạp vào, rẻ với dữ liệu nhỏ — phù hợp ngân sách sinh viên ($20/tháng) |
| `retentionInDays` | 30 | Giữ log 30 ngày; đủ để demo báo cáo, không tốn chi phí giữ lâu |
| `dailyQuotaGb` | 5 | Chặn chi phí bất ngờ nếu web tăng đột biến |

### Dữ liệu thực tế đang có (kiểm tra ngày 06/08/2026)
| Bảng | Số dòng |
|------|---------|
| `AzureMetrics` | ~301.000+ |
| `AppRequests` | 1.301 |
| `AppEvents` | 21 |
| `AppExceptions` | 10 |

### Khi nào hoạt động
Luôn hoạt động (24/7) khi có dữ liệu nạp vào. Giao diện **Logs** để chạy KQL.

### Chi phí
Gói **PerGB2018**, nằm trong hạn mức budget $20/tháng. Chi tiêu hiện tại ~$3.18.

### Giao tiếp với dịch vụ khác
- Nhận từ: **App Insights** (workspace-linked), **Diagnostic Settings** (Storage/MySQL/Activity)
- Cung cấp cho: **Metric Alerts**, **Sentinel**, **Dashboard**

---

## 3. APPLICATION INSIGHTS `appi-tripto`

### Làm gì trong dự án
Nhận **telemetry từ web** (mỗi request, sự kiện người dùng, lỗi PHP) và lưu vào Log Analytics.

### Bằng chứng cấu hình — `modules/app-insights.bicep`
```bicep
properties: {
  Application_Type: 'web'
  WorkspaceResourceId: workspaceId   // ← GẮN LIỀN workspace law-tripto
  RetentionInDays: 90
}
```

### Giải thích mục cấu hình
| Cấu hình | Ý nghĩa |
|----------|---------|
| `WorkspaceResourceId` | **Quan trọng nhất**: dữ liệu telemetry đi thẳng **VÀO Log Analytics** → query được ngay trong workspace, không cần gắn thêm gì |
| `Application_Type: web` | Đánh dấu là ứng dụng web (dùng metric `requests/duration`, `requests/failed`) |
| `RetentionInDays: 90` | Giữ telemetry 90 ngày |

### Luồng dữ liệu từ code — `backend/monitor.php`
Web gửi telemetry qua **HTTP REST** (không cần Composer/SDK):
- `monitorSend()` — POST JSON tới `https://dc.services.visualstudio.com/v2/track`
- `monitorEnvelope()` — đóng gói chuẩn App Insights (iKey, tags, baseType)
- `monitorMsToTimeSpan()` — đổi ms sang định dạng `dd.hh:mm:ss.fffffff` (bắt buộc, sai là App Insights trả 400)

### Các hàm track (đã có trong project)
| Hàm | Envelope | Bảng đích | Gọi từ đâu |
|-----|----------|-----------|-----------|
| `monitorTrackRequest()` | `Microsoft.ApplicationInsights.Request` | `AppRequests` | Tự động từ `config.php` (đầu/cuối mỗi request) |
| `monitorTrackEvent()` | `Microsoft.ApplicationInsights.Event` | `AppEvents` | `user.php`: `booking_created`, `user_login`, `user_register`, `user_microsoft_login`, `user_microsoft_register` |
| `monitorTrackException()` | `Microsoft.ApplicationInsights.Exception` | `AppExceptions` | Tự động khi có lỗi PHP fatal |
| `monitorTrackDependency()` | `Microsoft.ApplicationInsights.RemoteDependency` | `AppDependencies` | Gọi khi ghi nhận gọi DB/service ngoài |

### Instrumentation Key — `backend/config.php:31`
```php
define('APPINSIGHTS_INSTRUMENTATIONKEY',
  getenv('APPINSIGHTS_INSTRUMENTATIONKEY') ?: '2c156544-aac3-495d-ad96-9377a65ddcd2');
```
- Khớp với ikey của `appi-tripto` đã kiểm tra trên Azure.
- Ưu tiên biến môi trường (App Service), fallback default.

### Khi nào hoạt động
Mỗi khi web nhận request (qua `config.php` tự gọi `monitorBeginRequest`/`monitorEndRequest`).

### Sự kiện thực tế ghi nhận (từ `backend/user.php`)
- `booking_created` — khi đặt tour (kèm booking_id, tour_id, total, payment_method)
- `user_login`, `user_register`, `user_microsoft_login`, `user_microsoft_register`

### Giao tiếp với dịch vụ khác
Gửi dữ liệu **vào Log Analytics**; là **scope** của 2 Metric Alerts.

---

## 4. ACTION GROUP `ag-tripto-critical`

### Làm gì trong dự án
Là **đích gửi thông báo** khi có alert kích hoạt — ở đây gửi **email** cho admin.

### Bằng chứng cấu hình — `modules/action-group.bicep`
```bicep
properties: {
  groupShortName: 'TripToAlerts'
  enabled: true
  emailReceivers: [{
    name: 'AdminEmail'
    emailAddress: adminEmail          // = nggiao01@gmail.com (parameters.json)
    useCommonAlertSchema: true
  }]
  smsReceivers: []     // không dùng SMS
  webhookReceivers: [] // không dùng webhook
}
```

### Giải thích mục cấu hình
| Cấu hình | Ý nghĩa |
|----------|---------|
| `emailAddress: nggiao01@gmail.com` | Email nhận cảnh báo (đã đổi từ mặc định, xem `parameters.json`) |
| `useCommonAlertSchema: true` | Dùng schema alert chuẩn, dễ parse tự động |

### Vì sao chọn email thay vì SMS/webhook
Email **miễn phí & đơn giản** — phù hợp ngân sách sinh viên. SMS có phí; webhook không cần thiết vì không có hệ thống IT bên ngoài.

### Khi nào hoạt động
Chỉ hoạt động **khi được gắn vào alert** và alert **trigger**. Bản thân Action Group không tự gửi gì.

### Giao tiếp
Được **2 Metric Alerts** + 2 Activity Log Alerts tham chiếu qua `actionGroupId`.

---

## 5. METRIC ALERTS

### Làm gì trong dự án
Tự động phát hiện **lỗi request** và **response chậm** từ telemetry web.

### Bằng chứng cấu hình — `modules/alerts.bicep`

**Alert 1: `alert-failed-requests`**
```bicep
metricName: 'requests/failed'   // tỉ lệ request lỗi
operator: 'GreaterThan'
threshold: 5                    // > 5% request lỗi
timeAggregation: 'Count'
evaluationFrequency: 'PT5M'     // kiểm tra mỗi 5 phút
windowSize: 'PT5M'
severity: 3
```

**Alert 2: `alert-slow-response`**
```bicep
metricName: 'requests/duration' // thời gian response
operator: 'GreaterThan'
threshold: 5000                 // > 5 giây
timeAggregation: 'Average'
evaluationFrequency: 'PT5M'
windowSize: 'PT15M'             // quan sát trong 15 phút
severity: 3
```

### Giải thích mục cấu hình
| Mục | Alert lỗi | Alert chậm | Ý nghĩa |
|-----|-----------|-----------|---------|
| `metricName` | requests/failed | requests/duration | Metric từ App Insights |
| `threshold` | 5 (%) | 5000 (ms) | Ngưỡng kích hoạt |
| `timeAggregation` | Count | Average | Cách gộp metric |
| `windowSize` | 5m | 15m | Cửa sổ quan sát |
| `evaluationFrequency` | 5m | 5m | Tần suất đánh giá |

### Vì sao chọn cấu hình này
- Chỉ cảnh báo **khi có bất thường thật** (lỗi >5%, chậm >5s) để tránh nhiễu email.
- `alerts.bicep` chú thích: **không tạo alert CPU/Memory** vì web chạy trên App Service (không phải VM) → không có metric CPU VM.

### Khi nào hoạt động
Mỗi 5 phút đánh giá metric từ App Insights. Khi vượt ngưỡng → gửi email qua Action Group.

### Lỗi thường gặp
- Alert bắn nhưng **không nhận email** → kiểm tra Action Group đúng email + chưa bị unsubscribe.
- Alert không bao giờ trigger → dữ liệu `AppRequests` trống (kiểm tra telemetry có gửi về không).

### Giao tiếp
- **Scope**: `appi-tripto`
- **Action**: `ag-tripto-critical`

---

## 6. DIAGNOSTIC SETTINGS

### Làm gì trong dự án
Là "ống dẫn" tự động đưa **log & metric của tài nguyên** (MySQL, Storage) vào Log Analytics.

### Bằng chứng — tạo qua Portal (ghi nhận trong `PROGRESS.md`)
| Diagnostic Setting | Nguồn | Đích | Log gửi |
|--------------------|-------|------|---------|
| `ds-storage-to-law` | Storage `sttriptobackup` | `law-tripto` | AzureMetrics (Transaction, Capacity) |
| `ds-mysql-to-law` | MySQL `tripto-mysql-db` | `law-tripto` | MySqlSlowLogs, MySqlAuditLogs, AllMetrics |
| `ds-activity-to-sentinel` | Subscription activity | `law-tripto` | Administrative, Security, ServiceHealth, Policy |

### Giải thích
- **AzureMetrics** từ storage: đã về liên tục (~301k dòng) → streaming hoạt động tốt.
- **MySqlSlowLogs/MySqlAuditLogs**: cần bật `slow_query_log=ON`, `audit_log_enabled=ON`, `log_output=FILE` trên server rồi chạy query chậm (>1s) để có dữ liệu.

### Khi nào hoạt động
Liên tục, theo cấu hình gửi. Độ trễ log MySQL có thể lên tới 10-15 phút.

### Giao tiếp
Nguồn (Storage/MySQL/Activity) → **Log Analytics**.

---

## 7. RECOVERY SERVICES VAULT `rsv-tripto`

### Làm gì trong dự án
Thực hiện **backup file share** `tripto-share` (chứa dữ liệu/log trong storage `sttriptobackup`).

### Bằng chứng cấu hình — `modules/recovery-vault.bicep`
```bicep
sku: { name: 'Standard' }
properties: { publicNetworkAccess: 'Enabled' }
// backupconfig
properties: {
  storageType: 'GeoRedundant'   // lưu backup sao chép sang vùng khác
  storageTypeState: 'Locked'
}
```

### Giải thích mục cấu hình
| Cấu hình | Ý nghĩa |
|----------|---------|
| `sku Standard` | Backup chuẩn |
| `storageType: GeoRedundant` | Backup lưu ở 2 vùng → an toàn khi vùng chính mất |

### Backup thực tế (kiểm tra 06/08/2026)
- Item: `tripto-share` — Protection status **Healthy**
- Policy `policy-tripto-afs`: **Daily 02:00**, giữ **30 ngày**
- Job backup **Completed** liên tục từ 31/07 → 06/08

### Khi nào hoạt động
Hàng ngày lúc **02:00** theo lịch schedule.

### Giao tiếp
Backup **file share** trong storage `sttriptobackup`.

### Lưu ý cho phản biện
- Vault **KHÔNG phải** nơi backup MySQL (MySQL dùng PITR built-in 7 ngày của Azure).
- Vault backup **Azure Files** (file share) — đây là vai trò thực của nó.

---

## 8. AZURE AUTOMATION `aa-tripto`

### Làm gì trong dự án
Tự động hoá tác vụ định kỳ qua **Runbook** PowerShell — tạo log xác nhận backup MySQL mỗi ngày.

### Bằng chứng — `scripts/runbook-mysql-backup.ps1`
- Runbook: `runbook-mysql-backup` (PowerShell, **Published**)
- Schedule: chạy định kỳ (blob log mỗi ngày **19:02**)

### Runbook làm gì (từng bước trong script)
1. **Kết nối Azure bằng Managed Identity** (`Connect-AzAccount -Identity`)
2. Kiểm tra Storage `sttriptobackup` & container `mysql-backups` (tạo nếu chưa có)
3. Kiểm tra MySQL `tripto-mysql-db` (lấy backup retention)
4. Tạo file log `backup-check-<timestamp>.log`
5. **Upload blob** lên container `mysql-backups`
6. Dọn blob cũ hơn 14 ngày

### Bằng chứng hoạt động thực tế
Blob `backup-check-*.log` tồn tại **mỗi ngày** từ 31/07 → 05/08 (không sót ngày).

### Giải thích thiết kế
- Dùng **Managed Identity** (không cần mật khẩu trong code) — cần `Set-AzContext -SubscriptionId` sau khi connect (kinh nghiệm trong PROGRESS).
- **Không dùng `mysqldump`** vì không có trong sandbox Automation → dựa vào **PITR built-in** của MySQL và tạo log xác nhận.

### Giao tiếp
Automation (Managed Identity) → **Storage blob** `mysql-backups`.

---

## 9. MICROSOFT SENTINEL

### Làm gì trong dự án
Là lớp **SIEM** (Security Information & Event Management) **chạy trên** Log Analytics `law-tripto` — phát hiện bất thường bảo mật.

### Bản chất
Sentinel **không phải dịch vụ độc lập** — nó **dùng chính workspace** làm nguồn dữ liệu. (Bằng chứng: `features.unifiedSentinelBillingOnly: true` trên workspace).

### Các thành phần đã cấu hình
| Thành phần | Tên | Trạng thái |
|------------|-----|-----------|
| Data connector | `ds-activity-to-sentinel` (Azure Activity) | Enabled |
| Analytic rule | `rule-high-failed-requests` | Enabled, Scheduled, Medium |

### Analytic rule `rule-high-failed-requests`
```kql
AppRequests
| where TimeGenerated > ago(1h)
| summarize FailedCount = countif(ResultCode startswith "5"),
            TotalCount = count() by bin(TimeGenerated, 15m)
| where FailedCount > 0
| project TimeGenerated, FailedCount, TotalCount
```
- Chạy mỗi 1h, phát hiện có request lỗi (5xx).
- Khi khớp → tạo **Incident** (severity Medium, tactic Impact).

### Khi nào hoạt động
Mỗi khi analytic rule chạy (theo lịch) và dữ liệu khớp điều kiện.

### Giao tiếp
Đọc dữ liệu từ **Log Analytics `law-tripto`**.

---

## 10. AZURE POLICY

### Làm gì trong dự án
Áp đặt **chính sách bảo mật/tuân thủ** lên tài nguyên.

### Bằng chứng — `infrastructure/account2/policies/nsg-no-internet-admin-port.json`
Policy này **từ chối (deny)** mở port admin (22/3389) ra internet:
```json
"field": "Microsoft.Network/networkSecurityGroups/securityRules/destinationPortRange",
"in": ["22", "3389"],
"access": "Allow",
"direction": "Inbound",
"sourceAddressPrefix": "*"      // từ mọi nơi (internet)
→ effect: deny
```

### Các policy đang gán (kiểm tra 06/08/2026)
| Policy | Mục đích |
|--------|----------|
| `policy-storage-encryption` | Storage phải bật mã hoá hạ tầng |
| `policy-nsg-admin-ports` | Chặn mở port 22/3389 ra internet |

### Vì sao chọn
Bảo mật chủ động: ngăn lỗi cấu hình nguy hiểm (mở cổng admin ra internet) trước khi xảy ra.

### Khi nào hoạt động
Kiểm tra khi tạo/update tài nguyên. Vi phạm → chặn tạo hoặc đánh dấu không tuân thủ (Compliance).

---

## 11. MICROSOFT DEFENDER FOR CLOUD

### Làm gì trong dự án
Bảo mật toàn diện cho subscription — quét lỗ hổng, phát hiện mối đe doạ.

### Bằng chứng (kiểm tra 06/08/2026) — 7 plans Standard
`VirtualMachines`, `SqlServers`, `AppServices`, `Arm`, `CloudPosture`, `Discovery`, `FoundationalCspm`

### Giải thích
- **Standard** = bật tính năng đầy đủ (quét, phát hiện).
- **FoundationalCspm** = đánh giá tư thế bảo mật nền tảng.
- ⚠️ Lưu ý: một số plan đang dùng **free trial ~30 ngày** (ghi trong PROGRESS.md) — cần nêu khi báo cáo.

### Khi nào hoạt động
Liên tục quét tài nguyên & hiển thị khuyến nghị/alert bảo mật.

---

## 12. AZURE ADVISOR

### Làm gì trong dự án
Tự động phân tích tài nguyên và đưa **khuyến nghị best-practice** (miễn phí).

### Bằng chứng
- Kiểm tra 06/08/2026: **42 khuyến nghị** (tăng so với 25 ghi trước đó).
- File: `monitoring/advisor-service-health-report.md`.

### Các khuyến nghị điển hình (từ báo cáo)
| Nhóm | Nội dung |
|------|----------|
| Security | Chỉ 1 owner, bật Defender for SQL/Storage, chặn shared key |
| HighAvailability | Zone redundancy storage, geo-backup MySQL, Cross Region Restore |

### Khi nào hoạt động
Tự chạy định kỳ, không cần cấu hình. Xem tại Portal → Advisor.

---

## 13. AZURE COST MANAGEMENT

### Làm gì trong dự án
Theo dõi & giới hạn chi phí subscription.

### Bằng chứng (kiểm tra 06/08/2026)
- Budget: `budget-500k-vnd` — **$20/tháng** (≈500k VND)
- Chi tiêu hiện tại: **$3.18**
- Alert: 50% / 80% / 100% → email `nggiao01@gmail.com`

### Giải thích
- Budget đặt ngưỡng chi tiêu; khi chạm mốc 50%/80%/100% → email cảnh báo.
- Đang **trong giới hạn** → kiểm soát chi phí tốt.

### Khi nào hoạt động
Liên tục; alert gửi khi vượt mốc phần trăm.

---

## 14. AZURE SERVICE HEALTH

### Làm gì trong dự án
Theo dõi **sức khỏe của Azure** (toàn cục) và **từng tài nguyên**.

### Bằng chứng — `monitoring/advisor-service-health-report.md`
- **Service health events: 0** (không có sự cố Azure)
- **Resource health `law-tripto`: Available**

### 2 Alert đã cấu hình (Activity Log Alerts → `ag-tripto-critical`)
| Alert | Loại | Tác dụng |
|-------|------|----------|
| `alert-service-health` | ServiceHealth | Email khi Azure có sự cố dịch vụ |
| `alert-resource-health` | ResourceHealth | Email khi tài nguyên chuyển trạng thái xấu |

### Khi nào hoạt động
Liên tục; gửi email khi có sự cố/trạng thái xấu.

---

## 15. MICROSOFT ENTRA ID (App Registration)

### Làm gì trong dự án
Cung cấp **đăng nhập bằng Microsoft** cho web (xác thực OAuth 2.0).

### Bằng chứng — `backend/config.php:19-21`
```php
define('MS_CLIENT_ID', getenv('MS_CLIENT_ID') ?: '3e2d9308-3417-468d-a85a-6f6975c0da90');
define('MS_TENANT_ID', getenv('MS_TENANT_ID') ?: 'common');
define('MS_AUTHORITY', 'https://login.microsoftonline.com/' . MS_TENANT_ID . '/v2.0');
```
- App Registration: `tripto-app`
- SPA redirect URI cho cả 2 webapp tripto & tripto2

### Giải thích
- `tripto-app` là đăng ký ứng dụng → nhận clientId/tenant để xác thực.
- Backend có endpoint `login_microsoft`; web có MSAL config.

### Giao tiếp
Entra ID (authority) ↔ Web backend (OAuth token).

---

## 16. CI/CD — GITHUB ACTIONS

### Làm gì trong dự án
Tự động **deploy hạ tầng Monitoring** lên Azure mỗi khi push code.

### Bằng chứng — `.github/workflows/deploy-monitoring.yml`
Trigger khi push/thay đổi file trong `infrastructure/account2/**`.

3 jobs:
1. **validate** — cài Azure CLI, build Bicep (`az bicep build`), what-if preview
2. **deploy** — tạo RG + `az deployment group create` (chạy khi push main)
3. **verify** — kiểm tra workspace, App Insights, vault tồn tại

### Giải thích
- Dùng Secret `AZURE_CREDENTIALS` (service principal `sp-github-actions-tripto`, Contributor trên RG).
- **IaC bằng Bicep** → hạ tầng tái lập được, audit được qua git.

### Khi nào hoạt động
Khi push commit liên quan `infrastructure/account2/**`.

### Giao tiếp
GitHub Actions → **Azure** (deploy Bicep).

---

## 17. CÁC BẢNG DỮ LIỆU TRONG LOG ANALYTICS

> Quan trọng: **Trong Log Analytics workspace**, tên bảng App Insights có tiền tố **`App`**
> và cột viết **PascalCase** (`Name`, `DurationMs`, `TimeGenerated`...).
> Các file `monitoring/queries/*.kql` trong repo **đã viết theo schema workspace-based**
> (`AppRequests`, `AppExceptions`, `AppDependencies`) nên chạy được trực tiếp trong
> **Logs của Log Analytics workspace `law-tripto`**. Nếu mở Logs từ blade Application Insights,
> portal tự dịch sang tên cổ (`requests`, `name`, `problemId`...) nên query vẫn chạy được.

| Bảng (workspace) | Nguồn | Ý nghĩa |
|-------------------|-------|---------|
| `AppRequests` | App Insights (`monitorTrackRequest`) | Mỗi request vào web: duration, resultCode, success |
| `AppEvents` | App Insights (`monitorTrackEvent`) | Sự kiện người dùng: login, booking_created |
| `AppExceptions` | App Insights (`monitorTrackException`) | Lỗi PHP |
| `AppDependencies` | App Insights (`monitorTrackDependency`) | Gọi DB/service ngoài (MySQL query, HTTP...) |
| `AzureMetrics` | Diagnostic Settings (Storage/MySQL) | Metric hạ tầng |
| `MySqlSlowLogs` | Diagnostic Settings (MySQL) | Truy vấn chậm > long_query_time |
| `MySqlAuditLogs` | Diagnostic Settings (MySQL) | Hoạt động kết nối/audit |
| `AzureActivity` | Connector Azure Activity | Log hoạt động quản trị |

### Cột quan trọng
- `TimeGenerated` — thời điểm ghi log (App Insights dùng `TimeGenerated`, không phải `timestamp`).
- `ResultCode` — mã HTTP (dùng để lọc 5xx).

---

## TÓM TẮT VAI TRÒ TỪNG DỊCH VỤ

| Dịch vụ | Vai trò |
|---------|---------|
| Log Analytics | Kho dữ liệu trung tâm (GỐC) |
| App Insights | Thu telemetry web |
| Action Group | Đích gửi email cảnh báo |
| Metric Alerts | Tự phát hiện lỗi/chậm |
| Diagnostic Settings | Đưa log tài nguyên vào workspace |
| Recovery Vault | Backup file share |
| Automation | Tự động backup-check định kỳ |
| Sentinel | SIEM phát hiện bảo mật |
| Policy | Áp chính sách bảo mật |
| Defender | Bảo mật toàn diện |
| Advisor | Khuyến nghị best-practice |
| Cost | Kiểm soát chi phí |
| Service Health | Theo dõi sức khỏe Azure |
| Entra ID | Đăng nhập bằng Microsoft |
| GitHub Actions | Deploy hạ tầng IaC |
