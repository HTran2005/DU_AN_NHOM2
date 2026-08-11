<#
.SYNOPSIS
  Kiểm tra sẵn sàng (PREFLIGHT) trước khi liên kết toàn bộ dịch vụ lên Azure DevOps.

.DESCRIPTION
  Chạy trên máy DevOps (Account 3 — DevOps & Security) TRƯỚC khi thực hiện
  create-service-connections.ps1. Kiểm tra lần lượt:
    [1] Azure CLI (az) đã cài
    [2] Đã đăng nhập Azure (az login)
    [3] jq + bash (cần cho generate-report.sh)
    [4] File parameters.json tồn tại + hợp lệ + account nào còn thiếu subscriptionId
    [5] PAT Azure DevOps (tham số -Pat hoặc biến môi trường AZURE_DEVOPS_EXT_PAT)
    [6] (Tùy chọn) Kết nối mạng tới dev.azure.com:443

  In bảng kết quả ✅/❌ kèm hành động cần làm. Exit code = 0 nếu các mục
  quan trọng đều PASS, ngược lại = 1.

.PARAMETER Pat
  PAT Azure DevOps. Nếu không truyền sẽ kiểm tra biến môi trường AZURE_DEVOPS_EXT_PAT.

.PARAMETER SkipNetwork
  Bỏ qua kiểm tra kết nối mạng tới dev.azure.com (mục này có thể chậm).

.EXAMPLE
  .\preflight-check.ps1

.EXAMPLE
  .\preflight-check.ps1 -Pat "xxxx" -SkipNetwork
#>

