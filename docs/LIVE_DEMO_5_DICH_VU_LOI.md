# 🎬 LIVE DEMO 5 DỊCH VỤ LÕI — HƯỚNG DẪN CHI TIẾT

> Dùng cho phần bảo vệ đồ án. 5 dịch vụ này demo **trực tiếp trên Portal Azure**,
> tổng thời gian **80 giây**. Mỗi dịch vụ có: hiểu sao cho dễ → bấm gì → nói gì → bị hỏi gì.

**Tài khoản demo:** `nggiao01@gmail.com`
**Resource Group:** `rg-tripto-monitoring`
**Vùng:** `southeastasia` | **Subscription:** `42e7a0ff-6e78-4530-a021-bf133c012ba2`

---

## 🧭 TỔNG QUAN — 5 DỊCH VỤ NẰM TRONG 1 CHUỖI DUY NHẤT

```
[Web PHP tripto]  →  monitor.php gửi telemetry  →  [App Insights appi-tripto]
                                                          │ (gắn liền workspace)
                                                          ▼
                          [Log Analytics law-tripto]  ←──  dữ liệu đổ vào đây
                                 │          │
                                 ▼          ▼
                       [Metric Alerts] → [Action Group] → email nggiao01@gmail.com
                                 │
                                 ▼
                        [Sentinel - SIEM] phát hiện bảo mật
```

| # | Dịch vụ | Vai trò 1 câu | Thời gian |
|---|---------|---------------|-----------|
| 1 | Log Analytics | Kho chứa mọi log, nơi tra cứu | 20s |
| 2 | App Insights | Thu telemetry từ web | 15s |
| 3 | Metric Alerts | Tự phát hiện lỗi/chậm | 15s |
| 4 | Action Group | Gửi email khi có alert | 15s |
| 5 | Sentinel | SIEM phát hiện bảo mật | 15s |

---

# 🔢 DỊCH VỤ 1 — LOG ANALYTICS `law-tripto` (20 giây)

## 🧠 HIỂU ĐƠN GIẢN
Log Analytics giống **"kho dữ liệu trung tâm"** của cả hệ thống: mọi thứ (request web, lỗi,
metric Storage/MySQL, log hoạt động) đều đổ về một nơi duy nhất. Muốn biết web có hoạt động
không, mở kho này lên gõ câu lệnh tra cứu (KQL) là thấy ngay.

## 🛠️ BẰNG CHỨNG CẤU HÌNH (đã có trong project)
File `infrastructure/account2/modules/log-analytics.bicep`:
```bicep
sku: { name: 'PerGB2018' }        // trả tiền theo dung lượng dùng (rẻ)
retentionInDays: 30               // giữ log 30 ngày
workspaceCapping: { dailyQuotaGb: 5 }  // chặn chi phí vượt 5GB/ngày
```

## 🖱️ THAO TÁC TỪNG BƯỚC TRÊN PORTAL

| Bước | Bấm gì |
|------|--------|
| 1 | Mở `portal.azure.com` → thanh tìm kiếm trên đỉnh gõ `law-tripto` → Enter |
| 2 | Click vào workspace `law-tripto` |
| 3 | Menu trái → chọn **Logs** |
| 4 | Nếu có cửa sổ gợi ý query hiện lên → bấm **×** đóng lại |
| 5 | Dán query dưới đây vào ô soạn thảo → bấm **Run** |

**Query demo (dán vào):**
```kql
AppRequests
| where TimeGenerated > ago(24h)
| project TimeGenerated, Name, DurationMs, ResultCode, Success
| order by TimeGenerated desc
| take 10
```

## 🗣️ LỜI THOẠI NÓI (đọc nguyên văn)
> *"Đây là kho dữ liệu trung tâm của toàn hệ thống. Bảng AppRequests lưu mỗi request mà web
> PHP gửi về — hiện có hơn 1.300 request thật, kèm thời gian xử lý (DurationMs), mã trả về
> (ResultCode 200) và thành công hay không. Giờ em truy cập web một lần rồi chạy lại query
> để thấy dữ liệu mới xuất hiện."*

