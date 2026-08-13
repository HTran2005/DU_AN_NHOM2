# DNS Zone + Custom Domain miễn phí (Azure DNS + DuckDNS)

> Ngày thực hiện: 2026-08-13 · Tài khoản Azure: `hhd211105@gmail.com`

## 1. Mục tiêu
Đưa web `bao-cao-nhom2-web` chạy bằng một **tên miền đẹp miễn phí** (không mua domain) và đảm bảo HTTPS hoạt động.

## 2. Kết quả cuối cùng
- Web chạy tại: **`https://www.tripto.duckdns.org`** (HTTP 200, SSL hợp lệ `CN=www.tripto.duckdns.org`).
- Trang chủ tự chuyển đến `/frontend/user/TRANGCHU.html` (HTTP 200).

## 3. Tổng quan kiến trúc

```
Trình duyệt
   │  https://www.tripto.duckdns.org
   ▼
DuckDNS (A record → 20.212.64.3)  ← domain miễn phí, cài IP web app
   ▼
App Service bao-cao-nhom2-web (S1)  ← custom domain bind Verified + Managed Certificate
   ▼
Web (frontend/user/TRANGCHU.html)
```

### Tài nguyên chính
| Thành phần | Giá trị |
|---|---|
| Domain miễn phí | `www.tripto.duckdns.org` (tài khoản duckdns `tuine0942@gmail.com`) |
| IP web app | `20.212.64.3` (lấy từ `bao-cao-nhom2-web-cxenh6f9emhxdbgp.southeastasia-01.azurewebsites.net`) |
| App Service | `bao-cao-nhom2-web` — RG `DU_AN_NHOM2_RG` — Plan `ASP-DUANNHOM2RG-bd63` (**Standard S1**) — subscription `42e7a0ff-6e78-4530-a021-bf133c012ba2` |
| Custom domain binding | `www.tripto.duckdns.org` → trạng thái **Verified** |
| SSL | App Service Managed Certificate: `CN=www.tripto.duckdns.org` (thumbprint `2F26BE816CD509FE1D853D9C291D7987DE6A39EB`) |
| Mã xác minh web (domain verification ID) | `29391E5D2DF7F7D74EBDD40477EBB6244D09A6678ADEC1027068F7F52B6E2B89` |

---

## 4. Các bước đã thực hiện

### 4.1. Azure DNS — public zone `tripto.vn` (thuộc báo cáo "Azure DNS Zones")
1. Đăng ký provider `Microsoft.Network` trên subscription hhd:
   `az provider register -n Microsoft.Network -s <sub>`
2. Tạo public zone trong sub **`42e7a0ff-6e78-4530-a021-bf133c012ba2`** (sub đang quản lý):
   ```
   az network dns zone create -g DU_AN_NHOM2_RG -n tripto.vn -s 42e7a0ff-6e78-4530-a021-bf133c012ba2
   ```
   - Nameserver: `ns1-04.azure-dns.com`, `ns2-04.azure-dns.net`, `ns3-04.azure-dns.org`, `ns4-04.azure-dns.info`
3. Thêm record `www` CNAME → web:
   ```
   az network dns record-set cname set-record -g du_an_nhom2_rg -z tripto.vn -n www `
     --cname bao-cao-nhom2-web-cxenh6f9emhxdbgp.southeastasia-01.azurewebsites.net -s 42e7a0ff-
   ```
4. **Lưu ý:** zone trùng cũ ở sub `046d5392…` đã bị xóa để tránh trùng tên.

> Bản chất `tripto.vn` là **zone trắng minh họa** (NS không được ủy quyền công khai) — dùng để chứng minh dịch vụ **Azure DNS zones (Public)** hoạt động bằng `nslookup … ns1-04.azure-dns.com`. Để web chạy tên thật bằng Azure zone cần mua domain + trỏ NS (chưa làm, tốn phí).

### 4.2. DuckDNS — domain miễn phí dùng được ngay
1. Đăng ký tại `https://duckdns.org` bằng OAuth (Google/GitHub…) → tạo subdomain `tripto.duckdns.org` (token: `2ed2a347-4ce1-4176-843c-0cbb6bd72395`).
2. **DuckDNS không có mục CNAME** (chỉ A/AAAA/TXT/NS/MX) → dùng **A record** trỏ về IP web app.
3. Set A record = IP web app (`20.212.64.3`):
   ```
   https://www.duckdns.org/update?domains=tripto&token=2ed2a347-4ce1-4176-843c-0cbb6bd72395&ip=20.212.64.3
   ```
