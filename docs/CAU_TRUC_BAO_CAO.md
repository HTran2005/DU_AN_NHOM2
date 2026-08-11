# 📄 CẤU TRÚC BÁO CÁO ĐỒ ÁN — HỆ THỐNG TRIPTO TRÊN MICROSOFT AZURE

> File này là **khung báo cáo Word** (mục lục + hướng dẫn viết từng mục).
> Dùng để viết báo cáo đồ án đầy đủ **toàn bộ dịch vụ Azure** đã triển khai.
> Nguồn đối chiếu: toàn bộ code + tài liệu trong repo `DU_AN_NHOM2`.

---

## 📋 DANH MỤC DỊCH VỤ AZURE TRONG DỰ ÁN (tổng cộng ~30 dịch vụ)

| # | Nhóm | Dịch vụ | Tài nguyên | File bằng chứng trong repo |
|---|------|---------|-----------|---------------------------|
| 1 | Frontend & Security | App Service (chính) | `tripto` | `docs/STEPS_ACCOUNT1.md` |
| 2 | Frontend & Security | App Service (dự phòng) | `tripto2` | `docs/STEPS_ACCOUNT1.md` |
| 3 | Frontend & Security | Traffic Manager | `tripto-tm` | `docs/STEPS_ACCOUNT1.md` |
| 4 | Frontend & Security | Azure DNS Zones | `tripto.vn` (zone trắng) | `docs/STEPS_ACCOUNT1.md` |
| 5 | Frontend & Security | Key Vault | `triptokv` | `docs/STEPS_ACCOUNT1.md` |
| 6 | Frontend & Security | Azure Maps | `tripto-maps` | `docs/STEPS_ACCOUNT1.md`, `frontend/user/chitiettour.html` |
| 7 | Frontend & Security | Microsoft Entra ID | App Registration `tripto-app` | `docs/GIAI_THICH_DANG_NHAP_MICROSOFT.md`, `backend/config.php` |
| 8 | Database & Storage | Azure Database for MySQL Flexible | `tripto-mysql-db` (B1s) | `docs/STEPS_DATABASE_STORAGE.md`, `backend/config.php` |
| 9 | Database & Storage | Storage Account | `sttriptobackup` | `docs/STEPS_DATABASE_STORAGE.md`, `backend/blob/BlobStorage.php` |
| 10 | Database & Storage | Azure Cache for Redis | `tripto-redis` (C0) | `docs/STEPS_DATABASE_STORAGE.md`, `backend/redis.php`, `backend/RedisClient.php` |
| 11 | Database & Storage | Azure Function App | `tripto-function` | `docs/STEPS_DATABASE_STORAGE.md`, `backend/function/src/functions/*` |
| 12 | Database & Storage | Event Grid | system topic `tripto-visit-created` | `docs/STEPS_DATABASE_STORAGE.md`, `backend/azure-config.ps1` |
| 13 | Database & Storage | Virtual Network (VNet) | — | `docs/STEPS_DATABASE_STORAGE.md` (Dịch vụ 4) |
| 14 | Database & Storage | Backup Center + Recovery Services Vault | `rsv-tripto` | `docs/STEPS_DATABASE_STORAGE.md`, `infrastructure/account2/modules/recovery-vault.bicep` |
| 15 | Backend & Integration | API Management | `tripto-api-management.azure-api.net/tripto/` | `docs/STEPS_BACKEND_INTEGRATION.md`, 20 file frontend |
| 16 | Backend & Integration | Service Bus | `sb-tripto-backend` / queue `booking-queue` | `backend/config.php`, `backend/servicebus/ServiceBus.php` |
| 17 | Backend & Integration | SignalR Service | hub `triptoHub` | `backend/function/src/functions/negotiate.js`, `sendNotification.js`, `frontend/js/signalr.js` |
| 18 | Backend & Integration | Notification Hubs | `tripto-hub` (Web Push/VAPID) | `backend/function/src/functions/notificationHub*.js`, `sw.js`, `frontend/js/push-notification.js` |
| 19 | Backend & Integration | Communication Services | SMTP (qua `SendBookingEmail`) | `backend/function/src/functions/SendBookingEmail.js`, log Function |
| 20 | Backend & Integration | Logic Apps | — ⚠️ chưa có bằng chứng | `docs/STEPS_BACKEND_INTEGRATION.md` mục 2 |
| 21 | Monitoring & Governance | Log Analytics | `law-tripto` (GỐC) | `infrastructure/account2/modules/log-analytics.bicep`, `monitoring/MONITORING_GUIDE.md` |
| 22 | Monitoring & Governance | Application Insights | `appi-tripto` | `infrastructure/account2/modules/app-insights.bicep`, `backend/monitor.php` |
| 23 | Monitoring & Governance | Diagnostic Settings | `ds-storage-to-law`, `ds-mysql-to-law`, `ds-activity-to-sentinel` | `monitoring/MONITORING_GUIDE.md` mục 6 |
| 24 | Monitoring & Governance | Metric Alerts | `alert-failed-requests`, `alert-slow-response` | `infrastructure/account2/modules/alerts.bicep` |
| 25 | Monitoring & Governance | Action Group | `ag-tripto-critical` | `infrastructure/account2/modules/action-group.bicep` |
| 26 | Monitoring & Governance | Microsoft Sentinel (SIEM) | rule `rule-high-failed-requests` | `monitoring/MONITORING_GUIDE.md` mục 9 |
| 27 | Monitoring & Governance | Azure Automation | `aa-tripto` + runbook `runbook-mysql-backup` | `scripts/runbook-mysql-backup.ps1` |
| 28 | Monitoring & Governance | Azure Policy | `policy-storage-encryption`, `policy-nsg-admin-ports` | `infrastructure/account2/policies/nsg-no-internet-admin-port.json` |
| 29 | Monitoring & Governance | Microsoft Defender for Cloud | 7 plans Standard | `monitoring/MONITORING_GUIDE.md` mục 11 |
| 30 | Monitoring & Governance | Azure Advisor | 42 khuyến nghị | `monitoring/advisor-service-health-report.md` |
| 31 | Monitoring & Governance | Cost Management | Budget `budget-500k-vnd` ($20/tháng) | `monitoring/MONITORING_GUIDE.md` mục 13 |
| 32 | Monitoring & Governance | Service Health / Resource Health | 2 alert Activity Log | `monitoring/advisor-service-health-report.md` |
| 33 | CI/CD | GitHub Actions | `main_tripto.yml`, `main_tripto2.yml`, `deploy-monitoring.yml` | `.github/workflows/*` |
| 34 | CI/CD | Azure Pipelines | `azure-pipelines.yml` | `azure-pipelines.yml` |

