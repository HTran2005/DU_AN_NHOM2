# 🧩 GIỚI THIỆU 5 DỊCH VỤ CI/CD & DEVOPS — HỆ THỐNG TRIPTO TRÊN MICROSOFT AZURE

> Tài liệu trình bày **5 dịch vụ** được dùng trong đồ án TripTo:
> **Azure Boards · Azure Pipelines · Azure Load Testing · Azure App Configuration · Azure App Service**.
> (GitHub Actions đã được loại bỏ — nhóm dùng **Azure Pipelines** làm CI/CD chính.)
>
> Mỗi dịch vụ viết theo **khung chuẩn 8 mục** (thống nhất với `docs/CAU_TRUC_BAO_CAO.md`): ý nghĩa → vai trò → các bước tạo → cấu hình → tích hợp code → kiểm thử → kết quả/trạng thái → chi phí & lưu ý.
> Nguồn đối chiếu: toàn bộ tài nguyên + lệnh Azure CLI/DevOps đã xác minh thật trong đồ án.

---

## 📋 TỔNG QUAN 5 DỊCH VỤ

| # | Dịch vụ | Vai trò 1 câu | Bằng chứng thực tế | Trạng thái |
|---|---------|---------------|----------------------|------------|
| 1 | Azure Boards | Quản lý task/Work Item xuyên suốt vòng đời | 39 Work Items; #34/#33/#20 → Resolved | ✅ đã triển khai |
| 2 | Azure Pipelines | CI/CD phía Azure DevOps org `DuAnNhom2` | `azure-pipelines.yml`; 10 run succeeded | ✅ đã triển khai |
| 3 | Azure Load Testing | Kiểm thử tải cho web | `tripto-load-testing`, test `tripto-web-load-test` (TestRun DONE) | ✅ đã triển khai |
| 4 | Azure App Configuration | Quản lý cấu hình tập trung | Store `tripto-appconfig`, 25 key-value + feature flag `LOGIN_ENABLED` | ✅ đã triển khai |
| 5 | Azure App Service | Nơi host web TripTo | `bao-cao-nhom2-web` (Linux, PHP 8.3, S1); tích hợp Key Vault + App Config | ✅ đã triển khai |

> 🔑 Nhóm 5 dịch vụ này thuộc mảng **CI/CD & DevOps**: Azure Boards, Azure Pipelines, Azure Load Testing,
> Azure App Configuration thuộc **DevOps toolchain**; Azure App Service là **môi trường chạy web (runtime)** được
> pipeline deploy lên.

---

# 🔢 DỊCH VỤ 1 — AZURE BOARDS

## 🧠 Ý NGHĨA CỦA DỊCH VỤ
Azure Boards là dịch vụ **quản lý công việc (Work Items)** của Azure DevOps: quản lý backlog,
task, bug, épic theo mô hình Scrum/Kanban. Trong đồ án, Boards dùng để **theo dõi từng việc làm**
(VD: "Implement Microsoft Entra ID AB#34") và **liên kết trực tiếp với commit + pipeline** — nhờ
link Work Item ID trong commit message, pipeline tự chuyển trạng thái Work Item (New → Active → Resolved).

## 🎯 VAI TRÒ TRONG HỆ THỐNG
```
[Git commit: "Implement Entra ID AB#34"]
        │  Azure Pipelines đọc commit → tìm AB#34
        ▼
[Azure Boards Work Item #34]
        │  New ──► Active ──► Resolved  (6 bước trong pipeline đổi trạng thái)
        ▼
[Bảng Kanban/Sprint]  ←  nhóm nhìn tiến độ tại dev.azure.com
```

## 🛠️ CÁC BƯỚC TẠO TRÊN AZURE
1. Vào `https://dev.azure.com/DuAnNhom2` → open project `BAO_CAO`.
2. Menu trái → **Boards** → **Backlog** (hoặc **Sprints** / **Queries**).
3. Bấm **New Item** → tạo Work Item loại *User Story* / *Task*, ghi rõ nội dung + gán thành viên.
4. Ghi chú: Work Item được link qua cú pháp **`AB#<id>`** trong commit message.

