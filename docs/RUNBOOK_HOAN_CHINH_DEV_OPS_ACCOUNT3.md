# 🚀 RUNBOOK HOÀN CHỈNH — LIÊN KẾT TOÀN BỘ DỊCH VỤ LÊN AZURE DEVOPS
## Bàn giao cho: **DevOps (Account 3 — DevOps & Security)** · Máy: máy DevOps

> **Mục đích:** Thực hiện xong việc gom toàn bộ dịch vụ Azure của **3 account** (ACC1 Frontend & Backend · ACC2 Database & Monitoring · ACC3 DevOps & Security) vào **Azure DevOps** (org `DuAnNhom2`, project `BAO_CAO`) và tạo ra **báo cáo tổng hợp dịch vụ** để đưa vào đồ án.
>
> ⏱️ **Thời gian dự kiến: 60–90 phút** · 🛠️ Thực hiện trên máy Windows có PowerShell.

---

## 📋 PHẦN BÀN GIAO (DevOps cần chuẩn bị trước khi bắt đầu)

| Thứ | Cần có | Trạng thái |
|-----|--------|-----------|
| 1 | **Subscription ID của ACC1** (Frontend & Backend) | ✅ Đã có: `bbad92f7-b7ef-4fa7-b3ef-61c200f5802e` (đã điền vào `parameters.json`) |
| 2 | **Subscription ID của ACC2** (Database & Monitoring) | ✅ Đã có: `42e7a0ff-6e78-4530-a021-bf133c012ba2` (đã điền vào `parameters.json`) |
| 3 | **Subscription ID của ACC3** (DevOps & Security) | ⚠️ **Để trống** — DevOps thường không có Azure subscription (tài nguyên DevOps nằm trong Azure DevOps). Báo cáo sẽ gồm ACC1 + ACC2 |
| 4 | **PAT Azure DevOps** (scope: Service Connections Read&manage + Build Read&execute + **Project and Team Read**) | dev.azure.com → User settings → Personal Access Tokens (chi tiết: Phụ lục A) | ☐ |
| 5 | Azure CLI (`az`) | https://aka.ms/installazurecliwindows | ☐ |
| 6 | `jq` + `bash` (Git Bash/WSL) | `choco install jq` / `winget install jq` | ☐ |

> 📌 **Quyền tối thiểu:** Tài khoản Azure DevOps cần quyền tạo Service Connection (Project Collection Administrator hoặc đã được cấp). Tài khoản Azure cần quyền tạo App Registration (Application Administrator) để script tạo SPN.

### 📨 TIN NHẮN BÀN GIAO (copy gửi cho DevOps)

```
Chào bạn,
Bên mình đã chuẩn bị xong toàn bộ phần liên kết dịch vụ lên Azure DevOps cho Account 3 (DevOps & Security).
Bạn chỉ cần làm theo đúng runbook dưới đây:

📄 Runbook: docs/RUNBOOK_HOAN_CHINH_DEV_OPS_ACCOUNT3.md
📁 File: infrastructure/account3/ (đã commit sẵn trên nhánh main)

Việc cần làm:
 1. git pull (repo DU_AN_NHOM2)
 2. Chạy kiểm tra: .\infrastructure\account3\preflight-check.ps1 → xử lý các mục ❌
 3. Tạo PAT theo Phụ lục A (scope: Service connections Read&manage + Build Read&execute + Project&Team Read)
 4. Chạy: .\infrastructure\account3\create-service-connections.ps1 -Pat "<PAT>"
 5. Verify Service Connection 'Azure-TripTo' xanh trên DevOps Portal
 6. Import + chạy pipeline: infrastructure/account3/azure-pipelines-report.yml → lấy artifact BaoCaoToanBoDichVu/REPORT.md
 7. Chạy local: .\infrastructure\account3\collect-resources.ps1 → reports/REPORT.md
 8. Chụp 7 bằng chứng (Bước 7) + cập nhật PROGRESS.md + commit

Lưu ý: ACC3 (DevOps & Security) không có Azure subscription → báo cáo gồm ACC1 + ACC2;
bằng chứng của ACC3 = pipeline + service connection đã chạy.
Gặp lỗi gì xem bảng Xử lý sự cố cuối runbook, hoặc liên hệ mình.
```

---

### 📌 CÁCH LẤY SUBSCRIPTION ID (gửi cho từng bạn sở hữu account)