> 🔑 **3 account theo 3 máy:** Frontend & Backend (Account 1) · Database & Monitoring (Account 2) · DevOps & Security (Account 3).
> (4 nhóm dịch vụ: Frontend & Security + Backend & Integration thuộc **Account 1**; Database & Storage + Monitoring & Governance thuộc **Account 2**; CI/CD & bảo mật thuộc **Account 3**.)

---

# 📖 CẤU TRÚC BÁO CÁO WORD (ĐẦY ĐỦ)

## PHẦN MỞ ĐẦU

- **Bìa ngoài** — tên trường, tên đề tài, thành viên nhóm, giảng viên hướng dẫn, năm học
- **Lời cảm ơn**
- **Nhận xét của giảng viên** (để trống cho GV điền)
- **Mục lục** (tự cập nhật trong Word)
- **Danh mục từ viết tắt** — Azure, IaC, APIM, SLA, SIEM, PITR, SKU, CI/CD, JWT, OAuth...
- **Danh mục bảng, hình vẽ**

---

## CHƯƠNG 1 — GIỚI THIỆU ĐỀ TÀI

### 1.1. Lý do chọn đề tài
- Nhu cầu đặt tour du lịch trực tuyến; yêu cầu của môn học về triển khai hạ tầng cloud.
- Vì sao chọn **Microsoft Azure** (tài khoản Azure for Students, dịch vụ đa dạng, hỗ trợ sinh viên).

