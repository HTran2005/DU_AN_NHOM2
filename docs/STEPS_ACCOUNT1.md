# Các bước đã thực hiện — Account 1 (Frontend & Security)

Thứ tự thao tác thực tế trên Portal Azure + Cloud Shell. Người thực hiện: `camlylv2021@gmail.com`. Resource Group: `Frontend-Dung`.

---

## DỊCH VỤ 1 — App Service `tripto` (máy chủ web chính)

1. Portal → **App Services** → **Create**.
2. Điền: Resource group `Frontend-Dung`, Name `tripto`, Runtime stack (PHP/Node theo code), Region **Southeast Asia**.
3. Pricing plan: **F1 Free** (tier miễn phí).
4. Chọn **Create** → đợi deploy hoàn tất.
5. Deploy code: **Deployment Center** bị bỏ (theo quyết định nhóm) → deploy thủ công bằng **zip qua Cloud Shell**.
6. Cấu hình biến môi trường (env vars) cho app: cài DB config → đọc từ `config.php` phía backend.
7. Kiểm tra: app chạy Online tại URL:
   `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net`

**Ghi nhận:** F1 Free làm app **ngủ đông** khi không truy cập → request đầu có thể timeout; không bind được custom domain.

---

## DỊCH VỤ 2 — Traffic Manager `tripto-tm` (failover / cân bằng tải)

### Bước chuẩn bị — tạo App Service dự phòng `tripto2`

1. Portal → **App Services** → **Create** (giống hệt `tripto`): Name `tripto2`, RG `Frontend-Dung`, **F1 Free**, cùng region.
2. Deploy code zip qua Cloud Shell, cấu hình env vars giống `tripto`.
3. Kiểm tra Online tại: `https://tripto2-e3g2epfdaahzaqaa.southeastasia-01.azurewebsites.net`

> 📝 Thứ tự tạo `tripto2` sau khi biết Traffic Manager cần 2 endpoint failover.

### Trước đó: Azure Front Door bị chặn

- Thử tạo **Azure Front Door** → lỗi `BadRequest` (subscription Azure for Students không cho) → **chuyển sang Traffic Manager**.

### Tạo Traffic Manager

1. Portal → **Traffic Manager profiles** → **Create**.
2. Name `tripto-tm`, RG `Frontend-Dung`, Routing method: **Priority** (dự phòng thủ công: chính → phụ).
3. **Create** → chờ profile Online.
4. Thêm endpoint `tripto-origin`:
   - Type: **External endpoint**
   - Target: `tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net`
   - Priority: **1**
5. Thêm endpoint `tripto2`:
   - Type: **External endpoint**
   - Target: `tripto2-e3g2epfdaahzaqaa.southeastasia-01.azurewebsites.net`
   - Priority: **2**
6. Cấu hình health monitor:
   - Ban đầu: HTTP port 80 → endpoint **Degraded** (vì app F1 chỉ phục vụ HTTPS) → **đổi sang HTTPS port 443, path `/`**.
   - Interval: 30s.
7. Kiểm tra lại Monitor: cả 2 endpoint đều **Online** ✅

### Kiểm chứng

- Browser: `https://tripto-tm.trafficmanager.net` → **404** (F1 Free chặn host lạ — đã biết, không phải lỗi).
- Kiểm chứng bằng `nslookup tripto-tm.trafficmanager.net` → trả IP hợp lệ.
- Trạng thái Traffic Manager profile: **Online**, 2 endpoint **Online** ✅

> 📝 Mẹo quan trọng: dùng **External endpoint**, không dùng **Azure endpoint** (Azure endpoint gây `Degraded`).

---

## DỊCH VỤ 3 — Key Vault `triptokv` (lưu mật khẩu / secret)

1. Portal → **Key Vaults** → **Create**.
2. Name `triptokv` (không dấu gạch giữa), RG `Frontend-Dung`, Region **Southeast Asia**, Pricing tier **Standard**.
3. Permission model: **Azure role-based access control (RBAC)** (không dùng Access policy cũ).
4. **Create**.
5. Gán quyền cho bản thân: **Access control (IAM)** → **Add role assignment** → role **Key Vault Secrets Officer** → chọn user `camlylv2021`.
6. Tạo secret đầu tiên:
   - **Secrets** → **Generate/Import** → Name `DB-PASS`, Value `tripto@123` → **Create** ✅