## ⚙️ CẤU HÌNH SAU KHI TẠO
- Process template: **Basic / Scrum / Agile** (mặc định của project — ràng buộc danh sách trạng thái).
- Các trạng thái dùng thực tế: `New` → `Active` → `Resolved` (xem pipeline ứng dụng REST).

## 💻 TÍCH HỢP VÀO CODE
- Trong `azure-pipelines.yml`:
  - Step 2 "Get Work Item ID" — đọc commit message, bắt chuỗi `AB#<id>`:
    ```bash
    WORKITEM=$(echo "$COMMIT_MSG" | grep -oE 'AB#[0-9]+' | head -1 | grep -oE '[0-9]+')
    echo "##vso[task.setvariable variable=WORKITEM_ID]$WORKITEM"
    ```
  - Step 3 — REST `PATCH .../_apis/wit/workitems/$(WORKITEM_ID)` đổi State → `Active`.
  - Step 13 — đổi State → `Resolved` (chỉ chạy khi `succeeded()`).
- Dùng **PAT** (scope *Work Items: Read & write*) truyền qua biến `PAT` (variable group `TRIPTO-CONFIG`).

## 🧪 CÁCH KIỂM THỬ THỰC TẾ
1. Commit code kèm `AB#34` → push lên `main`.
2. Quan sát pipeline run: step "Set Work Item Active" trả `Work Item 34 -> Active`.
3. Mở Boards → thấy Work Item #34 chuyển từ New sang Active.
4. Khi pipeline thành công → Work Item tự chuyển sang Resolved.

## 📊 KẾT QUẢ ĐẠT ĐƯỢC & TRẠNG THÁI
- ✅ **Đã chứng minh bằng code**: cơ chế đọc AB#, cập nhật State qua REST trong `azure-pipelines.yml`.
- ✅ **Đã kiểm chứng trực tiếp trên Azure DevOps** (project `BAO_CAO`, lệnh `az boards query`):
  - Có **39 Work Items**: Feature, User Story, Test Plan, Test Suite, Test Case.
  - Work Item mẫu có trạng thái thật:
    - `#34 Microsoft Entra ID` (User Story) → **Resolved**
    - `#33 Key Vault` → **Resolved**
    - `#20 Azure DevOps Organizations` → **Resolved**
    - `#31 Front Door (Standard)` → **Resolved**
    - `#19 Mây 5 - DevOps & Security` (Feature) → **New**
    - `#61 TripTo - System Testing` (Test Plan) → **Active**
    - `#62 TripTo - System Testing` (Test Suite) → **In Progress**
- ⚠️ Các Work Item đang ở **New** (như `#23 Azure Lighthouse`, `#35 Azure Maps`, `#55 Azure Monitor`) là việc **chưa thực hiện** — dùng để chứng minh backlog, không phải đã làm.

## 💰 CHI PHÍ & LƯU Ý PHẢN BIỆN
- **Chi phí**: Azure Boards miễn phí trong Azure DevOps (5 người dùng basic free).
- **Phản biện**: *"Sao cần Boards khi đã có GitHub Issues?"* → Boards nằm cùng hệ sinh thái Azure DevOps với Pipelines + Service Connection, tự đồng bộ trạng thái Work Item với pipeline; GitHub Issues không gắn sẵn được với Azure Pipelines endpoint.

---

# 🔢 DỊCH VỤ 2 — AZURE PIPELINES

## 🧠 Ý NGHĨA CỦA DỊCH VỤ
Azure Pipelines là hệ thống **CI/CD của Azure DevOps** (org `DuAnNhom2`, project `BAO_CAO`): đọc
file YAML, chạy trên agent (ubuntu-latest), build/test/package/deploy. Pipeline này vừa **validate
code PHP vừa deploy web lên App Service**, vừa **tự cập nhật Work Item** (liên kết Azure Boards).