> Máy DevOps chỉ nhìn thấy subscription của **ACC2** (`42e7a0ff-...`). **ACC1 và ACC3 là tài khoản Azure của thành viên khác** — phải lấy từ họ. Gửi cho bạn ACC1 (và bạn ACC3 nếu có) đoạn sau:

```
1. Mở Command Prompt / PowerShell trên máy bạn:
   az login
   az account list -o table
   → Copy cột SubscriptionId (dạng 12345678-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
   → Gửi cho DevOps (Account 3)

(Cách khác: Azure Portal → ô tìm kiếm gõ "Subscriptions" → copy ID)
```

> ⚠️ **ACC3 (DevOps & Security) đặc biệt:** nếu bạn DevOps **không có Azure subscription riêng** (tài nguyên DevOps như org, pipeline, service connection nằm trong Azure DevOps chứ KHÔNG phải tài nguyên Azure) → **để trống** subscriptionId của ACC3, không cần lấy. Báo cáo sẽ gồm ACC1 + ACC2; bằng chứng ACC3 ghi nhận qua pipeline/connection (xem Bước 6).

---

## BƯỚC 0 — KIỂM TRA SẴN SÀNG (PREFLIGHT) · ~5 phút

Mở **PowerShell** tại thư mục đã clone repo (đã `git pull` lấy code mới nhất) và chạy:

```powershell
cd <đường dẫn thư mục DU_AN_NHOM2 trên máy bạn>
.\infrastructure\account3\preflight-check.ps1
```

**Kết quả mong đợi:** Bảng kiểm tra 5–6 mục, tất cả ✅.
Nếu có mục ❌ → làm theo dòng gợi ý bên dưới mục đó, rồi chạy lại cho đến khi toàn bộ ✅.

**Các lệnh hỗ trợ nhanh khi bị thiếu:**
```powershell
# Cài jq (1 trong 2)
choco install jq -y        # hoặc
winget install jq

# Kiểm tra az đã đăng nhập chưa
az account show

# Xem danh sách subscription (lấy subscriptionId còn thiếu)
az account list -o table
```

---

## BƯỚC 1 — KIỂM TRA `parameters.json` (đã điền sẵn) · ~2 phút

File `infrastructure/account3/parameters.json` **đã được điền sẵn** — chỉ cần MỞ RA kiểm tra, không cần sửa gì:

```json
{
  "organization": "DuAnNhom2",
  "project": "BAO_CAO",
  "serviceConnectionName": "Azure-TripTo",
  "servicePrincipalName": "sp-tripto-devops-report",
  "accounts": [
    {
      "key": "ACC1",
      "name": "ACCOUNT_1",
      "label": "Frontend & Backend",
      "subscriptionId": "bbad92f7-b7ef-4fa7-b3ef-61c200f5802e",
      "subscriptionName": ""
    },
    {
      "key": "ACC2",
      "name": "ACCOUNT_2",
      "label": "Database & Monitoring",
      "subscriptionId": "42e7a0ff-6e78-4530-a021-bf133c012ba2",
      "subscriptionName": ""
    },
    {
      "key": "ACC3",
      "name": "ACCOUNT_3",
      "label": "DevOps & Security",
      "subscriptionId": "",
      "subscriptionName": ""
    }
  ]
}
```

> 💡 **ACC1 + ACC2 đã có subscriptionId ✅. ACC3 để TRỐNG là đúng thiết kế** — DevOps & Security thường không có Azure subscription; script sẽ bỏ qua ACC3 và báo cáo gồm ACC1 + ACC2 (xem Bước 6). KHÔNG sửa gì trong file này.

---

## BƯỚC 2 — TẠO SERVICE CONNECTION LÊN AZURE DEVOPS · ~10 phút

> 🔑 **Quan trọng — đăng nhập đủ account:** Script truy vấn subscription theo **login hiện tại**. ACC1 và ACC2 có thể nằm ở **2 tenant khác nhau** → phải `az login` bằng **từng tài khoản sở hữu** (ACC1 + ACC2) rồi `az account set` giữa các tenant. Nếu bỏ qua, script sẽ bỏ qua account không truy cập được.

Trong PowerShell (đã đăng nhập Azure), chạy:

```powershell
az login                                    # nếu chưa đăng nhập
.\infrastructure\account3\create-service-connections.ps1 -Pat "PASTE_PAT_TAI_DAY"
```