7. (Sau này) Secret thứ 2 `MAPS-KEY` được tạo bằng CLI (xem Dịch vụ 4).

> Key Vault lưu được: Secrets (password/API key/connection string), Keys (mã hóa RSA/EC/AES), Certificates (SSL).

---

## DỊCH VỤ 4 — Azure Maps `tripto-maps` (bản đồ)

### Thử qua Portal (thất bại)

1. Portal → **Azure Maps** → **Create**.
2. Name `tripto-maps`, RG `Frontend-Dung`, Pricing tier **Gen2 (G2)**.
3. Chọn Region theo dropdown → thử lần lượt 5 vùng:
   `(US) East US`, `(US) West US 2`, `(Europe) North Europe`, `(Europe) West Europe`, `(US) West Central US`
   → **tất cả đều báo lỗi** `RequestDisallowedByAzure` (policy region của subscription sinh viên).

### Thử qua Cloud Shell CLI (điều chỉnh)

4. Lệnh 1 — `southeastasia`:
   ```powershell
   az maps account create -g Frontend-Dung -n tripto-maps --sku G2 --location southeastasia
   ```
   → Lỗi `LocationNotAvailableForResourceType`: Azure Maps **không hỗ trợ** Southeast Asia; region khả dụng là
   `westcentralus, global, westus2, eastus, westeurope, northeurope`.

5. Lệnh 2 — `eastus`:
   ```powershell
   az maps account create -g Frontend-Dung -n tripto-maps --sku G2 --location eastus
   ```
   → Lỗi `RequestDisallowedByAzure`: policy subscription chặn cả region này.

6. Lệnh 3 — `global` (né policy region):
   ```powershell
   az maps account create -g Frontend-Dung -n tripto-maps --sku G2 --location global
   ```
   → Nhập `y` chấp nhận license → **TẠO THÀNH CÔNG** ✅
   - Kết quả: kind `Gen2`, sku `G2`, location `global`, provisioningState `Succeeded`.

7. Lấy subscription key:
   ```powershell
   az maps account keys list -g Frontend-Dung -n tripto-maps --query primaryKey -o tsv
   ```
   → Trả key: `<MAPS_KEY>`

8. Lưu key vào Key Vault (chú ý **bọc key trong nháy kép**, vì `<` là ký tự đặc biệt của PowerShell):
   ```powershell
   az keyvault secret set --vault-name triptokv --name MAPS-KEY --value "<MAPS_KEY>"
   ```
   → Thành công ✅ → secret `MAPS-KEY` có trong `triptokv`.

> ⚠️ Key đã lộ trong chat khi thao tác → đã **regenerate** key mới (Portal → Azure Maps → Keys).

### Nhúng Azure Maps vào trang chi tiết tour (chitiettour.html)

9. Regenerate key mới: Portal → Azure Maps → `tripto-maps` → **Authentication** → **Regenerate** Primary key.
   → Key mới: `<MAPS_KEY>` (lấy từ Portal, **không commit lên git**)

10. Sửa file `frontend/user/chitiettour.html` (thay iframe Google Maps bằng Azure Maps Web SDK), 3 chỗ:
    - **Trong `<head>`**: thêm thư viện SDK
      ```html
      <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css" type="text/css" />
      <script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
      ```
    - **Trong phần mô tả tour**: thay `<iframe ... google.com/maps ...>` bằng
      ```html
      <div id="tourMap" class="map-frame"></div>
      ```
    - **Trước `</body>`**: khởi tạo bản đồ với key mới + marker điểm đến
      ```html
      <script>
          var map = new atlas.Map('tourMap', {
              center: [107.1822, 20.9101],   // [kinh độ, vĩ độ] Vịnh Hạ Long
              zoom: 10,
              view: 'Auto',
              authOptions: {
                  authType: 'subscriptionKey',
                  subscriptionKey: window.MAPS_KEY
              }
          });
          map.events.add('ready', function () {
              map.markers.add(new atlas.HtmlMarker({
                  position: [107.1822, 20.9101],
                  text: 'Hạ Long'
              }));
          });
      </script>
      ```