## 🎯 VAI TRÒ TRONG HỆ THỐNG
```
Push commit (main / feature/*)
        ▼
Azure Pipelines (azure-pipelines.yml, agent ubuntu-latest)
        ├─ 1..8: build & validate (checkout, PHP, composer, SQL, archive)
        ├─ 9..10: đóng gói + publish artifact Website.zip
        └─ 11: Deploy AzureWebApp → bao-cao-nhom2-web (appSettings từ variable group)
                   │
                   └─ 3 & 13: cập nhật Azure Boards (AB# → Active/Resolved)
```

## 🛠️ CÁC BƯỚC TẠO TRÊN AZURE
1. Vào DevOps `DuAnNhom2` → project `BAO_CAO` → **Pipelines** → **Create Pipeline**.
2. Chọn nguồn **Azure Repos Git** → chọn repo `BAO_CAO`.
3. Chọn **Existing Azure Pipelines YAML file** → đường dẫn `azure-pipelines.yml`.
4. Trong **Project Settings → Service connections** tạo connection `BAO_CAO_DEPLOY` (SPN Azure Resource Manager).
5. Tạo **Variable group** `TRIPTO-CONFIG` chứa: `PAT`, `APP_SERVICE_NAME`, `APP_ENV`, `API_BASE_URL`.
6. Gắn biến PAT (secret) vào queue-based env trong step: `env: { PAT: $(PAT) }`.

## ⚙️ CẤU HÌNH SAU KHI TẠO
- `trigger`: nhánh `main` + `feature/*`.
- `pool.vmImage`: `ubuntu-latest`.
- `variables.group`: `TRIPTO-CONFIG`.
- Task deploy: `AzureWebApp@1` — `azureSubscription: 'BAO_CAO_DEPLOY'`, `appType: 'webAppLinux'`, `package: Website.zip`, `appSettings` đẩy `APP_ENV` + `API_BASE_URL` vào App Service.

## 💻 TÍCH HỢP VÀO CODE
File `azure-pipelines.yml` (13 step):
| Step | Việc | Task/Lệnh |
|------|------|-----------|
| 1 | Checkout full lịch sử | `checkout: self` + `fetchDepth: 0` |
| 2 | Lấy Work Item ID | `grep -oE 'AB#[0-9]+'` |
| 3 | Set Work Item Active | REST `curl -X PATCH` + PAT |
| 4–5 | Hiển thị structure, PHP version | `pwd; ls -R` / `php -v` |
| 6 | Validate PHP | `find . -name "*.php" -exec php -l {} \;` |
| 7 | Cài Composer | `composer install --no-dev` |
| 8 | Tìm file SQL | `find . -name "*.sql"` |
| 9–10 | Đóng gói + publish artifact | `ArchiveFiles@2` + `PublishBuildArtifacts@1` |
| 11 | Deploy lên App Service | `AzureWebApp@1` |
| 12 | In thông tin deploy | echo URL `https://$(APP_SERVICE_NAME).azurewebsites.net` |
| 13 | Set Work Item Resolved (khi thành công) | REST `curl -X PATCH` |

## 🧪 CÁCH KIỂM THỬ THỰC TẾ
1. Push lên `main` → vào Pipelines → thấy run mới nằm trong queue.
2. Mở từng step xem log: PHP do `php -l` không lỗi, artifact `Website` có `Website.zip`.
3. Sau deploy, mở `https://bao-cao-nhom2-web.azurewebsites.net` → web chạy.
4. Kiểm tra App Settings trong Portal App Service có `APP_ENV`, `API_BASE_URL`.
5. Kiểm tra Work Item đã ở trạng thái Resolved.