### 1.2. Mục tiêu của đề tài
- Xây dựng website đặt tour **TripTo** (frontend + backend PHP + MySQL).
- Triển khai lên **Azure**, tích hợp **≥ 20 dịch vụ Azure** theo phân công 3 máy.
- Giám sát, bảo mật, kiểm soát chi phí.

### 1.3. Phạm vi đề tài
- Chức năng: đăng ký/đăng nhập (kể cả Microsoft SSO), xem & tìm kiếm tour, đặt tour, thanh toán, quản trị tour/booking/khách hàng, đánh giá, yêu thích...
- 4 nhóm dịch vụ: Frontend & Security · Database & Storage · Backend & Integration · Monitoring & Governance.

### 1.4. Phương pháp nghiên cứu & công cụ
- Công nghệ: HTML/CSS/JS (frontend), PHP (backend), MySQL (DB), Bicep (IaC), PowerShell, GitHub Actions/Azure Pipelines (CI/CD).

### 1.5. Giới thiệu tổng quan về Azure Cloud
- Mô hình IaaS/PaaS/SaaS; khái niệm Resource Group, Subscription, Region; **Azure for Students**.
- Nêu ngắn gọn: Portal, Cloud Shell, CLI (`az`), Bicep (IaC).

### 1.6. Giới thiệu website TripTo
- Mô tả nghiệp vụ + sơ đồ chức năng (user/admin).
- Danh sách trang: `TRANGCHU.html`, `TATCA_TOUR.html`, `thanhtoan_chitiet.html`, `Admin_Login.html`, ...

---

## CHƯƠNG 2 — PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

### 2.1. Phân tích yêu cầu
- Yêu cầu chức năng (user: đặt tour, yêu thích, đánh giá; admin: quản lý tour, booking, khách hàng, thanh toán).
- Yêu cầu phi chức năng: hiệu năng, bảo mật, sẵn sàng cao, chi phí thấp.

### 2.2. Kiến trúc tổng thể hệ thống
- **Sơ đồ kiến trúc Azure** (vẽ bằng draw.io / Mermaid rồi chụp vào Word):

```
Browser → [App Service tripto/tripto2 + Traffic Manager]
              ↓
        [API Management Gateway]
              ↓
    [Backend PHP] ──→ [MySQL Flexible] · [Service Bus] · [Function App]
                                                ↓
         [Storage Account] ← Event Grid → Function → Redis
                                                ↓
         [SignalR / Notification Hubs] → browser realtime & push
              ↓
   [App Insights / Log Analytics] → Alerts → Action Group → email
```

- Giải thích luồng dữ liệu chính: **đặt tour** (create_booking → DB → Service Bus → SignalR → email).

### 2.3. Thiết kế cơ sở dữ liệu
- Sơ đồ ERD: các bảng chính `nguoi_dung`, `tour`, `dat_tour`, `danh_gia`, `yeu_thich`, `thanh_toan`...
- Mô tả vài bảng quan trọng (cột chính, khóa).

### 2.4. Thiết kế giao diện & luồng nghiệp vụ
- Sơ đồ use case, sơ đồ tuần tự luồng đặt tour.
- Ảnh chụp màn hình các trang chính.

### 2.5. Phân công công việc
- Bảng: thành viên / máy / nhóm dịch vụ / công việc chính (theo `docs/STEPS_*.md`).

---

## CHƯƠNG 3 — TRIỂN KHAI VÀ TÍCH HỢP CÁC DỊCH VỤ AZURE

