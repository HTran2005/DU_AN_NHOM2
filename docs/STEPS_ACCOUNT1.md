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

## Tổng kết trạng thái hiện tại

| Dịch vụ | Tài nguyên | Trạng thái |
|---------|-----------|------------|
| App Service (chính) | `tripto` | ✅ Online |
| App Service (dự phòng) | `tripto2` | ✅ Online |
| Traffic Manager | `tripto-tm` | ✅ 2 endpoint Online |
| Key Vault | `triptokv` | ✅ 2 secrets: `DB-PASS`, `MAPS-KEY` |
| Azure Maps | `tripto-maps` | ✅ Gen2, location `global`, **đã nhúng bản đồ vào web** (Usage 165 request) |

**Chưa làm:** DNS zones (chưa có domain), Entra ID (nhóm bỏ qua). **Bị chặn:** Front Door, region Maps cụ thể.