## 📊 KẾT QUẢ ĐẠT ĐƯỢC & TRẠNG THÁI
- ✅ **Có file pipeline hoàn chỉnh**, đủ 13 step, kết nối Boards + deploy App Service.
- ✅ **Đã kiểm chứng run thật trên Azure DevOps** (pipeline `HTran2005.DU_AN_NHOM2`, pipelineId 2, lệnh `az pipelines runs list`):
  - **10 run gần nhất đều `succeeded`** (hoàn tất từ 02:09 đến 18:26 UTC ngày 12/08/2026) — deploy lên `bao-cao-nhom2-web` thành công liên tục.
- ⚠️ Nên chụp screenshot **Runs + Artifacts** từ DevOps để gắn vào Word (tôi đã xác nhận run tồn tại qua API).

## 💰 CHI PHÍ & LƯU Ý PHẢN BIỆN
- **Chi phí**: 1.800 phút free/tháng (Microsoft-hosted) — đồ án dùng rất ít.
- **Phản biện**: *"Sao không dùng GitHub Actions?"* → Nhóm **chọn Azure Pipelines làm CI/CD duy nhất** vì gắn chặt hệ sinh thái Azure DevOps (Boards tự đồng bộ Work Item, Service Connection, variable group), hỗ trợ task `AzureWebApp@1` deploy kèm `appSettings`. GitHub Actions đã được **loại bỏ** để tránh song song 2 hệ thống CI/CD.

---

# 🔢 DỊCH VỤ 3 — AZURE LOAD TESTING

## 🧠 Ý NGHĨA CỦA DỊCH VỤ
Azure Load Testing là dịch vụ **kiểm thử tải (load test)** theo mô hình managed của Azure: tạo
tập kịch bản (JMeter/URL test) với mô phỏng nhiều người dùng ảo (VUs), chạy từ cloud, đo latency, throughput,
đưa **App Metrics** vào bài test để xem tác động lên ứng dụng — kiểm tra web có chịu nổi hay không.

## 🎯 VAI TRÒ TRONG HỆ THỐNG
```
[Kiểm thử viên] tạo kịch bản URL test (TRANGCHU.html, API đặt tour)
        ▼
Azure Load Testing (mô phỏng tại max throughput)
        ▼
Test engine ──┼──► web TripTo (App Service bao-cao-nhom2-web)
              └──► Metrics (Response Time, Errors) → báo cáo
```

## 🛠️ CÁC BƯỚC TẠO TRÊN AZURE (đã triển khai thực tế)
1. Portal → tìm **Azure Load Testing** → **Create** → tên `tripto-load-testing`, region **southeastasia**, tạo thành công ngày **12/08/2026** (`provisioningState: Succeeded`).
2. Vào resource → **Tests** → **Create test** → chọn kiểu **URL test** (không cần file `.jmx`) → đặt tên `tripto-web-load-test` → URL đích `https://bao-cao-nhom2-web.azurewebsites.net/frontend/user/TRANGCHU.html`.
3. Định nghĩa **Load parameters**: số VUs, thời lượng chạy, tốc độ ramp-up từ từ.
4. Bấm **Run** → chọn engine (Single Test) → hệ thống cấp phát agent chạy bài test.
5. Mở **Test results** để xem statistics (requests/s, error %, response time percentile).

## ⚙️ CẤU HÌNH SAU KHI TẠO (đã thực hiện)
- **Test Run thực tế**: `TestRun_8/12/2026_1:04:27 PM` — trạng thái **DONE**.
- Thông số: chạy **~5 phút**, mô phỏng lên tới **~9 virtual users**, tổng **1.67 virtual user hours**.
- Được tạo bởi tài khoản `hhd211105@gmail.com` (chính chủ đồ án), hoàn tất lúc `2026-08-12T06:09:56Z`.
- Có **Portal URL** báo cáo kết quả để mở xem chi tiết từng métric.
- App Service chạy plan **S1 (Standard)** với 1 instance → giữ VUs thấp để không làm web nghẽn.