> ### 📌 KHUNG CHUẨN VIẾT MỖI DỊCH VỤ (lặp lại cho TẤT CẢ các dịch vụ)
> Với mỗi dịch vụ, viết đủ **8 mục con** sau (cách này giúp báo cáo đồng bộ & dễ chấm điểm):
>
> 1. **Ý nghĩa của dịch vụ** — nó là gì, dùng trong Azure để làm gì, vì sao chọn cho TripTo.
> 2. **Vai trò trong hệ thống** — vẽ sơ đồ luồng nhỏ, dịch vụ nằm ở đâu, giao tiếp với ai.
> 3. **Các bước tạo trên Azure** — thao tác Portal hoặc lệnh `az ...` / file Bicep (dán lệnh + ảnh).
> 4. **Cấu hình sau khi tạo** — thông số chính (SKU, region, retention...), biến môi trường, policy.
> 5. **Tích hợp vào code** — file + hàm cụ thể (VD: `ServiceBus.php`, `monitor.php`, `signalr.js`).
> 6. **Cách kiểm thử thực tế** — từng bước test + kết quả quan sát được (số liệu, log, ảnh).
> 7. **Kết quả đạt được & trạng thái** — ✅ đã hoạt động / ⚠️ một phần / ❌ chưa đủ bằng chứng.
> 8. **Chi phí & lưu ý phản biện** — giá thành, điểm yếu, cách trả lời giảng viên.

### 3.0. Giới thiệu chương & cách tổ chức theo 4 nhóm

### 3.1. Nhóm 1 — Frontend & Bảo mật (Account 1)
- **3.1.1. Azure App Service** — `tripto` (F1 Free) + `tripto2`; deploy zip qua Cloud Shell; env vars; GitHub Actions `main_tripto.yml`; hạn chế F1 (ngủ đông, không bind domain).
- **3.1.2. Azure Traffic Manager** — `tripto-tm`, routing **Priority** failover; 2 endpoint External (tripto, tripto2); health monitor HTTPS 443 path `/`; vì sao bỏ Front Door (subscription sinh viên chặn).
- **3.1.3. Azure DNS Zones** — zone trắng `tripto.vn`; bản ghi NS/SOA tự sinh; record `www` CNAME; chứng minh bằng `nslookup`; điều kiện chạy thật (mua domain + nâng B1+).
- **3.1.4. Azure Key Vault** — `triptokv`, permission model **RBAC**; secrets `DB-PASS`, `MAPS-KEY`; dùng để lưu mật khẩu/khóa, không hardcode.
- **3.1.5. Azure Maps** — `tripto-maps` (Gen2 G2, location `global`); lỗi region policy sinh viên → tạo bằng `--location global`; nhúng Web SDK vào `chitiettour.html`; **bảo mật key** (maps-config.js gitignore, GH013 push protection).
- **3.1.6. Microsoft Entra ID (SSO)** — App Registration `tripto-app`; luồng MSAL.js + OAuth 2.0/OpenID Connect; backend `verifyMicrosoftIdToken()` xác minh JWT (issuer, audience, RS256, JWKS); các lỗi đã sửa (redirect_uri, issuer `login.live.com`, audience, tên "Khách Microsoft").

### 3.2. Nhóm 2 — Database & Storage (Account 2)
- **3.2.1. Azure Database for MySQL — Flexible Server** — `tripto-mysql-db` (B1s); SSL bắt buộc; user `nhom2`; **PITR 7 ngày** (backup built-in); kết nối persistent + `ping()` trong `config.php`; track `MySqlSlowLogs`/`MySqlAuditLogs` qua Diagnostic Settings.
- **3.2.2. Azure Storage Account** — `sttriptobackup`; 3 container `tour-images/` (ảnh tour — `BlobStorage.php`), `web-visits/` (lượt truy cập), `mysql-backups/`; file share `tripto-share` (backup).
- **3.2.3. Azure Cache for Redis** — `tripto-redis` (C0 Free); `RedisClient.php` wrapper (Predis + phpredis); dùng đếm tổng lượt truy cập key `tripto:visits:total` (INCR).
- **3.2.4. Azure Functions** — `tripto-function` (Node.js); liệt kê các function: `trackVisit`, `BlobEventHandler`, `visits`, `negotiate`, `sendNotification`, `SendBookingEmail`, `GetVapidPublicKey`, `RegisterNotification`, `SendNotificationHub`, `notificationHubDebug`.
- **3.2.5. Azure Event Grid** — system topic + subscription `tripto-visit-created`; event `Microsoft.Storage.BlobCreated`; blob `web-visits/` → trigger `BlobEventHandler` → tăng Redis.
- **3.2.6. Virtual Network** — mục đích cách ly tài nguyên; trạng thái: hướng dẫn chuẩn (làm sau) nếu chưa hoàn thành.
- **3.2.7. Backup Center + Recovery Services Vault** — `rsv-tripto` (Standard, GeoRedundant); backup file share `tripto-share` daily 02:00 giữ 30 ngày; **phân biệt rõ**: vault backup Azure Files, MySQL dùng PITR.