**Script sẽ tự động:**
1. ✅ Kiểm tra đăng nhập Azure
2. ✅ Liệt kê các subscription hợp lệ (in `✓ ACC1 | tên-sub | tenant ...`)
3. ✅ Tạo SPN `sp-tripto-devops-report` + cấp quyền **Reader** cho từng subscription
4. ✅ Tạo Service Connection **`Azure-TripTo`** trên org `DuAnNhom2` / project `BAO_CAO`

**Kết quả mong đợi (cuối màn hình):**
```
══════════════════════════════════════════════
  ✅ HOÀN TẤT - LIÊN KẾT AZURE DEVOPS
══════════════════════════════════════════════
  Org       : DuAnNhom2
  Project   : BAO_CAO
  Connection : Azure-TripTo  (subscription ...)
```

**⚠️ Nếu 1 account báo `khác tenant` hoặc `cấp quyền thất bại`:** Các account của bạn nằm ở **tenant Entra ID khác nhau**. Chuyển sang chế độ PerSubscription (1 connection mỗi account):

```powershell
.\infrastructure\account3\create-service-connections.ps1 -Mode PerSubscription -Pat "PASTE_PAT_TAI_DAY"
# Kết quả: Azure-TripTo-ACC1, Azure-TripTo-ACC2, Azure-TripTo-ACC3
# → Bước 4: import file azure-pipelines-report-multi.yml THAY VÌ bản mặc định
```

---

## BƯỚC 3 — XÁC MINH SERVICE CONNECTION TRÊN PORTAL · ~5 phút

1. Mở trình duyệt → `https://dev.azure.com/DuAnNhom2/BAO_CAO`
2. **Project Settings** (biểu tượng bánh răng góc trái dưới) → **Service connections**
3. Thấy connection **`Azure-TripTo`** trạng thái **xanh ✅**
4. Bấm vào → **Edit** → bấm **Verify** → thấy `Successfully verified` ✔️

> 🔴 **Connection đỏ?** Xem Bảng Xử lý sự cố ở cuối runbook (mục "Connection đỏ").

---

## BƯỚC 4 — TẠO VÀ CHẠY PIPELINE BÁO CÁO · ~15 phút

> 📌 **Nguồn repo:** Code đang nằm trên **GitHub** (`github.com/HTran2005/DU_AN_NHOM2`). Khi import pipeline, chọn nguồn **GitHub** (lần đầu sẽ được hỏi tạo GitHub service connection bằng GitHub PAT — chỉ cần quyền đọc repo). Nếu nhóm đã có sẵn repo trên **Azure Repos** thì chọn **Azure Repos Git**.

1. **Pipelines → New Pipeline**
2. Chọn nguồn: **GitHub** (hoặc **Azure Repos Git** nếu repo đã push lên Azure Repos) → chọn repo **`DU_AN_NHOM2`**
3. Chọn **Existing Azure Pipelines YAML file**
4. Đường dẫn: **`infrastructure/account3/azure-pipelines-report.yml`** → **Continue → Run**
5. Đợi build chạy xong (2–3 phút) → **trạng thái xanh ✓**

**Kiểm tra kết quả:**
- Mở build run → tab **Artifacts** → tải **`BaoCaoToanBoDichVu`** → file **`REPORT.md`**
- Mở file: thấy 3 phần — ① Tổng quan (số tài nguyên/account) · ② Chi tiết từng account · ③ Top loại dịch vụ

> 🔁 Pipeline để trigger `none` (chạy tay). Muốn báo cáo mới → Pipelines → chọn pipeline → **Run pipeline**.

---

## BƯỚC 5 — CHẠY BÁO CÁO LOCAL TRÊN MÁY DEV OPS · ~10 phút

Chạy trực tiếp trên máy (không cần mở portal):

```powershell
.\infrastructure\account3\collect-resources.ps1
```

**Kết quả mong đợi:**
```
  -- ACC1 (Frontend & Backend) --
  ✅ ACC1: 8 tài nguyên / 6 loại dịch vụ
  -- ACC2 (Database & Monitoring) --
  ✅ ACC2: 12 tài nguyên / 9 loại dịch vụ
  ...
══════════════════════════════════════════════
  ✅ BÁO CÁO ĐÃ TẠO: D:\DU_AN_NHOM2\reports\REPORT.md
══════════════════════════════════════════════
```

Mở `reports\REPORT.md` để xem báo cáo tổng hợp.