## 💻 TÍCH HỢP VÀO CODE
- Dùng kiểu **URL test** nên không cần file `.jmx` trong repo — chỉ định URL web TripTo làm đích.
- Bài test đo trực tiếp từ cloud lên App Service → có thể xem **App component metrics** (CPU, memory, HTTP 5xx) nếu gắn thêm tài nguyên.

## 🧪 CÁCH KIỂM THỬ THỰC TẾ (đã chạy)
1. Tạo test → bấm Run.
2. Chờ 5 phút đến khi test chuyển sang trạng thái **DONE**.
3. Mở tab **Result** → xem: số request thành công, response time, error rate.
4. Đối chiếu tài nguyên S1 — giải thích vì sao web có thể chậm ở request đầu (warmup).

## 📊 KẾT QUẢ ĐẠT ĐƯỢC & TRẠNG THÁI
- ✅ **Đã triển khai & chạy thành công**: resource `tripto-load-testing` tồn tại; có ít nhất **1 Test Run hoàn tất (DONE)** — bằng chứng từ `az load test list`, `az load test-run list`.
- 🔗 Portal URL báo cáo: mở từ Portal → resource → **Test runs** → bấm vào run để xem biểu đồ response time, throughput, error rate.
- ⚠️ Nên chụp screenshot màn hình **Test results** để gắn vào Word làm bằng chứng.

## 💰 CHI PHÍ & LƯU Ý PHẢN BIỆN
- **Chi phí**: Azure for Students cần xem hạn mức load testing; test 5 phút ~2 virtual user hours là **rất nhỏ, nằm trong budget**.
- **Lưu ý phản biện**: load test lên web dễ làm nghẽn → nên chọn giờ thấp điểm và giữ **VUs thấp**; công nhận giới hạn của hạ tầng khi test thay vì phủ nhận.

---

# 🔢 DỊCH VỤ 4 — AZURE APP CONFIGURATION

## 🧠 Ý NGHĨA CỦA DỊCH VỤ
Azure App Configuration là dịch vụ **quản lý cấu hình tập trung** (key-value store + feature flags):
lưu chuỗi kết nối, API key, cấu hình môi trường (dev/staging/prod) ở **một nơi**, ứng dụng đọc
động, **đổi cấu hình không cần redeploy** — thay thế cho việc nhúng cấu hình cứng trong code.

## 🎯 VAI TRÒ TRONG HỆ THỐNG
```
[App Configuration store]  (key: DB_HOST, DB_PASS, API_BASE_URL, REDIS_*...)
        ▲        │ read (qua App Service)
        │        ▼
[Backend PHP tripto trên App Service]   ← app settings trỏ về store
```

## 🛠️ CÁC BƯỚC TẠO TRÊN AZURE (đã triển khai thực tế)
1. Portal → **Azure App Configuration** → **Create** → tên `tripto-appconfig`, region **southeastasia**, pricing tier **Free** — tạo thành công ngày **02/08/2026**.
2. Mở store (endpoint `https://tripto-appconfig.azconfig.io`) → menu **Configuration explorer** → **Create** thêm từng key-value (dưới đây).
3. Mục **Feature manager** → tạo feature flag **`LOGIN_ENABLED`** (đang **enabled**).
4. Gắn store vào App Service: App Service → **Configuration** → app settings dạng `@Microsoft.AppConfiguration(Endpoint=...;Key=...)`.

## ⚙️ CẤU HÌNH SAU KHI TẠO (đã thực hiện)
- Pricing: **Free tier** — vừa đủ quy mô đồ án, không phát sinh chi phí.
- **25 key-value** đã nhập, phân theo nhóm rõ ràng:

