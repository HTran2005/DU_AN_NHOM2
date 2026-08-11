# ACCOUNT 3 — DevOps & Security (Máy DevOps)
## Nhiệm vụ: Liên kết TOÀN BỘ dịch vụ Azure lên Azure DevOps để báo cáo

---

## ✅ ĐÃ HOÀN THÀNH (Code & Script)

### 1. Liên kết dịch vụ lên Azure DevOps
- [x] **Org**: `DuAnNhom2` · **Project**: `BAO_CAO`
- [x] Script tạo Service Connection: `create-service-connections.ps1`
  - Chế độ **Shared**: 1 SPN `sp-tripto-devops-report` + 1 connection `Azure-TripTo` (tất cả account cùng tenant)
  - Chế độ **PerSubscription**: `Azure-TripTo-ACC1..3` (các account khác tenant)
  - Cấp quyền **Reader** trên từng subscription (least-privilege, chỉ đọc để báo cáo)
- [x] Pipeline báo cáo: `azure-pipelines-report.yml` (Shared) + `azure-pipelines-report-multi.yml` (dự phòng)
- [x] Báo cáo tổng hợp: `generate-report.sh` → `REPORT.md` (tổng quan + chi tiết từng account + top dịch vụ)
- [x] Thu thập local: `collect-resources.ps1` (chạy ngay trên máy DevOps)

### 2. Tài liệu
- [x] `docs/RUNBOOK_HOAN_CHINH_DEV_OPS_ACCOUNT3.md` — **runbook hoàn chỉnh bàn giao DevOps** (từng bước + lệnh + bằng chứng + rollback)
- [x] `infrastructure/account3/preflight-check.ps1` — script kiểm tra sẵn sàng trước khi thực hiện
- [x] `docs/LIEN_KET_DEV_OPS_ACCOUNT3.md` — hướng dẫn từng bước chi tiết

---

## 🔄 ĐANG LÀM / CHỜ

### A. Điền thông tin thật (cần thành viên khác cung cấp)
- [x] `parameters.json` — **ACC1** (Frontend & Backend): `bbad92f7-b7ef-4fa7-b3ef-61c200f5802e`
- [x] `parameters.json` — **ACC2** (Database & Monitoring): `42e7a0ff-6e78-4530-a021-bf133c012ba2`
- [ ] **ACC3** (DevOps & Security): **để trống** — DevOps thường không có Azure subscription (tài nguyên DevOps nằm trong Azure DevOps, không phải Azure). Báo cáo sẽ gồm ACC1 + ACC2.
- [ ] Chạy `create-service-connections.ps1` với PAT thật
- [ ] Chạy pipeline báo cáo + chụp màn hình artifact làm bằng chứng

---

## 📋 CÁC BƯỚC THỰC HIỆN (khi có đủ thông tin)

```powershell
# 1. Điền subscriptionId vào infrastructure/account3/parameters.json

# 2. Tạo service connection (chạy trên máy DevOps)
az login
.\infrastructure\account3\create-service-connections.ps1 -Pat "<PAT>"

# 3. Chạy báo cáo local
.\infrastructure\account3\collect-resources.ps1
# → reports/REPORT.md

# 4. Tạo pipeline trên DevOps portal (import azure-pipelines-report.yml) → Run
# → Artifact: BaoCaoToanBoDichVu/REPORT.md
```

---

## 📌 GHI CHÚ

- SPN chỉ có quyền **Reader** — không thể thay đổi tài nguyên, an toàn cho mục đích báo cáo.
- Nếu các account nằm ở tenant Entra ID khác nhau → dùng `-Mode PerSubscription` + pipeline `azure-pipelines-report-multi.yml`.
- Báo cáo `REPORT.md` là bằng chứng thời gian thực bổ sung cho `docs/CAU_TRUC_BAO_CAO.md` (Chương 3).