*(Mở tab web `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net/frontend/user/TRANGCHU.html`
→ quay lại bấm **Run** → trỏ chuột vào dòng trên cùng:)*
> *"Dòng mới nhất có TimeGenerated chỉ vài giây trước — dữ liệu chảy về **thời gian thực**,
> không cần cấu hình thêm gì."*

## 📊 ĐIỂM NHẤN GHI ĐIỂM
- `AppRequests` = **1.301** dòng | `AzureMetrics` = **301.000+** dòng | `AppEvents` = 21 | `AppExceptions` = 10
- Retention 30 ngày + quota 5GB/ngày = **vừa đủ demo, vừa chặn chi phí**.

## ❓ PHẢN BIỆN CÓ THỂ GẶP
- **"Sao tên bảng là AppRequests mà không phải requests?"**
  → *"Trong Log Analytics workspace, bảng App Insights có tiền tố App và cột viết hoa
  (PascalCase). Đây là schema workspace-based — ghi rõ trong file monitoring/queries/*.kql."*
- **"Dữ liệu giữ bao lâu?"**
  → *"30 ngày — đủ cho báo cáo, không tốn chi phí lưu lâu."*

---

# 🔢 DỊCH VỤ 2 — APPLICATION INSIGHTS `appi-tripto` (15 giây)

## 🧠 HIỂU ĐƠN GIẢN
App Insights là **"tai mắt" của web**: nhận telemetry (mỗi request, sự kiện người dùng, lỗi PHP)
từ web gửi lên, rồi **đẩy thẳng vào Log Analytics**. Điểm đáng nói: dự án **không dùng SDK
của Microsoft** mà tự viết hàm gửi bằng HTTP REST (`monitor.php`) — vừa gọn vừa không cần Composer.

## 🛠️ BẰNG CHỨNG CẤU HÌNH
File `infrastructure/account2/modules/app-insights.bicep`:
```bicep
properties: {
  Application_Type: 'web'
  WorkspaceResourceId: workspaceId   // ← gắn liền workspace law-tripto
  RetentionInDays: 90
}
```
Code `backend/monitor.php` — các hàm gửi telemetry:
| Hàm | Gửi gì | Đổ vào bảng |
|-----|--------|-------------|
| `monitorTrackRequest()` | Mỗi request web | `AppRequests` |
| `monitorTrackEvent()` | Login, đặt tour... | `AppEvents` |
| `monitorTrackException()` | Lỗi PHP fatal | `AppExceptions` |
| `monitorTrackDependency()` | Gọi MySQL/DB | `AppDependencies` |

## 🖱️ THAO TÁC TỪNG BƯỚC TRÊN PORTAL

| Bước | Bấm gì |
|------|--------|
| 1 | Ô tìm kiếm portal gõ `appi-tripto` → Enter → click vào |
| 2 | Menu trái → chọn **Performance** (Hiệu suất) |
| 3 | Nhìn bảng: tổng số request, thời gian trung bình (Duration) |
| 4 | (Tùy chọn) Menu trái → **Failures** → thấy biểu đồ lỗi, danh sách exception |

## 🗣️ LỜI THOẠI NÓI (đọc nguyên văn)
> *"App Insights nhận toàn bộ telemetry từ web. Trang Performance cho thấy số request và
> thời gian xử lý trung bình. Điểm đáng chú ý: web PHP gửi dữ liệu lên đây qua file
> monitor.php bằng HTTP REST — không cần cài SDK, và vì gắn liền workspace nên dữ liệu
> tự chảy vào Log Analytics vừa demo ở trên."*

## 📊 ĐIỂM NHẤN GHI ĐIỂM
- **Không dùng SDK, dùng REST** → chứng minh hiểu sâu, tự viết được.
- `monitorMsToTimeSpan()` trong monitor.php — hàm đổi mili-giây sang đúng định dạng
  App Insights yêu cầu (từng fix bug 400, xem PROGRESS.md).

## ❓ PHẢN BIỆN CÓ THỂ GẶP
- **"Sao không dùng SDK chính thức?"**
  → *"Dự án chạy PHP trên App Service không cần Composer; tự viết REST giúp giảm phụ thuộc
  và dễ kiểm soát từng loại telemetry. Chuẩn API theo đúng spec App Insights."*
- **"Dữ liệu nằm ở đâu?"**
  → *"Do có WorkspaceResourceId trỏ tới law-tripto, telemetry nằm ngay trong Log Analytics,
  query được từ bảng App*."*

---

# 🔢 DỊCH VỤ 3 — METRIC ALERTS (15 giây)

## 🧠 HIỂU ĐƠN GIẢN
Metric Alerts là **"người gác đêm"**: cứ **mỗi 5 phút** kiểm tra số liệu của web một lần.
Thấy web **lỗi nhiều** hoặc **chạy chậm** là báo động ngay. Dự án có **2 rule**:

| Rule | Metric | Điều kiện bắn | Cửa sổ quan sát |
|------|--------|---------------|-----------------|
| `alert-failed-requests` | `requests/failed` | Hơn **5** request lỗi | 5 phút |
| `alert-slow-response` | `requests/duration` | Trung bình **> 5000ms (5 giây)** | 15 phút |

## 🛠️ BẰNG CHỨNG CẤU HÌNH
File `infrastructure/account2/modules/alerts.bicep`:
```bicep
// Rule 1 - lỗi
metricName: 'requests/failed'
operator: 'GreaterThan'  threshold: 5  timeAggregation: 'Count'
evaluationFrequency: 'PT5M'  windowSize: 'PT5M'  severity: 3
// Rule 2 - chậm
metricName: 'requests/duration'
operator: 'GreaterThan'  threshold: 5000  timeAggregation: 'Average'
evaluationFrequency: 'PT5M'  windowSize: 'PT15M'  severity: 3
```

## 🖱️ THAO TÁC TỪNG BƯỚC TRÊN PORTAL

| Bước | Bấm gì |
|------|--------|
| 1 | Ô tìm kiếm gõ `Monitor` → Enter → menu trái chọn **Alerts** |
| 2 | Tab **Alert rules** → bấm ô lọc **Scope** → chọn `rg-tripto-monitoring` → Apply |
| 3 | Thấy 2 rule: `alert-failed-requests`, `alert-slow-response` — trạng thái **Enabled** |
| 4 | Click `alert-failed-requests` → xem **Condition** (metric, threshold, frequency) |
| 5 | Xem **Actions** (gắn `ag-tripto-critical`) và **Details** (severity, Enabled) |
| 6 | Bấm nút quay lại → click `alert-slow-response` → chỉ vào windowSize **PT15M** |

## 🗣️ LỜI THOẠI NÓI (đọc nguyên văn)
> *"Đây là 2 alert rule tự phát hiện bất thường: rule đầu theo dõi request lỗi — quá 5 lỗi
> trong 5 phút là báo động; rule thứ hai theo dõi tốc độ — trung bình chậm hơn 5 giây trong
> 15 phút là báo động. Cả hai kiểm tra mỗi 5 phút, và toàn bộ được khai báo bằng code Bicep
> nên tạo lại bất cứ lúc nào cũng y hệt."*

## 📊 ĐIỂM NHẤN GHI ĐIỂM
- **IaC**: rule nằm trong `modules/alerts.bicep`, deploy bằng GitHub Actions.
- Không tạo alert CPU/Memory vì web chạy App Service (không có VM) — **chứng tỏ hiểu đúng mô hình**.
- 2 rule này chưa từng bắn = hệ thống đang chạy khỏe (câu trả lời hay nếu bị hỏi).

## ❓ PHẢN BIỆN CÓ THỂ GẶP
- **"Số 5 là 5% hay 5 request?"**
  → *"Theo cấu hình Bicep, metric requests/failed gộp theo Count, ngưỡng 5 — nghĩa là
  hơn 5 request lỗi trong cửa sổ 5 phút."* (nói đúng cấu hình trên màn hình, đừng tự nói %)
- **"Sao chưa thấy alert nào bắn?"**
  → *"Vì web đang hoạt động tốt: không lỗi, không chậm. Alert chỉ bắn khi vượt ngưỡng —
  không có alert instance chính là bằng chứng hệ thống ổn định."*

---

# 🔢 DỊCH VỤ 4 — ACTION GROUP `ag-tripto-critical` (15 giây)

## 🧠 HIỂU ĐƠN GIẢN
Action Group là **"danh bạ người nhận cảnh báo"**: khi alert bắn, nó quyết định **gửi đi đâu**.
Ở đây là gửi **email** cho admin. Bản thân Action Group không tự gửi gì — chỉ hoạt động khi
được gắn vào alert.

## 🛠️ BẰNG CHỨNG CẤU HÌNH
File `infrastructure/account2/modules/action-group.bicep`:
```bicep
groupShortName: 'TripToAlerts'
emailReceivers: [{
  name: 'AdminEmail'
  emailAddress: 'nggiao01@gmail.com'   // từ parameters.json
  useCommonAlertSchema: true
}]
smsReceivers: []      // không dùng SMS (có phí)
webhookReceivers: []  // không cần webhook
```

## 🖱️ THAO TÁC TỪNG BƯỚC TRÊN PORTAL

| Bước | Bấm gì |
|------|--------|
| 1 | Monitor → menu trái → **Alerts** → tab **Action groups** |
| 2 | Click `ag-tripto-critical` |
| 3 | Nhìn mục **Notifications**: email `nggiao01@gmail.com`, enabled |
| 4 | Nhìn mục **Actions**: (webhook/SMS trống) |

## 🗣️ LỜI THOẠI NÓI (đọc nguyên văn)
> *"Đây là đích gửi cảnh báo: Action Group `ag-tripto-critical` chứa địa chỉ email
> nggiao01@gmail.com. Cả 2 metric alert và 2 alert sức khỏe tài nguyên đều trỏ về đây —
> nên mọi bất thường đều đổ về một hòm thư của admin. Nhóm chọn email vì miễn phí và đủ
> cho quy mô đồ án; không dùng SMS vì tốn phí."*

## 📊 ĐIỂM NHẤN GHI ĐIỂM
- Email đã được **đổi sang nggiao01@gmail.com** và verify bằng `az monitor action-group show`
  (ghi trong PROGRESS.md).
- `useCommonAlertSchema: true` = dùng schema cảnh báo chuẩn, dễ tự động xử lý.

## ❓ PHẢN BIỆN CÓ THỂ GẶP
- **"Email không nhận được thì làm sao?"**
  → *"Kiểm tra 2 chỗ: Action Group đúng email chưa, và email chưa bấm unsubscribe — vì
  Azure gửi email dạng subscription cần xác nhận."*
- **"Sao không gọi điện/SMS?"**
  → *"SMS có phí theo tin nhắn; với đồ án sinh viên email là đủ và miễn phí."*

---

# 🔢 DỊCH VỤ 5 — MICROSOFT SENTINEL (SIEM) (15 giây)

## 🧠 HIỂU ĐƠN GIẢN
Sentinel là **"camera an ninh"** cho toàn hệ thống: một SIEM (Security Information & Event
Management) **chạy ngay trên Log Analytics** — không phải dịch vụ riêng. Nó đọc dữ liệu trong
workspace, chạy các luật phát hiện, và khi thấy dấu hiệu xấu (như nhiều request lỗi 5xx)
thì **tự tạo Incident** để xử lý.

## 🛠️ BẰNG CHỨNG CẤU HÌNH
| Thành phần | Tên | Trạng thái |
|------------|-----|-----------|
| Data connector | `ds-activity-to-sentinel` (Azure Activity) | Enabled |
| Analytic rule | `rule-high-failed-requests` | Enabled, Scheduled, severity Medium |

Query của rule (trong `MONITORING_GUIDE.md`):
```kql
AppRequests
| where TimeGenerated > ago(1h)
| summarize FailedCount = countif(ResultCode startswith "5"),
            TotalCount = count() by bin(TimeGenerated, 15m)
| where FailedCount > 0
| project TimeGenerated, FailedCount, TotalCount
```
→ Chạy mỗi 1 giờ; có request 5xx là tạo **Incident** (severity Medium, tactic Impact).

## 🖱️ THAO TÁC TỪNG BƯỚC TRÊN PORTAL

| Bước | Bấm gì |
|------|--------|
| 1 | Ô tìm kiếm gõ `Microsoft Sentinel` → Enter → chọn workspace `law-tripto` |
| 2 | Menu trái → mục **Configuration** → **Analytics** |
| 3 | Bấm ô lọc trạng thái → chọn **Active** → thấy rule `rule-high-failed-requests` |
| 4 | Click rule → xem query, schedule (1h), severity, trạng thái Enabled |
| 5 | (Tùy chọn) Menu trái → **Incidents** → nếu có incident thì trỏ vào |
| 6 | (Tùy chọn) Menu trái → **Data connectors** → `Azure Activity` Connected |

## 🗣️ LỜI THOẠI NÓI (đọc nguyên văn)
> *"Sentinel là lớp bảo mật của hệ thống — SIEM chạy ngay trên chính workspace vừa demo.
> Nó có một analytic rule tên rule-high-failed-requests: mỗi giờ quét bảng AppRequests,
> nếu phát hiện request lỗi 5xx trong 15 phút thì tự tạo Incident để đội vận hành xử lý.
> Dữ liệu đến từ connector Azure Activity — toàn bộ hoạt động quản trị đều được theo dõi."*

## 📊 ĐIỂM NHẤN GHI ĐIỂM
- Sentinel **không phải dịch vụ độc lập** — dùng chính `law-tripto` làm nguồn (bằng chứng
  `features.unifiedSentinelBillingOnly: true` trên workspace). Nói được điểm này là "ăn điểm".
- Rule tự tạo Incident khi HTTP 5xx → thể hiện khép kín: phát hiện → cảnh báo → xử lý.

## ❓ PHẢN BIỆN CÓ THỂ GẶP
- **"Sentinel khác gì Log Analytics?"**
  → *"Log Analytics là kho chứa; Sentinel là lớp phân tích bảo mật chạy trên kho đó —
  có rule phát hiện và tạo incident, Log Analytics chỉ lưu và tra cứu."*
- **"Chi phí Sentinel?"**
  → *"Sentinel tính phí theo dữ liệu đưa vào (đang dùng chung gói miễn phí 10GB/ngày đầu
  của workspace) — nằm trong ngân sách $20/tháng."* ⚠️ *Nếu không chắc số liệu thì chỉ nói
  "nằm trong hạn mức budget".*

---

## ✅ CHECKLIST TRƯỚC KHI DEMO (5 dịch vụ lõi)

- [ ] Đăng nhập portal bằng `nggiao01@gmail.com` trước, mở sẵn trình duyệt
- [ ] Mở sẵn **5 tab theo thứ tự**: ① Logs của `law-tripto` (query dán sẵn) ② Performance `appi-tripto`
      ③ Alerts (scope `rg-tripto-monitoring`) ④ Action groups → `ag-tripto-critical`
      ⑤ Sentinel → Analytics (`law-tripto`)
- [ ] Có sẵn **1 tab web** `tripto...azurewebsites.net/frontend/user/TRANGCHU.html` để truy cập tạo dữ liệu mới
- [ ] Ghi số liệu ra giấy: **1.301 AppRequests / 301k AzureMetrics / 5 giây / 5 phút / nggiao01@gmail.com**
- [ ] Tập nói 2 lần theo đúng lời thoại, bấm giờ mỗi dịch vụ (15–20s)

## ⏱️ NHỊP THỜI GIAN NHẮC NHỞ
```
0:00  Dịch vụ 1 Log Analytics      (20s)
0:20  Dịch vụ 2 App Insights       (15s)
0:35  Dịch vụ 3 Metric Alerts      (15s)
0:50  Dịch vụ 4 Action Group       (15s)
1:05  Dịch vụ 5 Sentinel           (15s)
1:20  ← hết phần LIVE DEMO, chuyển sang phần lướt nhanh
```
