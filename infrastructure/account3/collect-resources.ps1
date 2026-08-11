<#
.SYNOPSIS
  Thu thập danh sách tài nguyên từ TẤT CẢ các account/subscription của TripTo
  về thư mục local (reports/inventory) để phục vụ báo cáo.

.DESCRIPTION
  Chạy TRÊN MÁY DEV OPS (máy account 3). Yêu cầu:
    - Azure CLI đã đăng nhập (az login) với tài khoản có quyền đọc từng subscription
    - jq (dùng cho generate-report.sh): choco install jq / winget install jq
    - bash (Git Bash / WSL) để chạy generate-report.sh

  Kết quả: reports/inventory/resources-<KEY>.json + meta-<KEY>.json cho từng account,
  sau đó tự động gọi generate-report.sh để tạo reports/REPORT.md.

.EXAMPLE
  .\collect-resources.ps1

.EXAMPLE
  .\collect-resources.ps1 -ParametersPath "infrastructure/account3/parameters.json" -ReportDir "reports/inventory"
#>

[CmdletBinding()]
param(
  [string]$ParametersPath = "infrastructure/account3/parameters.json",
  [string]$ReportDir      = "reports/inventory"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TripTo - Thu thập tài nguyên toàn bộ account" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════`n" -ForegroundColor Cyan

# === KIỂM TRA ===
$azPath = Get-Command az -ErrorAction SilentlyContinue
if (-not $azPath) {
  Write-Error "❌ Azure CLI chưa được cài đặt. Tải tại: https://aka.ms/installazurecliwindows"
  exit 1
}

$contextJson = az account show 2>$null
if ($LASTEXITCODE -ne 0 -or -not $contextJson) {
  Write-Warning "⚠️ Chưa đăng nhập Azure. Đang mở trình duyệt đăng nhập..."
  az login
  if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Đăng nhập Azure thất bại."
    exit 1
  }
}

if (-not (Test-Path $ParametersPath)) {
  Write-Error "❌ Không tìm thấy file cấu hình: $ParametersPath"
  exit 1
}
$config = Get-Content $ParametersPath -Raw | ConvertFrom-Json

# === TẠO THƯ MỤC ===
$invDir = Join-Path (Get-Location) $ReportDir
New-Item -ItemType Directory -Path $invDir -Force | Out-Null
Write-Host "📁 Thư mục lưu trữ: $invDir" -ForegroundColor Yellow

# === THU THẬP ===
$collected = 0
foreach ($acc in $config.accounts) {
  if (-not $acc.subscriptionId) {
    Write-Host "  ⏭️  $($acc.key) ($($acc.name)): chưa có subscriptionId → bỏ qua" -ForegroundColor DarkGray
    continue
  }
  $subId = $acc.subscriptionId
  $key   = $acc.key

  Write-Host ""
  Write-Host "  -- $key ($($acc.label)) --" -ForegroundColor Yellow

  $metaJson = az account show --subscription $subId -o json 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $metaJson) {
    Write-Warning "  ⚠️  Không truy cập được subscription $subId (cần az login với account này)."
    continue
  }
  $meta = $metaJson | ConvertFrom-Json

  $resJson = az resource list --subscription $subId -o json 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $resJson) {
    Write-Warning "  ⚠️  Lấy danh sách tài nguyên thất bại cho $subId."
    continue
  }
  $res = $resJson | ConvertFrom-Json

  $meta | ConvertTo-Json -Depth 5 | Out-File (Join-Path $invDir "meta-$key.json") -Encoding utf8
  $res  | ConvertTo-Json -Depth 10 | Out-File (Join-Path $invDir "resources-$key.json") -Encoding utf8

  $typeCount = ($res | Select-Object -ExpandProperty type -Unique).Count
  Write-Host "  ✅ ${key}: $($res.Count) tài nguyên / $typeCount loại dịch vụ" -ForegroundColor Green
  $collected++
}

if ($collected -eq 0) {
  Write-Error "❌ Không thu thập được account nào. Kiểm tra subscriptionId trong parameters.json."
  exit 1
}

Write-Host "`n✅ Đã thu thập $collected account." -ForegroundColor Green

# === SINH BÁO CÁO ===
Write-Host ""
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  SINH BÁO CÁO TỔNG HỢP (generate-report.sh)" -ForegroundColor DarkCyan
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$genScript = Join-Path $repoRoot "infrastructure/account3/generate-report.sh"
$outFile = Join-Path (Split-Path $invDir) "REPORT.md"

if (-not (Test-Path $genScript)) {
  Write-Error "❌ Không tìm thấy generate-report.sh tại $genScript"
  exit 1
}

$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bashCmd) {
  Write-Warning "⚠️ Không tìm thấy bash (cần Git Bash hoặc WSL). Dữ liệu JSON đã lưu tại $invDir."
  exit 1
}

& bash $genScript -i $invDir -o $outFile
if ($LASTEXITCODE -ne 0) {
  Write-Error "❌ Sinh báo cáo thất bại (kiểm tra jq: choco install jq)."
  exit 1
}

Write-Host ""
Write-Host "══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ BÁO CÁO ĐÃ TẠO: $outFile" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════" -ForegroundColor Green