| Nhóm | Key | Giá trị mẫu |
|------|-----|-------------|
| App | `APP_NAME`, `APP_ENV`, `APP_DEBUG` | `Tripto`, `production`, `false` |
| Database | `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`, `DB_PORT` | `tripto-mysql-db.mysql.database.azure.com`, `nhom2`, `tripto@123`, `tripto_db`, `3306` |
| Redis | `REDIS_HOST`, `REDIS_PASSWORD`, `REDIS_PORT`, `REDIS_FAVORITE_TTL`, `REDIS_FAVORITE_FLUSH_SECONDS` | `tripto-redis.southeastasia.redis.azure.net`, ... `600`, `10` |
| API | `API_BASE_URL` | `https://tripto-api-management.azure-api.net` |
| Event Grid | `EVENTGRID_LOGIN_TOPIC_ENDPOINT`, `EVENTGRID_LOGIN_TOPIC_KEY` | `https://tripto-login-topic...eventgrid.azure.net/api/events`, `<key>` |
| Nhân hệ thống | `Service:Machine1:AppUrl`, `Service:Machine1:FrontDoorUrl`, `Service:Machine2:ApiManagementUrl`, `Service:Machine3:MySqlHost`, `Service:Machine3:StorageUrl`, `Service:Machine4:LogAnalytics`, `Service:Machine4:Monitor` | URL/cấu hình từng máy trong kiến trúc |
| Web | `WEBSITE_ENABLE_SYNC_UPDATE_SITE` | `true` |
| Feature flag | `.appconfig.featureflag/LOGIN_ENABLED` | `{"id":"LOGIN_ENABLED","enabled":true,...}` |

## 💻 TÍCH HỢP VÀO CODE
- Backend đọc cấu hình từ các key trên thay vì nhúng cứng: `DB_*`, `REDIS_*`, `API_BASE_URL` nằm trong store → đổi giá trị ở **một nơi**, ứng dụng đọc lại giá trị mới **không cần redeploy**.
- Trên App Service, các app settings đã **trỏ trực tiếp về store**: `DB_HOST`, `DB_USER`, `DB_PASS`, `REDIS_HOST`, `REDIS_PASSWORD`, `REDIS_PORT` đều có dạng `@Microsoft.AppConfiguration(Endpoint=https://tripto-appconfig.azconfig.io;Key=...)` (xác minh bằng `az webapp config appsettings list`).
- Feature flag `LOGIN_ENABLED` dùng để bật/tắt chức năng đăng nhập mà không sửa code.
- Nguồn xác thực: store dùng **Azure AD** (`disableLocalAuth: true`), cấu hình qua CLI `az appconfig kv list --name tripto-appconfig --auth-mode login`.

## 🧪 CÁCH KIỂM THỬ THỰC TẾ (đã làm)
1. Chạy `az appconfig kv list` → liệt kê đủ **25 key-value** (bằng chứng lấy từ Azure CLI).
2. Thay đổi giá trị 1 key (VD: bật/tắt `LOGIN_ENABLED`) → ứng dụng đọc lại giá trị mới **không cần build lại**.
3. Mở App Service → **Configuration** → thấy các app settings `@Microsoft.AppConfiguration(...)` đang tham chiếu store.
4. Mở Portal → `tripto-appconfig` → **Configuration explorer** → thấy từng key, label, thời gian sửa cuối (last modified).

## 📊 KẾT QUẢ ĐẠT ĐƯỢC & TRẠNG THÁI
- ✅ **Đã triển khai và có dữ liệu thật**: store `tripto-appconfig` tồn tại (tier free), chứa **25 key-value** + **feature flag** `LOGIN_ENABLED`, các key được cập nhật liên tục đến **12/08/2026**.
- ✅ **Tích hợp thật với App Service**: các app settings của `bao-cao-nhom2-web` tham chiếu `@Microsoft.AppConfiguration(...)` — chứng minh web thực sự đọc cấu hình từ service này.
- ✅ Bằng chứng: `az appconfig show` + `az appconfig kv list` + `az webapp config appsettings list`.
- ⚠️ Nên chụp screenshot **Configuration explorer** để gắn vào Word.