4. Set TXT thể hiện quyền sở hữu (dùng cho xác minh App Service; TXT này trả về cho cả `asuid.www`):
   ```
   https://www.duckdns.org/update?domains=tripto&token=2ed2a347-4ce1-4176-843c-0cbb6bd72395&txt=29391E5D2DF7F7D74EBDD40477EBB6244D09A6678ADEC1027068F7F52B6E2B89
   ```

### 4.3. App Service — bind custom domain `www.tripto.duckdns.org`
1. Lấy mã xác minh web:
   ```
   az rest -m get -u "https://management.azure.com/subscriptions/42e7a0ff-…/resourceGroups/DU_AN_NHOM2_RG/providers/Microsoft.Web/sites/bao-cao-nhom2-web?api-version=2023-12-01" -q properties.customDomainVerificationId
   ```
2. Bind custom domain:
   ```
   az webapp config hostname add -g DU_AN_NHOM2_RG --webapp-name bao-cao-nhom2-web `
     --hostname www.tripto.duckdns.org -s 42e7a0ff-6e78-4530-a021-bf133c012ba2
   ```
   → kết quả `hostNameType: "Verified"` (Azure đã xác minh quyền sở hữu qua TXT asuid).

### 4.4. HTTPS — App Service Managed Certificate (miễn phí)
1. Tạo managed cert (resource `Microsoft.Web/certificates` với `canonicalName` + `serverFarmId`), hoặc dùng:
   `az webapp config ssl create -g DU_AN_NHOM2_RG --name bao-cao-nhom2-web --hostname www.tripto.duckdns.org -s 42e7a0ff-…`
2. Bind cert (SNI):
   ```
   az webapp config ssl bind --certificate-thumbprint 2F26BE816CD509FE1D853D9C291D7987DE6A39EB `
     --ssl-type SNI -g DU_AN_NHOM2_RG --name bao-cao-nhom2-web --hostname www.tripto.duckdns.org -s 42e7a0ff-…
   ```

---

## 5. Kết quả kiểm chứng
| Kiểm tra | Lệnh | Kết quả |
|---|---|---|
| DNS A record | `nslookup www.tripto.duckdns.org 8.8.8.8` | → `20.212.64.3` ✅ |
| DNS TXT (asuid) | `nslookup -type=TXT asuid.www.tripto.duckdns.org` | trả mã xác minh ✅ |
| HTTPS + chứng chỉ | `curl.exe -sS -o NUL -w "%{http_code} %{ssl_verify_result}" https://www.tripto.duckdns.org/` | `200 0` (verify OK) ✅ |
| Trang chủ thật | `curl … https://www.tripto.duckdns.org/frontend/user/TRANGCHU.html` | `200` ✅ |

## 6. Cách dùng / trình bày
- Mở trình duyệt: `https://www.tripto.duckdns.org`
- Minh chứng Azure DNS zones: `nslookup -type=CNAME www.tripto.vn ns1-04.azure-dns.com`

## 7. Lưu ý
- **IP có thể đổi**: nếu IP web app thay đổi (thay plan/redeploy), cập nhật lại A record duckdns bằng lệnh ở mục 4.2. bước 3.
- DuckDNS là **subdomain miễn phí** (chủ sở hữu là duckdns.org) → dùng cho demo/đồ án. Muốn domain "thật" cần mua + delegate NS về Azure DNS.
- Zone `tripto.vn` vẫn **chưa ủy quyền công khai** (zone trắng) — muốn chạy thật cần mua domain này.