> 🔐 **Bảo mật key:** GitHub chặn push khi phát hiện key Azure Maps trong code (`GH013 Push Protection`). Vì vậy key được đặt trong file `frontend/user/maps-config.js` (chứa `window.MAPS_KEY = "<MAPS_KEY>"`) — file này nằm trong `.gitignore` nên **không bao giờ được commit lên git**, nhưng vẫn nằm trong zip khi deploy nên web vẫn dùng được key bình thường.

11. Deploy lên App Service `tripto` qua Cloud Shell:
    ```powershell
    mkdir -p deploy/frontend/user
    cp chitiettour.html deploy/frontend/user/
    cd deploy
    zip -r ../tripto.zip frontend
    cd ..
    az webapp deploy --resource-group Frontend-Dung --name tripto --src-path tripto.zip --type zip
    ```

12. Kiểm chứng trên web thật:
    - Fetch lại trang: `curl -s https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net/frontend/user/chitiettour.html | grep -c atlas` → kết quả ≥ 1
    - Mở trang trên trình duyệt → phần "Mô tả tour" → khung **"Bản đồ điểm đến"** hiện bản đồ Azure Maps (góc dưới phải có chữ **Microsoft**, nút **Feedback**) ✅
    - Portal Azure Maps → `tripto-maps` → **Monitoring → Metrics** → metric **Usage** (Aggregation **Count**) → thấy số request tăng (vd **165 request**) → chứng minh web thật sự gọi Azure Maps ✅

---

## KẾT NỐI GITHUB ACTIONS CHO TRIPTO2 (để cả 2 app tự cập nhật khi push code)

> Mục đích: ban đầu chỉ `tripto` kết nối GitHub Actions. Để `tripto2` (bản dự phòng failover) cũng tự deploy cùng code khi push → cần kết nối Deployment Center cho tripto2.

1. **Bước 1 — Bật SCM Basic Auth cho tripto2** (bắt buộc, không thì lỗi "publish profile invalid"):
   - Portal → App Service **`tripto2`** → **Configuration** → tab **General settings**
   - Gạt **"SCM Basic Auth Publishing Credentials"** sang **On** → **Save** → chờ restart.

2. **Bước 2 — Vào Deployment Center**:
   - App Service `tripto2` → menu trái → **Deployment Center**
   - Nếu có kết nối cũ → **Disconnect** trước
   - Chọn **Source: GitHub** → **Authorize** (đăng nhập GitHub nếu hỏi)
   - Điền: **Organization** `HTran2005`, **Repository** `DU_AN_NHOM2`, **Branch** `main`

3. **Bước 3 — Chọn build provider**:
   - **Build provider**: **GitHub Actions**
   - **Runtime stack**: **PHP**
   - **Version**: **8.5**

4. **Bước 4 — Chọn Authentication type**:
   - Trong **Authentication settings** → chọn **Publish profile**
   - Subscription để mặc định (không chọn OIDC / user-assigned identity)

5. **Bước 5 — Save**:
   - Bấm **Save** → Azure tự động:
     - Tạo file `.github/workflows/main_tripto2.yml` trong repo GitHub
     - Tạo secret riêng cho tripto2 trên GitHub
     - Deploy lần đầu lên tripto2

6. **Bước 6 — Kiểm tra**:
   - GitHub → tab **Actions** → thấy **2 workflow**: `main_tripto.yml` (tripto) và `main_tripto2.yml` (tripto2)
   - Cả 2 đều **xanh ✅**
   - Kiểm chứng: sửa code → commit + push → cả 2 workflow cùng chạy → 2 app cùng cập nhật = thành công 🎉

> ⚠️ **Lưu ý bảo mật:** file `maps-config.js` (chứa key Azure Maps) không nằm trong git (bị gitignore) nên không được deploy qua GitHub Actions. Khi deploy mới lên tripto2, file này sẽ **không có trên tripto2** → bản đồ có thể trống. Cần cân nhắc giải pháp an toàn (đưa key vào App Setting / biến môi trường) nếu muốn bản đồ hoạt động trên cả 2 app.

---