## 💰 CHI PHÍ & LƯU Ý PHẢN BIỆN
- **Chi phí**: Free tier đủ dùng — **không phát sinh chi phí**.
- **Lưu ý phản biện**: nếu giảng viên hỏi "dùng env vars có rẻ hơn không?" → trả lời: nhóm **đã nâng cấp từ env vars/variable group lên App Configuration** — một nơi quản lý cấu hình tập trung, đổi cấu hình không cần redeploy; env vars chỉ phù hợp đồ án 1 máy nhỏ. Bằng chứng: app settings trên App Service trỏ thẳng về store.

---

# 🔢 DỊCH VỤ 5 — AZURE APP SERVICE

## 🧠 Ý NGHĨA CỦA DỊCH VỤ
Azure App Service là **PaaS của Azure để host web/API** (PHP, .NET, Node, Python...): tự quản lý
system OS, vá lỗi, HTTPS, scale. Trong đồ án, App Service là nơi chạy **web TripTo
(`bao-cao-nhom2-web`)** — là **đích đến của Azure Pipelines** (deploy ảnh trên CI/CD).

## 🎯 VAI TRÒ TRONG HỆ THỐNG
```
Azure Pipelines (build Website.zip) ──deploy──► App Service bao-cao-nhom2-web (Linux, PHP 8.3)
                                                          │
                    app settings ──► App Configuration + Key Vault (DB/REDIS/KEY)
                                                          │
                        host: tripto.duckdns.org / Traffic Manager / Azure Web Apps
```

## 🛠️ CÁC BƯỚC TẠO TRÊN AZURE
1. Portal → **App Services** → **Create** → tên `bao-cao-nhom2-web`, runtime stack **PHP 8.3**, OS **Linux**, region **southeastasia**.
2. Chọn **App Service plan** `ASP-DUANNHOM2RG-bd63` (tier **S1 Standard**, 1 instance).
3. Hosting: gắn custom domain `www.tripto.duckdns.org`, bật **HTTPS only**.
4. Đưa code lên bằng deploy pipeline (hoặc zip deploy) — App Service tự nhận và chạy.

## ⚙️ CẤU HÌNH SAU KHI TẠO (đã thực hiện)
- **Tên**: `bao-cao-nhom2-web` — trạng thái **Running**, `httpsOnly: true`.
- **Runtime**: `PHP|8.3`, App Service plan **S1 (Standard)**, 1 instance, Linux.
- **Host name**: `bao-cao-nhom2-web-...azurewebsites.net` + `www.tripto.duckdns.org` + `bao-cao-nhom2-tm.trafficmanager.net`.
- **App settings** — kết hợp bảo mật hạ tầng:
  - Trực tiếp: `APP_ENV=production`, `API_BASE_URL=https://tripto-api-management.azure-api.net/tripto/`, `WEBSITE_ENABLE_SYNC_UPDATE_SITE=true`, `EVENTGRID_LOGIN_TOPIC_*`, `AZURE_STORAGE_ACCOUNT=sttriptobackup`.
  - Bí mật qua **Key Vault** (`@Microsoft.KeyVault`): `AZURE_STORAGE_ACCOUNT_KEY`, `MAPS_KEY`.
  - Cấu hình DB/Redis qua **App Configuration** (`@Microsoft.AppConfiguration`): `DB_HOST`, `DB_USER`, `DB_PASS`, `REDIS_*`.
- **Logging**: bật Diagnostic logs (application logs Error, detailed error messages, failed request tracing, HTTP logs).
- **Managed Identity**: `SystemAssigned` đã kích hoạt (bảo mật để đọc Key Vault không cần key).

