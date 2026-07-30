<#
.SYNOPSIS
  Deploy TripTo Monitoring Infrastructure (Account 2) lên Azure bằng Bicep.
  Có thể chạy local hoặc CI/CD.

.DESCRIPTION
  Script này:
    1. Đăng nhập Azure (nếu chưa)
    2. Tạo Resource Group
    3. Deploy Bicep template
    4. Xuất kết quả deployment
    5. Lưu Output (Instrumentation Key, Connection String) ra file

.PARAMETER ResourceGroupName
  Tên Resource Group (mặc định: rg-tripto-monitoring)

.PARAMETER Location
  Region Azure (mặc định: southeastasia)

.PARAMETER BicepPath
  Đường dẫn đến thư mục chứa main.bicep

.PARAMETER ParametersFile
  Đường dẫn đến file parameters JSON

.EXAMPLE
  .\scripts\deploy-monitoring.ps1
  Chạy với giá trị mặc định

.EXAMPLE
  .\scripts\deploy-monitoring.ps1 -ResourceGroupName "rg-tripto-monitoring" -Location "southeastasia"
#>

param(
  [string]$ResourceGroupName = "rg-tripto-monitoring",
  [string]$Location = "southeastasia",
  [string]$BicepPath = "infrastructure/account2",
  [string]$OutputFile = "infrastructure/account2/.deploy-outputs.json"
)

# === KIỂM TRA PREREQUISITES ===
Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TripTo - Azure Monitor Deployment" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# Kiểm tra Azure CLI
$azPath = Get-Command az -ErrorAction SilentlyContinue
if (-not $azPath) {
  Write-Error "❌ Azure CLI chưa được cài đặt. Tải tại: https://aka.ms/installazurecliwindows"
  exit 1
}

# Kiểm tra Bicep
$bicepCheck = az bicep version 2>$null
if (-not $bicepCheck) {
  Write-Host "📦 Đang cài đặt Bicep CLI..." -ForegroundColor Yellow
  az bicep install
}

# === ĐĂNG NHẬP AZURE ===
$context = Get-AzContext
if (-not $context) {
  Write-Host "🔑 Đăng nhập Azure..." -ForegroundColor Yellow
  Connect-AzAccount
}
else {
  Write-Host "✅ Đã đăng nhập: $($context.Account.Id)" -ForegroundColor Green
}

# === TẠO RESOURCE GROUP ===
Write-Host "`n📁 Tạo Resource Group: $ResourceGroupName tại $Location..." -ForegroundColor Yellow
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
  New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
  Write-Host "✅ Resource Group đã tạo" -ForegroundColor Green
}
else {
  Write-Host "✅ Resource Group đã tồn tại" -ForegroundColor Green
}

# === BUILD BICEP (validate syntax) ===
Write-Host "`n🔍 Kiểm tra cú pháp Bicep..." -ForegroundColor Yellow
$buildResult = az bicep build --file "$BicepPath/main.bicep" 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Error "❌ Lỗi Bicep syntax: $buildResult"
  exit 1
}
Write-Host "✅ Bicep syntax OK" -ForegroundColor Green

# === WHAT-IF (xem trước thay đổi) ===
Write-Host "`n🔮 Preview thay đổi (what-if)..." -ForegroundColor Yellow
az deployment group what-if `
  --resource-group $ResourceGroupName `
  --template-file "$BicepPath/main.bicep" `
  --parameters "@$BicepPath/parameters.json" `
  --output table

# === DEPLOY ===
$confirm = Read-Host "`n❓ Deploy lên Azure? (y/n)"
if ($confirm -ne 'y') {
  Write-Host "⏹️  Đã hủy deployment." -ForegroundColor Red
  exit 0
}

Write-Host "`n🚀 Đang deploy Bicep..." -ForegroundColor Yellow
$deployment = New-AzResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$BicepPath/main.bicep" `
  -TemplateParameterFile "$BicepPath/parameters.json" `
  -Mode Incremental

# === KẾT QUẢ ===
Write-Host "`n═══════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host "  Resource Group : $ResourceGroupName"
Write-Host "  Deployment Name: $($deployment.DeploymentName)"
Write-Host "  Provisioning  : $($deployment.ProvisioningState)"
Write-Host "  Timestamp     : $($deployment.Timestamp)"
Write-Host ""

# Xuất outputs
$outputs = @{}
foreach ($key in $deployment.Outputs.Keys) {
  $value = $deployment.Outputs[$key].Value
  $outputs[$key] = $value
  Write-Host "  📌 $key = $value" -ForegroundColor White
}

# Lưu outputs ra file (quan trọng: Instrumentation Key cho backend)
$outputs | ConvertTo-Json | Out-File $OutputFile -Encoding utf8
Write-Host "`n💾 Outputs đã lưu vào: $OutputFile" -ForegroundColor Cyan

# === HƯỚNG DẪN TIẾP THEO ===
Write-Host "`n📋 CÁC BƯỚC TIẾP THEO:" -ForegroundColor Yellow
Write-Host "  1. Lấy Instrumentation Key từ file: $OutputFile"
Write-Host "  2. Gắn vào backend/config.php (xem hướng dẫn trong file)"
Write-Host "  3. Commit & push lên GitHub để CI/CD chạy"
Write-Host "  4. Kiểm tra data trong Log Analytics: https://portal.azure.com"
Write-Host "`n═══════════════════════════════════════`n" -ForegroundColor Cyan