### 3.3. Nhóm 3 — Backend & Tích hợp dịch vụ (Account 1)
- **3.3.1. Azure API Management** — gateway `tripto-api-management.azure-api.net/tripto/`; frontend KHÔNG gọi thẳng backend nữa; CORS phía backend (`config.php`); commit `973adf3` đổi 20 file; lưu ý: chưa có bằng chứng về tạo resource/Policy/Subscription key.
- **3.3.2. Azure Service Bus** — namespace `sb-tripto-backend`, queue `booking-queue`; `ServiceBus.php` tự xây SAS token (HMAC-SHA256), send/receive/deleteMessage; tích hợp tác vụ nền sau `create_booking` (fastcgi_finish_request); lưu ý: chưa chứng minh consumer xử lý end-to-end.
- **3.3.3. Azure SignalR Service** — hub `triptoHub`, event `newNotification`; `negotiate.js` (input binding) + `sendNotification.js` (output binding); `frontend/js/signalr.js` kết nối WebSocket + Toast realtime; log `negotiate` Succeeded.
- **3.3.4. Azure Notification Hubs** — hub `tripto-hub`; **Web Push + VAPID**; `push-notification.js` + Service Worker `sw.js`; functions `GetVapidPublicKey`, `RegisterNotification`, `SendNotificationHub`; **lưu ý trung thực**: chưa chứng minh được chuỗi end-to-end → trình bày đúng mức "code + cấu hình, cần kiểm chứng trực tiếp".
- **3.3.5. Azure Communication Services** — SMTP gửi email xác nhận booking; function `SendBookingEmail.js` (nodemailer); di trú Gmail → ACS (commit `d3e5401`); bằng chứng log: `Accepted`, `SMTP Response: 250 Queued mail for delivery`.
- **3.3.6. Azure Logic Apps** — ⚠️ **ghi trung thực**: repo chưa có bằng chứng (không workflow, không trigger Service Bus). Nếu giảng viên hỏi → nói rõ nhóm chưa triển khai phần này hoặc sẽ bổ sung.

### 3.4. Nhóm 4 — Monitoring & Governance (Account 2)
- **3.4.1. Log Analytics** — `law-tripto` = **kho dữ liệu trung tâm** (GỐC); PerGB2018, retention 30 ngày, quota 5GB/ngày; các bảng `AppRequests` (1.301), `AzureMetrics` (301k+), `AppEvents`, `AppExceptions`.
- **3.4.2. Application Insights** — `appi-tripto` gắn liền workspace (`WorkspaceResourceId`); **tự viết REST** trong `monitor.php` (không dùng SDK): `monitorTrackRequest/Event/Exception/Dependency`; ikey `2c156544-...`; sự kiện `booking_created`, `user_login`...
- **3.4.3. Diagnostic Settings** — 3 ống dẫn: `ds-storage-to-law`, `ds-mysql-to-law` (MySqlSlowLogs/AuditLogs), `ds-activity-to-sentinel` (Activity).
- **3.4.4. Metric Alerts** — `alert-failed-requests` (>5 lỗi/5p), `alert-slow-response` (>5 giây/15p); severity 3; không alert CPU/Memory vì App Service (lý do thiết kế).
- **3.4.5. Action Group** — `ag-tripto-critical`, email `nggiao01@gmail.com`, `useCommonAlertSchema: true`; vì sao chọn email thay SMS/webhook.
- **3.4.6. Microsoft Sentinel** — SIEM chạy TRÊN workspace (không phải dịch vụ độc lập); connector `Azure Activity`; analytic rule `rule-high-failed-requests` (1h quét 5xx → Incident Medium).
- **3.4.7. Azure Automation** — `aa-tripto` + runbook PowerShell `runbook-mysql-backup`; dùng **Managed Identity**; upload blob `backup-check-*.log` mỗi ngày; không dùng mysqldump (sandbox không có) → dựa PITR + log xác nhận.
- **3.4.8. Azure Policy** — deny mở port 22/3389 ra internet (`nsg-no-internet-admin-port.json`); `policy-storage-encryption`; áp dụng cấp subscription/RG.
- **3.4.9. Microsoft Defender for Cloud** — 7 plans Standard (VM, SqlServers, AppServices, Arm, CloudPosture, Discovery, FoundationalCspm); lưu ý free trial 30 ngày.
- **3.4.10. Azure Advisor** — 42 khuyến nghị (Security, HighAvailability...); file `monitoring/advisor-service-health-report.md`.
- **3.4.11. Cost Management** — budget `budget-500k-vnd` ($20/tháng ≈ 500k VND); chi tiêu ~$3.18; alert 50/80/100% → email.
- **3.4.12. Service Health / Resource Health** — 0 sự cố; resource `law-tripto` Available; 2 Activity Log Alerts (`alert-service-health`, `alert-resource-health`).