## DNS ZONES — Tạo zone `tripto.vn` (zone trắng minh họa)

> **Bối cảnh:** chưa mua domain thật + App Service đang F1 (không bind custom domain được). Nên tạo **zone trắng** để chứng minh dịch vụ Azure DNS zones hoạt động. Để zone chạy thật cần: mua domain + trỏ NS + nâng tier B1+.

### Các bước tạo zone

1. **Mở trang tạo**: Portal → ô tìm kiếm → gõ **"DNS zones"** → chọn dịch vụ → bấm **+ Create**
2. **Điền thông tin**:
   - **Resource group**: `Frontend-Dung`
   - **Name**: `tripto.vn` (tên miền dự kiến)
   - **Resource group location**: để mặc định (Azure DNS global)
3. Bấm **Review + create** → **Create** → **Go to resource**
4. **Xác nhận tạo đúng chuẩn**: trong zone thấy **4 bản ghi NS** (nameserver Azure) + **1 bản ghi SOA** tự sinh ✅

### Minh chứng cho giáo viên (3 bước — không cần mua domain)

**Bước 1 — Lấy nameserver của zone:**
- Portal → zone `tripto.vn` → nhìn record **NS** → copy 1 cái (vd `ns1-01.azure-dns.com`)

**Bước 2 — Thêm 1 bản ghi vào zone:**
- Trong zone → **+ Record set** → Name `www` → Type **CNAME** → Alias `tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net` → **OK**

**Bước 3 — Query trực tiếp nameserver (Cloud Shell hoặc máy):**
```
nslookup -type=CNAME www.tripto.vn ns1-01.azure-dns.com
```
Kết quả (bằng chứng hoạt động):
```
www.tripto.vn  canonical name = tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net
```
→ Máy chủ DNS Azure trả lời đúng bản ghi = **zone đang hoạt động thật** ✅

### Bảng minh chứng cho giáo viên

| Câu giáo viên hỏi | Bạn trả lời + cho xem |
|---|---|
| "DNS zones là gì?" | Nơi quản lý bản ghi tên miền → Azure DNS zone |
| "Bạn có tạo thật không?" | Có, mở Portal cho xem zone `tripto.vn` + NS/SOA records |
| "Nó hoạt động không?" | Chạy `nslookup -type=CNAME www.tripto.vn <NS-Azure>` → Azure trả lời đúng bản ghi |
| "Sao không mở web bằng domain?" | F1 không bind domain + chưa mua domain; cần B1+ để bind |

### Tóm lại

- **Zone trắng vẫn chứng minh được hoạt động** bằng cách query nameserver (nslookup/dig) — không cần mua domain
- Điều kiện để zone chạy thật (web mở bằng tên miền): mua domain + trỏ NS sang Azure DNS + nâng App Service lên B1+ để bind custom domain

---

## ENTRA ID — Tạo App Registration + Tích hợp "Đăng nhập bằng Microsoft" vào web

> **Đã code sẵn trong repo** (phần này không tốn tiền, dùng Entra ID Free):
> - **Backend** `backend/user.php`: action `login_microsoft` → `authLoginMicrosoft()` xác minh `id_token` JWT RS256 bằng JWKS của Microsoft (không cần thư viện ngoài), tự tạo/tìm user theo email, set session như login thường.
> - **Frontend** `frontend/js/msal-auth.js`: MSAL.js từ CDN, tự chèn nút **"Tiếp tục với Microsoft"** vào modal đăng nhập của 7 trang (TRANGCHU, BLOG, TATCA_TOUR, TATCA_COMBO, UUDAI, chitiettour, timkiem_chitiet), popup đăng nhập rồi gửi `id_token` lên backend.
> - **Cấu hình** `frontend/user/msal-config.js`: chứa `window.MSAL_CONFIG` (gitignored, không commit). Backend đọc `MS_CLIENT_ID`/`MS_TENANT_ID` từ biến môi trường App Service.

### Bước 1 — Tạo App Registration (Portal, ~15 phút)

1. Portal → tìm **"Microsoft Entra ID"** → menu trái → **App registrations** → **+ New registration**
2. Điền:
   - **Name**: `tripto-app`
   - **Supported account types**: chọn **"Accounts in any organizational directory and personal Microsoft accounts"** (để mọi email Microsoft đăng nhập được)
   - **Redirect URI**: platform **Single-page application (SPA)** → nhập URL web thật:
     `https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net`