[CmdletBinding()]
param(
  [string]$Pat = $env:AZURE_DEVOPS_EXT_PAT,
  [switch]$SkipNetwork,
  [string]$ParametersPath = "infrastructure/account3/parameters.json"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TRIPTO — PREFLIGHT CHECK (Máy DevOps / Account 3)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════`n" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Item,
    [string]$Status,        # "OK" hoặc "MISSING"
    [string]$Detail = ""
  )
  $script:results.Add([pscustomobject]@{ Item = $Item; Status = $Status; Detail = $Detail })
  $icon = if ($Status -eq "OK") { "✅" } else { "❌" }
  Write-Host ("  {0} {1}" -f $icon, $Item) -ForegroundColor $(if ($Status -eq "OK") { "Green" } else { "Red" })
  if ($Detail) {
    Write-Host ("      → {0}" -f $Detail) -ForegroundColor Gray
  }
}

# =========================================================
# [1] AZURE CLI
# =========================================================
Write-Host "── [1] Azure CLI ────────────────────────────────" -ForegroundColor DarkCyan
$az = Get-Command az -ErrorAction SilentlyContinue
if ($az) {
  $azVer = az version -o json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty 'azure-cli' -ErrorAction SilentlyContinue
  if (-not $azVer) { $azVer = "đã cài" }
  Add-Check "Azure CLI (az)" "OK" "Đã cài: $azVer"
}
else {
  Add-Check "Azure CLI (az)" "MISSING" "Cài tại https://aka.ms/installazurecliwindows"
}

# =========================================================
# [2] ĐĂNG NHẬP AZURE
# =========================================================
Write-Host "── [2] Đăng nhập Azure ──────────────────────────" -ForegroundColor DarkCyan
$ctx = az account show -o json 2>$null
if ($LASTEXITCODE -eq 0 -and $ctx) {
  $accName = ($ctx | ConvertFrom-Json).user.name
  Add-Check "Đăng nhập Azure" "OK" "Đang đăng nhập: $accName"
}
else {
  Add-Check "Đăng nhập Azure" "MISSING" "Chạy 'az login' trước khi tiếp tục"
}

# =========================================================
# [3] jq + BASH
# =========================================================
Write-Host "── [3] Công cụ báo cáo (jq, bash) ──────────────" -ForegroundColor DarkCyan
$jq = Get-Command jq -ErrorAction SilentlyContinue
if ($jq) {
  Add-Check "jq" "OK" "Cài: $($jq.Source)"
}
else {
  Add-Check "jq" "MISSING" "Cài: choco install jq  (hoặc winget install jq)"
}

$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
  Add-Check "bash (Git Bash / WSL)" "OK"
}
else {
  Add-Check "bash (Git Bash / WSL)" "MISSING" "Cài Git for Windows (có Git Bash) hoặc bật WSL"
}

# =========================================================
# [4] PARAMETERS.JSON
# =========================================================
Write-Host "── [4] Cấu hình parameters.json ────────────────" -ForegroundColor DarkCyan
if (-not (Test-Path $ParametersPath)) {
  Add-Check "File $ParametersPath" "MISSING" "File chưa tồn tại — kiểm tra đường dẫn"
}
else {
  Add-Check "File $ParametersPath" "OK"
  try {
    $cfg = Get-Content $ParametersPath -Raw | ConvertFrom-Json
    Add-Check "JSON hợp lệ" "OK"
    Add-Check "Org/Project: $($cfg.organization) / $($cfg.project)" "OK"
    foreach ($acc in $cfg.accounts) {
      if ($acc.subscriptionId) {
        Add-Check "$($acc.key) — $($acc.label)" "OK" "subscriptionId: $($acc.subscriptionId)"
      }
      else {
        Add-Check "$($acc.key) — $($acc.label)" "MISSING" "Chưa có subscriptionId — hỏi thành viên sở hữu account"
      }
    }
  }
  catch {
    Add-Check "JSON hợp lệ" "MISSING" "Lỗi parse: $($_.Exception.Message)"
  }
}

# =========================================================
# [5] PAT AZURE DEVOPS
# =========================================================
Write-Host "── [5] PAT Azure DevOps ─────────────────────────" -ForegroundColor DarkCyan
if ($Pat) {
  Add-Check "PAT" "OK" "Đã cung cấp (độ dài $($Pat.Length) ký tự) — scopes cần: Service Connections (Read & manage) + Build (Read & execute)"
}
else {
  Add-Check "PAT" "MISSING" "Truyền -Pat hoặc đặt biến AZURE_DEVOPS_EXT_PAT. Tạo PAT: dev.azure.com → User settings → Personal Access Tokens"
}

# =========================================================
# [6] KẾT NỐI MẠNG
# =========================================================
if (-not $SkipNetwork) {
  Write-Host "── [6] Kết nối mạng ─────────────────────────────" -ForegroundColor DarkCyan
  try {
    $tcp = Test-NetConnection -ComputerName "dev.azure.com" -Port 443 -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) {
      Add-Check "Kết nối dev.azure.com:443" "OK"
    }
    else {
      Add-Check "Kết nối dev.azure.com:443" "MISSING" "Không tới được dev.azure.com — kiểm tra firewall/VPN"
    }
  }
  catch {
    Add-Check "Kết nối dev.azure.com:443" "MISSING" $_.Exception.Message
  }
}

# =========================================================
# TỔNG KẾT
# =========================================================
Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
$okCount  = ($results | Where-Object Status -eq "OK").Count
$missCount = ($results | Where-Object Status -eq "MISSING").Count
Write-Host "  KẾT QUẢ: $okCount OK · $missCount CẦN XỬ LÝ" -ForegroundColor $(if ($missCount -eq 0) { "Green" } else { "Yellow" })
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan

if ($missCount -gt 0) {
  Write-Host ""
  Write-Host "  📋 Các mục cần xử lý TRƯỚC KHI CHẠY create-service-connections.ps1:"
  Write-Host "    - Subscription ID còn thiếu: hỏi bạn ACC1/ACC2/ACC3 (az account list)"
  Write-Host "    - jq: choco install jq | winget install jq | sudo apt install jq"
  Write-Host "    - PAT: tạo mới tại User settings → Personal Access Tokens"
  Write-Host "    - az login: đăng nhập bằng tài khoản Azure"
  Write-Host ""
  Write-Host "  Chi tiết từng bước: docs/RUNBOOK_HOAN_CHINH_DEV_OPS_ACCOUNT3.md" -ForegroundColor Cyan
  exit 1
}

Write-Host ""
Write-Host "  ✅ MỌI ĐIỀU KIỆN SẴN SÀNG. Bắt đầu theo runbook:" -ForegroundColor Green
Write-Host "     docs/RUNBOOK_HOAN_CHINH_DEV_OPS_ACCOUNT3.md" -ForegroundColor Cyan
exit 0