### 3.5. CI/CD — GitHub Actions & Azure Pipelines (Account 3 — DevOps & Security)
- GitHub Actions: `main_tripto.yml`, `main_tripto2.yml` (deploy web khi push main), `deploy-monitoring.yml` (validate → deploy Bicep → verify, secret `AZURE_CREDENTIALS`).
- Azure Pipelines: `azure-pipelines.yml` (org `DuAnNhom2`, project `BAO_CAO` — cập nhật Work Item qua REST + PAT).
- **Account 3 (DevOps & Security) — liên kết toàn bộ dịch vụ lên Azure DevOps:**
  - Service Connection `Azure-TripTo` (SPN dùng chung `sp-tripto-devops-report`, role **Reader** trên các subscription) tạo bằng `infrastructure/account3/create-service-connections.ps1`.
  - Pipeline báo cáo `infrastructure/account3/azure-pipelines-report.yml` (chế độ PerSubscription: `azure-pipelines-report-multi.yml`) tự quét `az resource list` cả 3 account → xuất artifact `BaoCaoToanBoDichVu/REPORT.md` — dùng làm bằng chứng tổng hợp dịch vụ theo account.
  - Chạy local trên máy DevOps: `collect-resources.ps1` + `generate-report.sh` → `reports/REPORT.md`. Chi tiết: `docs/LIEN_KET_DEV_OPS_ACCOUNT3.md`.
- Nhấn mạnh **IaC bằng Bicep** → hạ tầng tái lập được, audit qua git.

### 3.6. Bảng tổng kết tài nguyên theo Account
- 4 bảng nhỏ hoặc 1 bảng lớn: Account / RG / Dịch vụ / Tài nguyên / Trạng thái (dùng lại bảng ở đầu file).

---

## CHƯƠNG 4 — KIỂM THỬ VÀ ĐÁNH GIÁ

### 4.1. Kịch bản kiểm thử end-to-end
- **Luồng đặt tour đầy đủ** (một kịch bản xuyên suốt):
  1. Mở web → đăng nhập (kể cả Microsoft SSO) → chọn tour → đặt tour.
  2. Quan sát: DB có booking mới; **Service Bus** `booking-queue` tăng Active message; **SignalR** Toast realtime ở tab khác; **email ACS** đến hộp thư; **App Insights** ghi `booking_created`.
- **Luồng giám sát**: alert bắn → email qua Action Group; Sentinel quét 5xx → Incident.
- **Luồng admin**: đăng nhập qua APIM → quản lý tour/booking → upload ảnh lên Blob.

### 4.2. Kết quả kiểm thử từng dịch vụ
- Bảng theo 4 nhóm: dịch vụ / cách test / kết quả / trạng thái (✅⚠️❌) — dựa vào khung mục 7 của từng dịch vụ ở Chương 3.

### 4.3. Đánh giá hiệu năng
- Số liệu thật từ App Insights: tổng request, Duration trung bình, request lỗi; Log Analytics: số dòng mỗi bảng.
- Nhận xét: web PHP trên F1 ngủ đông → request đầu chậm (đã ghi nhận).