3. Bấm **Register** → sang trang app → ghi lại 2 giá trị:
   - **Application (client) ID** → điền vào `MS_CLIENT_ID`
   - **Directory (tenant) ID** → điền vào `MS_TENANT_ID`
4. (Tùy chọn) Nhánh trái → **Authentication** → phần **Implicit grant and hybrid flows** → tick **ID tokens** → **Save** (một số phiên bản MSAL cần, thường SPA mặc định đã đủ)

### Bước 2 — Cấu hình backend (App Service)

- Portal → App Service `tripto` → **Configuration** → tab **Application settings** → thêm 2 biến:
  - `MS_CLIENT_ID` = `<Application Client ID vừa tạo>`
  - `MS_TENANT_ID` = `<Tenant ID>` (hoặc để `common` nếu muốn chấp nhận mọi tenant)
- **Save** → app restart tự động. Làm tương tự trên `tripto2` (nếu muốn).

### Bước 3 — Cấu hình frontend

- Sửa file `frontend/user/msal-config.js` (file này đang gitignored):
  ```js
  window.MSAL_CONFIG = {
      clientId: '<Application Client ID>',
      authority: 'https://login.microsoftonline.com/<Tenant ID>/v2.0',
      redirectUri: 'https://tripto-gcbmg6gybegye7ex.southeastasia-01.azurewebsites.net'
  };
  ```
- Deploy lại frontend (file này không nằm trong git nên phải deploy qua zip/Cloud Shell như `maps-config.js`).

### Bước 4 — Kiểm chứng

1. Mở web thật → bấm **Đăng Nhập** → modal có nút **"Tiếp tục với Microsoft"**
2. Bấm nút → popup Microsoft hiện ra → đăng nhập bằng email Microsoft bất kỳ
3. Chọn đồng ý quyền → popup đóng → web báo đăng nhập thành công, hiện tên user
4. Kiểm tra DB: `SELECT id, email, facebook_id FROM nguoi_dung WHERE facebook_id IS NOT NULL;` → thấy user mới tự tạo
5. Portal Entra ID → **Sign-in logs** → thấy lần đăng nhập mới = **chứng minh đăng nhập qua Entra ID thật** ✅

### Lưu ý an toàn

- `clientId`/`tenantId` **không phải bí mật** (dạng public trong SPA) nhưng đặt trong file gitignored để tránh GitHub chặn push và giữ gọn.
- Toàn bộ xác minh chữ ký diễn ra ở **backend** (chỉ dựa vào khóa công khai Microsoft, không tin token gửi lên) → chống làm giả token.

---

## Tổng kết trạng thái hiện tại

| Dịch vụ | Tài nguyên | Trạng thái |
|---------|-----------|------------|
| App Service (chính) | `tripto` | ✅ Online |
| App Service (dự phòng) | `tripto2` | ✅ Online |
| Traffic Manager | `tripto-tm` | ✅ 2 endpoint Online |
| Key Vault | `triptokv` | ✅ 2 secrets: `DB-PASS`, `MAPS-KEY` |
| Azure Maps | `tripto-maps` | ✅ Gen2, location `global`, **đã nhúng bản đồ vào web** (Usage 165 request) |
| GitHub Actions | `main_tripto.yml` | ✅ Deploy `tripto` tự động khi push main |
| GitHub Actions | `main_tripto2.yml` | ✅ (kết nối xong) Deploy `tripto2` tự động khi push main |
| DNS zones | `tripto.vn` | ✅ Zone trắng tạo xong (NS/SOA tự sinh), minh chứng bằng nslookup |
| Entra ID | `tripto-app` (App Registration) | 🔄 **Đã code xong backend + frontend**; đang chờ tạo App Registration + điền `msal-config.js` + set env vars |

**Chưa làm:** Entra ID (đang chờ tạo App Registration để nối). **Bị chặn:** Front Door, region Maps cụ thể. **DNS chạy thật:** cần mua domain + nâng B1+ (đề xuất bước tiếp theo).