## 💻 TÍCH HỢP VÀO CODE
- Pipeline `AzureWebApp@1` đẩy `Website.zip` vào web; `appSettings` được inject từ variable group `TRIPTO-CONFIG`.
- Backend PHP (`backend/config.php`) đọc các biến môi trường do App Service cấp để kết nối MySQL, Redis, Storage, Event Grid.
- App Service đóng vai trò **điểm kết nối các DevOps service**: nhận nguồn từ Pipelines, đọc cấu hình từ App Configuration, lấy mật khẩu từ Key Vault.

## 🧪 CÁCH KIỂM THỬ THỰC TẾ
1. Mở `https://bao-cao-nhom2-web.azurewebsites.net` → web TripTo hiển thị.
2. Vào Portal → `bao-cao-nhom2-web` → **Configuration** → kiểm tra các app settings `@Microsoft.AppConfiguration`, `@Microsoft.KeyVault`.
3. Vào **Diagnostic logs** → xác nhận đã bật.
4. Vào **Identity** → xác nhận SystemAssigned.
5. Push code lên `main` → pipeline chạy → web tự cập nhật phiên bản mới.

## 📊 KẾT QUẢ ĐẠT ĐƯỢC & TRẠNG THÁI
- ✅ **Web đang chạy thật trên App Service** (`bao-cao-nhom2-web`, Running, HTTPS only).
- ✅ **Tích hợp sâu với DevOps toolchain**: nhận deploy từ Pipelines; đọc cấu hình từ App Configuration; lấy bí mật từ Key Vault; có Managed Identity + Diagnostic logs.
- ⚠️ Nên chụp screenshot **Overview + Configuration + Identity** của App Service để gắn vào Word.

## 💰 CHI PHÍ & LƯU Ý PHẢN BIỆN
- **Chi phí**: plan **S1** tính theo giờ — chi phí nhỏ, phù hợp đồ án; có thể hạ về plan free nếu muốn tiết kiệm (giới hạn tài nguyên, không scale).
- **Lưu ý phản biện**: *"Sao không host web trên VPS rẻ hơn?"* → App Service là PaaS: tự vá OS, tự TLS, auto-scale, gắn chặt Azure DevOps (deploy bằng `AzureWebApp@1`); VPS rẻ hơn nhưng phải tự quản lý mọi thứ. *"App Service có phải service DevOps không?"* → đây là **môi trường chạy** (runtime) để CI/CD "đích đến" — không thể thiếu trong chuỗi DevOps.

---

## ✅ CHECKLIST TRƯỚC KHI NỘP BÁO CÁO

- [ ] Azure Boards: chụp screenshot **Backlog (39 Work Items)** + chi tiết Work Item #34 → Resolved
- [ ] Azure Pipelines: chụp screenshot **Runs** (10 run succeeded) + tab Artifacts
- [ ] Azure Load Testing: chụp màn hình **Test results** (`TestRun_8/12/2026_1:04:27 PM`, DONE)
- [ ] Azure App Configuration: chụp **Configuration explorer** với 25 key-value + feature flag `LOGIN_ENABLED`; chụp app settings `@Microsoft.AppConfiguration` trên App Service
- [ ] Azure App Service: chụp **Overview + Configuration + Identity** của `bao-cao-nhom2-web`

> 🔎 **Trạng thái trung thực:** Cả **5 dịch vụ đều đã triển khai và được kiểm chứng bằng lệnh CLI/Azure:**
> Azure Boards (**39 Work Items**, mẫu #34/#33/#20 → Resolved), Azure Pipelines (**10 run succeeded** deploy `bao-cao-nhom2-web`), Azure Load Testing (`tripto-load-testing` — 1 TestRun DONE), Azure App Configuration (`tripto-appconfig` — 25 key-value + feature flag, app settings trỏ về store), Azure App Service (`bao-cao-nhom2-web` — Running, PHP 8.3, HTTPS, tích hợp Key Vault).
> 🔻 **GitHub Actions đã loại bỏ** khỏi báo cáo (dựa vào Azure Pipelines làm CI/CD chính); các workflow trong `.github/workflows/` vẫn còn trong repo nhưng không dùng để chứng minh.