### 4.4. Đánh giá bảo mật
- Không hardcode secret (Key Vault + env vars + Managed Identity); xác minh JWT phía backend; CORS đúng nguồn; Policy chặn port admin; Defender + Sentinel.

### 4.5. Đánh giá chi phí
- Bảng chi phí ước tính theo dịch vụ; so với budget $20/tháng; giải pháp tiết kiệm (F1 Free, Redis C0, PerGB2018, quota 5GB).

### 4.6. Thuận lợi, khó khăn, bài học kinh nghiệm
- Thuận lợi: Azure for Students, IaC tái lập nhanh, tài liệu phong phú.
- Khó khăn: policy subscription chặn region (Maps/Front Door), F1 hạn chế, CORS, MySQL connection chết, chi phí/retention.
- Bài học: ưu tiên env vars cho secret, kiểm tra CORS, viết bằng chứng (log/screenshot) ngay khi test.

---

## CHƯƠNG 5 — KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

### 5.1. Kết luận
- Tóm tắt kết quả: website hoàn chỉnh trên Azure với ~30 dịch vụ, giám sát & bảo mật đầy đủ, trong ngân sách.

### 5.2. Những gì đã đạt được
- Liệt kê theo 4 nhóm; nhấn mạnh các dịch vụ có bằng chứng hoạt động thật.

### 5.3. Hạn chế
- Nêu trung thực: Logic Apps chưa có bằng chứng, Notification Hubs chưa chứng minh end-to-end, APIM chưa có policy/subscription key, F1 không bind domain, VNet chưa hoàn thiện.

### 5.4. Hướng phát triển
- Nâng App Service lên B1+ + bind domain thật + DNS thật; bật policy APIM (rate limit, subscription key); hoàn thiện consumer Service Bus (Logic App/Function); chứng minh push notification end-to-end; thêm backup MySQL đầy đủ.

---

## TÀI LIỆU THAM KHẢO
- Microsoft Learn: App Service, MySQL Flexible, Service Bus, SignalR, API Management, App Insights, Sentinel, Cost Management...
- Tài liệu nhóm trong repo: `docs/STEPS_*.md`, `monitoring/MONITORING_GUIDE.md`, `docs/LIVE_DEMO_5_DICH_VU_LOI.md`.

## PHỤ LỤC
- **Phụ lục A**: Lệnh Azure CLI chính đã dùng (storage, function, maps, keyvault, servicebus...).
- **Phụ lục B**: File Bicep chính (`infrastructure/account2/main.bicep` + modules) — kèm giải thích.
- **Phụ lục C**: KQL queries (`monitoring/queries/*.kql`) + kết quả.
- **Phụ lục D**: Ảnh minh chứng Portal (mỗi dịch vụ 1–2 ảnh: overview, log, alert, budget...).
- **Phụ lục E**: Log thực thi Function App (email Succeeded, negotiate Succeeded...).

---

# ✅ CHECKLIST TRƯỚC KHI NỘP BÁO CÁO

- [ ] Mục lục + đánh số trang + tiêu đề Heading 1/2/3 (để Word tự tạo mục lục).
- [ ] Mỗi dịch vụ đủ 8 mục con theo khung chuẩn (mục 3.0).
- [ ] Có sơ đồ kiến trúc tổng thể + sơ đồ nhỏ từng luồng.
- [ ] Có ảnh chụp Portal thật cho các dịch vụ quan trọng (App Service, APIM, Service Bus Explorer, App Insights Performance, Alerts, Budget, Sentinel).
- [ ] Ghi trung thực trạng thái ✅⚠️❌ — không khẳng định những gì chưa kiểm chứng (Logic Apps, Notification Hubs end-to-end).
- [ ] Đối chiếu số liệu (request, chi phí, alert) tại thời điểm viết — cập nhật lại từ Portal.
- [ ] Phân công rõ ràng: mỗi thành viên viết nhóm dịch vụ của mình (dựa vào `docs/STEPS_*.md`).
