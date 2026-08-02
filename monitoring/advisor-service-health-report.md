# Báo cáo dịch vụ bổ sung — Azure Advisor & Azure Service Health

Ngày kiểm tra: 2026-08-02
Subscription: `42e7a0ff-6e78-4530-a021-bf133c012ba2`
Tenant: `27089f51-910a-4704-8f1d-47c335d11e1c`

---

## 1. Azure Advisor

### Giới thiệu
Azure Advisor là dịch vụ miễn phí, tự động phân tích tài nguyên của subscription và đưa ra
khuyến nghị (best practice) theo 5 nhóm: Cost, Security, Reliability, Performance,
Operational Excellence. Dữ liệu được lấy trực tiếp từ Portal/Cli khi chạy
`az advisor recommendation list`.

### Kết quả kiểm tra thực tế (2026-08-02)
- **Tổng số khuyến nghị: 25**
  - **Security: 17**
  - **HighAvailability (Reliability): 8**

### Các khuyến nghị đáng chú ý
| Nhóm | Mức | Nội dung |
|------|-----|----------|
| Security | High | Chỉ có 1 owner trên subscription, nên thêm nhiều hơn |
| Security | High | Bật Microsoft Defender for SQL cho MySQL flexible server |
| Security | High | Bật Microsoft Defender for Storage (malware scanning) |
| Security | Medium | Storage nên giới hạn truy cập mạng bằng VNet rules |
| Security | Medium | Storage nên chặn shared key access |
| HighAvailability | High | Bật zone redundancy cho storage accounts |
| HighAvailability | Medium | Bật geo-backup cho MySQL server |
| HighAvailability | Medium | Bật Cross Region Restore cho Recovery Services Vault |
| HighAvailability | High | Tạo Azure Service Health alert (đã làm) |

> Advisor tự chạy, không tốn chi phí. Các khuyến nghị là căn cứ chứng minh dịch vụ hoạt động:
> portal.azure.com → Advisor → xem danh sách.

---

## 2. Azure Service Health

### Giới thiệu
Azure Service Health gồm 2 phần:
- **Service health**: sự cố/outage ảnh hưởng toàn bộ dịch vụ Azure tại region.
- **Resource health**: trạng thái sức khỏe (Available/Degraded/Unavailable) của từng tài nguyên.

### Kết quả kiểm tra thực tế (2026-08-02)
- **Service health events: 0** (không có sự cố Azure nào gần đây — trạng thái bình thường)
- **Resource health (`law-tripto` — Log Analytics workspace): Available** ✅

### Cảnh báo đã cấu hình (Activity Log Alerts → Action Group `ag-tripto-critical`)
| Alert | Loại | Tác dụng |
|-------|------|----------|
| `alert-service-health` | ServiceHealth | Báo email khi Azure có sự cố dịch vụ |
| `alert-resource-health` | ResourceHealth | Báo email khi tài nguyên chuyển trạng thái xấu |

> Chứng minh hoạt động: portal.azure.com → Service Health → xem "Service issues",
> "Resource health", "Health history". Không có sự cố = hệ thống đang khỏe.

---

## Tóm tắt giá trị báo cáo
- **Advisor**: chứng minh khả năng phân tích & đưa khuyến nghị bảo mật/độ tin cậy (25 khuyến nghị thực).
- **Service Health**: chứng minh giám sát sức khỏe Azure toàn cục + từng tài nguyên (Resource Health Available), kèm 2 alert email tự động.