---

## BƯỚC 6 — KIỂM TRA CHẤT LƯỢNG BÁO CÁO · ~5 phút

Đối chiếu `REPORT.md` với danh mục **~30 dịch vụ** trong `docs/CAU_TRUC_BAO_CAO.md`:

| Kiểm tra | Mong đợi |
|----------|----------|
| ACC1 có App Service `tripto`, `tripto2`, Traffic Manager, Key Vault, Azure Maps...? | ☐ |
| ACC2 có MySQL `tripto-mysql-db`, Storage `sttriptobackup`, Redis, Function App, Log Analytics `law-tripto`, App Insights...? | ☐ |
| Tổng tài nguyên khớp xấp xỉ danh mục? | ☐ |
| Bảng Top loại dịch vụ hiển thị đúng (không bị xuống dòng lộn xộn)? | ☐ |

> 📌 **ACC3 (DevOps & Security)** thường không có Azure subscription nên không xuất hiện trong `REPORT.md`. Bằng chứng của ACC3 = chính **runbook này + pipeline đã chạy + Service Connection `Azure-TripTo` + các file `infrastructure/account3/*`** — chụp màn hình ở Bước 7.

---

## BƯỚC 7 — CHỤP BẰNG CHỨNG (CHO BÁO CÁO ĐỒ ÁN) · ~10 phút

Chụp màn hình và lưu vào thư mục `reports/evidence/`:

| # | Màn hình cần chụp | File gợi ý |
|---|-------------------|------------|
| 1 | Service Connection `Azure-TripTo` (trạng thái xanh) trên DevOps | `evidence/1-service-connection.png` |
| 2 | Pipeline báo cáo chạy **thành công** (run xanh) | `evidence/2-pipeline-success.png` |
| 3 | Artifact `BaoCaoToanBoDichVu` có `REPORT.md` | `evidence/3-artifact.png` |
| 4 | `REPORT.md` — Phần 1 Tổng quan | `evidence/4-report-overview.png` |
| 5 | `REPORT.md` — Phần 2 chi tiết ACC1 + ACC2 | `evidence/5-report-detail.png` |
| 6 | Màn hình PowerShell đã chạy `collect-resources.ps1` thành công | `evidence/6-local-collect.png` |
| 7 | SPN `sp-tripto-devops-report` + role Reader (tùy chọn) | `evidence/7-spn-reader.png` |

---

## BƯỚC 8 — COMMIT LÊN GIT · ~5 phút

```powershell
cd D:\DU_AN_NHOM2
# Commit LUÔN parameters.json: subscription ID là thông tin nội bộ (không phải secret),
# giúp DevOps pull về là chạy được ngay, không cần điền lại.
git add infrastructure/account3/ docs/RUNBOOK_HOAN_CHINH_DEV_OPS_ACCOUNT3.md docs/LIEN_KET_DEV_OPS_ACCOUNT3.md docs/CAU_TRUC_BAO_CAO.md
git commit -m "Account 3 DevOps: lien ket toan bo dich vu len Azure DevOps + runbook"
git push origin main
```

> ⚠️ **KHÔNG commit:** thư mục `reports/` (dữ liệu báo cáo local) và `.agnes/`. Nếu muốn loại trừ cả `parameters.json` (nội bộ) → dùng `git add infrastructure/account3/ ':!infrastructure/account3/parameters.json'` (subscription ID vẫn có trong bảng Bàn giao đầu runbook để DevOps tự điền).

---

## 📎 PHỤ LỤC A — TẠO PAT TỪNG CLICK (cần ở Bước 2)

1. Mở trình duyệt → `https://dev.azure.com/DuAnNhom2` → **đăng nhập** bằng tài khoản DevOps
2. Click **avatar** (hình đại diện) ở **góc trên bên phải** → chọn **Personal access tokens**
   (Menu xuất hiện ngay dưới avatar, mục *Security*)
3. Bấm nút **+ New Token**
4. Điền form **Create a new personal access token**:
   - **Name:** `tripto-account3-devops`
   - **Organization:** chọn **`DuAnNhom2`**
   - **Expiration:** chọn **90 days** (đủ cho kỳ đồ án; nếu org giới hạn thì lấy tối đa cho phép)
   - **Scopes:** chọn **Custom defined** → bấm **Show all scopes** → tích đúng 3 ô:
     - ☑ **Service connections** → **Read & manage** *(script cần để tạo `Azure-TripTo`)*
     - ☑ **Build** → **Read & execute** *(pipeline báo cáo cần)*
     - ☑ **Project and Team** → **Read** *(bắt buộc kèm để truy vấn project — chỉ đọc, an toàn)*
5. Bấm **Create**
6. ⚠️ **Copy token NGAY** — chỉ hiển thị **1 lần duy nhất**! Lưu vào nơi an toàn (không dán vào git/chat)
7. Dùng token:

```powershell
# Cách 1: truyền trực tiếp
.\infrastructure\account3\create-service-connections.ps1 -Pat "PASTE_TOKEN"

# Cách 2: đặt biến môi trường (an toàn hơn, không lộ trong lệnh)
$env:AZURE_DEVOPS_EXT_PAT = "PASTE_TOKEN"
.\infrastructure\account3\create-service-connections.ps1
```

> 🔒 **Bảo mật PAT:** token là chìa khóa — không commit, không gửi qua chat nhóm. Nếu nghi lộ, xóa ngay tại trang *Personal access tokens* và tạo cái mới.

---

## 🧯 ROLLBACK (khi cần hủy / làm lại từ đầu)

```powershell
# 1. Xóa Service Connection trên DevOps (Portal: Project Settings → Service connections → Delete)
# 2. Xóa SPN (tra appId theo tên rồi xóa — an toàn với mọi phiên bản az):
$appId = az ad sp list --display-name sp-tripto-devops-report --query "[0].appId" -o tsv
if ($appId) { az ad sp delete --id $appId }
# 3. (Tùy chọn) Xóa pipeline vừa import trên DevOps
# 4. Xóa dữ liệu local:
Remove-Item reports -Recurse -Force
```

---

## 🆘 BẢNG XỬ LÝ SỰ CỐ (TRA NHANH)

| Triệu chứng | Nguyên nhân | Xử lý |
|-------------|-------------|-------|
| `Tạo Service Connection thất bại: 401` | PAT thiếu scope | Tạo PAT mới, đủ **Service Connections (Read & manage)** |
| Connection **đỏ** trên Portal | SPN sai tenant / thiếu quyền | Chạy lại script với `-Force`; nếu khác tenant → `-Mode PerSubscription` |
| `Cấp role Reader thất bại` | Subscription khác tenant (chế độ Shared) | Dùng `-Mode PerSubscription` |
| `Tạo SPN thất bại` | Không có quyền tạo App Registration | Nhờ admin Entra cấp quyền (Application Administrator) |
| `Reset credential SPN thất bại` | Thiếu quyền hoặc SPN do người khác tạo | Nhờ admin, hoặc đổi tên SPN trong `parameters.json` rồi chạy lại |
| Pipeline lỗi `Không có file resources-*.json` | Không account nào có subscriptionId | Điền đủ ID vào `parameters.json` |
| Pipeline lỗi `az: command not found` | Agent thiếu az | ubuntu-latest có sẵn; nếu chạy self-hosted thì cài az |
| `REPORT.md` thiếu 1 account | Account bỏ qua (chưa có ID / SPN không có quyền) | Kiểm tra Bước 1 + chạy lại script |
| `jq: command not found` (chạy local) | jq chưa cài | `choco install jq` |

---

## ✅ CHECKLIST CUỐI CÙNG (TRƯỚC KHI BÁO CÁO HOÀN THÀNH)

- [ ] `preflight-check.ps1` → toàn bộ ✅
- [ ] `parameters.json` có subscriptionId (ACC2 đã có sẵn)
- [ ] `create-service-connections.ps1` chạy thành công → connection `Azure-TripTo` xanh
- [ ] Pipeline `azure-pipelines-report.yml` chạy thành công → artifact có `REPORT.md`
- [ ] `collect-resources.ps1` chạy local → `reports/REPORT.md`
- [ ] `REPORT.md` đối chiếu đủ dịch vụ ACC1 + ACC2
- [ ] Đã chụp 7 bằng chứng ở Bước 7
- [ ] Commit + push lên GitHub
- [ ] Báo cáo xong cho nhóm — cập nhật `infrastructure/account3/PROGRESS.md`

---

*Runbook này là tài liệu bàn giao chính thức cho Account 3 (DevOps & Security). Mọi thắc mắc kỹ thuật xem thêm `docs/LIEN_KET_DEV_OPS_ACCOUNT3.md`.*
