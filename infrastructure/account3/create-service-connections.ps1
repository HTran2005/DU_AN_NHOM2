<#
.SYNOPSIS
  Tạo Service Connection (Azure Resource Manager) trên Azure DevOps cho TOÀN BỘ dịch vụ TripTo.

.DESCRIPTION
  Liên kết tất cả account/subscription của dự án (3 account) vào Azure DevOps
  (Org: DuAnNhom2, Project: BAO_CAO) bằng cách:
    1. Tạo Service Principal (SPN) DÙNG CHUNG (Mode Shared) hoặc 1 SPN/account (Mode PerSubscription)
    2. Cấp quyền Reader trên từng subscription (đủ để báo cáo tài nguyên)
    3. Tạo Service Connection loại Azure Resource Manager qua Azure DevOps REST API
    4. (Tùy chọn -CollectReport) Thu thập tài nguyên + sinh báo cáo ngay trên máy này

.PARAMETER ParametersPath
  Đường dẫn file cấu hình parameters.json (mặc định: infrastructure/account3/parameters.json)

.PARAMETER Mode
  Shared          = 1 SPN + 1 Service Connection cho TẤT CẢ subscription (khi các account cùng 1 tenant Entra ID)
  PerSubscription = 1 SPN + 1 Service Connection cho MỖI account (khi các account nằm tenant khác nhau)

.PARAMETER Pat
  Personal Access Token Azure DevOps.
  Yêu cầu scopes: "Service Connections (Read & manage)" + "Build (Read & execute)".
  Nếu không truyền, đọc từ biến môi trường AZURE_DEVOPS_EXT_PAT.

.PARAMETER Force
  Nếu Service Connection đã tồn tại thì XÓA và tạo lại (cấp password SPN mới).

.PARAMETER CollectReport
  Sau khi tạo kết nối, chạy thu thập tài nguyên (collect-resources.ps1) + sinh báo cáo
  (generate-report.sh) ngay trên máy này.

.EXAMPLE
  .\create-service-connections.ps1 -Pat "xxxx"

.EXAMPLE
  .\create-service-connections.ps1 -Mode PerSubscription -Pat "xxxx" -Force

.EXAMPLE
  .\create-service-connections.ps1 -Pat "xxxx" -CollectReport
#>

[CmdletBinding()]
param(
  [string]$ParametersPath  = "infrastructure/account3/parameters.json",
  [ValidateSet("Shared", "PerSubscription")]
  [string]$Mode           = "Shared",
  [string]$Pat            = $env:AZURE_DEVOPS_EXT_PAT,
  [switch]$Force,
  [switch]$CollectReport,
  [string]$ReportDir      = "reports/inventory"
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# =========================================================
# KIỂM TRA ĐIỀU KIỆN TIÊN QUYẾT
# =========================================================
Write-Host ""
Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TripTo - Liên kết toàn bộ dịch vụ lên Azure DevOps" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Org     : (đọc từ parameters.json)"
Write-Host "  Mode    : $Mode"
Write-Host ""

if (-not $Pat) {
  Write-Error "❌ Thiếu PAT. Truyền -Pat hoặc đặt biến môi trường AZURE_DEVOPS_EXT_PAT."
  exit 1
}

$azPath = Get-Command az -ErrorAction SilentlyContinue
if (-not $azPath) {
  Write-Error "❌ Azure CLI chưa được cài đặt. Tải tại: https://aka.ms/installazurecliwindows"
  exit 1
}

if (-not (Test-Path $ParametersPath)) {
  Write-Error "❌ Không tìm thấy file cấu hình: $ParametersPath"
  exit 1
}
$config = Get-Content $ParametersPath -Raw | ConvertFrom-Json

if (-not $config.organization -or -not $config.project) {
  Write-Error "❌ parameters.json thiếu organization/project."
  exit 1
}

$org    = $config.organization
$project = $config.project
$baseSpnName = $config.servicePrincipalName
$baseConnName = $config.serviceConnectionName

# Kiểm tra đăng nhập Azure
$contextJson = az account show 2>$null
if ($LASTEXITCODE -ne 0 -or -not $contextJson) {
  Write-Warning "⚠️ Chưa đăng nhập Azure. Đang mở trình duyệt đăng nhập..."
  az login
  if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Đăng nhập Azure thất bại."
    exit 1
  }
}
$currentTenant = ($contextJson | ConvertFrom-Json).tenantId
Write-Host "✅ Đã đăng nhập Azure (tenant: $currentTenant)" -ForegroundColor Green

# =========================================================
# HÀM TIỆN ÍCH
# =========================================================
function Get-SubscriptionInfo {
  param([string]$SubscriptionId)
  $json = az account show --subscription $SubscriptionId 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $json) {
    return $null
  }
  return ($json | ConvertFrom-Json)
}

function New-SpnWithSecret {
  param([string]$SpnName)
  # Kiểm tra SPN đã tồn tại chưa → reset password (giữ idempotent)
  $exists = az ad sp list --display-name $SpnName --query "[0].appId" -o tsv 2>$null
  if ($LASTEXITCODE -eq 0 -and $exists) {
    Write-Host "  ↻ SPN '$SpnName' đã tồn tại → reset credential..." -ForegroundColor Yellow
    $reset = az ad sp credential reset --name $SpnName 2>$null
    if ($LASTEXITCODE -ne 0) {
      throw "Reset credential SPN '$SpnName' thất bại (cần quyền Application Administrator hoặc nhờ admin cấp quyền)."
    }
    return ($reset | ConvertFrom-Json)
  }
  Write-Host "  ➕ Tạo SPN '$SpnName'..." -ForegroundColor Yellow
  $created = az ad sp create-for-rbac --name $SpnName --role Reader 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "Tạo SPN thất bại: $created"
  }
  return ($created | ConvertFrom-Json)
}

function Grant-ReaderOnSubscription {
  param([string]$AppId, [string]$SubscriptionId, [string]$TenantId)
  $scope = "/subscriptions/$SubscriptionId"
  Write-Host "  🔑 Cấp Reader cho SPN trên subscription: $SubscriptionId (tenant $TenantId)"
  $out = az role assignment create --assignee $AppId --role Reader --scope $scope 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "Cấp role Reader thất bại (subscription $SubscriptionId): $out"
  }
}

function New-ServiceEndpoint {
  param(
    [string]$EndpointName,
    [string]$Description,
    [string]$SubscriptionId,
    [string]$SubscriptionName,
    [string]$TenantId,
    [string]$AppId,
    [string]$SpnKey
  )
  $uri = "https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4"
  $basic = ":" + $Pat
  $headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($basic))
  }

  # Kiểm tra endpoint đã tồn tại
  try {
    $list = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $found = $list.value | Where-Object { $_.name -eq $EndpointName }
  }
  catch {
    Write-Error "❌ Không đọc được danh sách Service Connection: $($_.Exception.Message)"
    Write-Host "   Kiểm tra PAT có scope 'Service Connections (Read & manage)' chưa?" -ForegroundColor Yellow
    throw
  }
  if ($found -and -not $Force) {
    Write-Host "  ⏭️  Service Connection '$EndpointName' đã tồn tại → bỏ qua (dùng -Force để tạo lại)" -ForegroundColor Yellow
    return
  }
  if ($found -and $Force) {
    Write-Host "  🗑️  Xóa Service Connection cũ '$EndpointName'..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri "https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints/$($found.id)?api-version=7.1-preview.4" -Headers $headers -Method Delete | Out-Null
  }

  $body = @{
    authorization = @{
      parameters = @{
        authenticationType = "spnKey"
        serviceprincipalid  = $AppId
        serviceprincipalkey = $SpnKey
        tenantid            = $TenantId
      }
      scheme = "ServicePrincipal"
    }
    data = @{
      subscriptionId   = $SubscriptionId
      subscriptionName = $SubscriptionName
      environment      = "AzureCloud"
      scopeLevel       = "Subscription"
      creationMode     = "Manual"
    }
    name        = $EndpointName
    type        = "azurerm"
    url         = "https://management.azure.com/"
    description = $Description
    isReady     = $true
    serviceEndpointProjectReferences = @(
      @{
        projectReference = @{ name = $project }
        name             = $EndpointName
        description      = $Description
      }
    )
  } | ConvertTo-Json -Depth 10

  try {
    $result = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -ContentType "application/json" -Body $body
    Write-Host "  ✅ Service Connection '$EndpointName' đã tạo (id: $($result.id))" -ForegroundColor Green
  }
  catch {
    Write-Error "❌ Tạo Service Connection thất bại: $($_.Exception.Message)"
    Write-Host "   Kiểm tra: PAT có scope 'Service Connections (Read & manage)' chưa?" -ForegroundColor Yellow
    throw
  }
}

# =========================================================
# THỰC THI
# =========================================================
Write-Host ""
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  BƯỚC 1: Liệt kê subscription hợp lệ" -ForegroundColor DarkCyan
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan

$accounts = @()
foreach ($acc in $config.accounts) {
  if (-not $acc.subscriptionId) {
    Write-Host "  ⏭️  $($acc.key) ($($acc.name)): chưa có subscriptionId → bỏ qua" -ForegroundColor DarkGray
    continue
  }
  $info = Get-SubscriptionInfo -SubscriptionId $acc.subscriptionId
  if (-not $info) {
    Write-Warning "  ⚠️  $($acc.key): không truy cập được subscription $($acc.subscriptionId)."
    Write-Host "      → Chạy 'az login' với tài khoản sở hữu account này rồi chạy lại script." -ForegroundColor Yellow
    continue
  }
  $accounts += [pscustomobject]@{
    Key              = $acc.key
    Name             = $acc.name
    Label            = $acc.label
    SubscriptionId   = $acc.subscriptionId
    SubscriptionName = if ($info.name) { $info.name } else { $acc.subscriptionName }
    TenantId         = $info.tenantId
  }
  Write-Host "  ✓ $($acc.key) | $($info.name) | tenant $($info.tenantId)" -ForegroundColor Green
}

if ($accounts.Count -eq 0) {
  Write-Error "❌ Không có subscription nào hợp lệ. Hãy điền subscriptionId vào parameters.json."
  exit 1
}

Write-Host ""
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  BƯỚC 2: Tạo Service Principal + cấp quyền" -ForegroundColor DarkCyan
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan

$endpoints = @()

if ($Mode -eq "Shared") {
  $spn = New-SpnWithSecret -SpnName $baseSpnName
  $grantedAccounts = @()
  foreach ($acc in $accounts) {
    if ($acc.TenantId -ne $spn.tenant) {
      Write-Warning "  ⚠️  $($acc.Key) ở tenant $($acc.TenantId) khác tenant SPN ($($spn.tenant))."
      Write-Host "      → Không thể cấp quyền cho SPN dùng chung. Dùng -Mode PerSubscription cho trường hợp này." -ForegroundColor Yellow
      continue
    }
    try {
      Grant-ReaderOnSubscription -AppId $spn.appId -SubscriptionId $acc.SubscriptionId -TenantId $acc.TenantId
      $grantedAccounts += $acc
    }
    catch {
      Write-Warning "  ⚠️  Cấp quyền thất bại cho $($acc.Key): $($_.Exception.Message)"
    }
  }
  if ($grantedAccounts.Count -eq 0) {
    Write-Error "❌ Không cấp được quyền Reader cho account nào trong chế độ Shared."
    exit 1
  }
  # Service Connection scope vào subscription ĐẦU TIÊN đã cấp quyền thành công
  $scopeAcc = $grantedAccounts[0]
  $endpoints += @{
    Key        = "ALL"
    Name       = $baseConnName
    Description = "TripTo - Service Connection dùng chung cho toàn bộ account (Reader)"
    SubscriptionId   = $scopeAcc.SubscriptionId
    SubscriptionName = $scopeAcc.SubscriptionName
    TenantId         = $spn.tenant
    AppId            = $spn.appId
    SpnKey           = $spn.password
  }
}
else {
  foreach ($acc in $accounts) {
    $spnName = "$baseSpnName-$($acc.Key.ToLower())"
    Write-Host ""
    Write-Host "  -- $($acc.Key) ($($acc.Label)) --" -ForegroundColor Yellow
    # Chuyển context sang đúng subscription để SPN được tạo đúng tenant của account
    az account set --subscription $acc.SubscriptionId 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "  ⚠️  Không chuyển được context sang subscription $($acc.SubscriptionId). SPN sẽ tạo ở tenant hiện tại."
    }
    $spn = New-SpnWithSecret -SpnName $spnName
    Grant-ReaderOnSubscription -AppId $spn.appId -SubscriptionId $acc.SubscriptionId -TenantId $acc.TenantId
    $endpoints += @{
      Key        = $acc.Key
      Name       = "$baseConnName-$($acc.Key)"
      Description = "TripTo - $($acc.Label) ($($acc.Name)) - Reader"
      SubscriptionId   = $acc.SubscriptionId
      SubscriptionName = $acc.SubscriptionName
      TenantId         = $spn.tenant
      AppId            = $spn.appId
      SpnKey           = $spn.password
    }
  }
}

Write-Host ""
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  BƯỚC 3: Tạo Service Connection trên Azure DevOps" -ForegroundColor DarkCyan
Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  Org: $org | Project: $project" -ForegroundColor Gray
Write-Host ""

foreach ($ep in $endpoints) {
  New-ServiceEndpoint -EndpointName $ep.Name -Description $ep.Description `
    -SubscriptionId $ep.SubscriptionId -SubscriptionName $ep.SubscriptionName `
    -TenantId $ep.TenantId -AppId $ep.AppId -SpnKey $ep.SpnKey
}

Write-Host ""
Write-Host "══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ HOÀN TẤT - LIÊN KẾT AZURE DEVOPS" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Org       : $org"
Write-Host "  Project   : $project"
foreach ($ep in $endpoints) {
  Write-Host "  Connection : $($ep.Name)  (subscription $($ep.SubscriptionId))"
}
Write-Host ""
Write-Host "  Kiểm tra trên Portal: Project Settings → Service connections" -ForegroundColor White
Write-Host "  (Chờ vài giây để Azure DevOps verify kết nối trước khi chạy pipeline)" -ForegroundColor DarkGray
Write-Host ""

# =========================================================
# (TÙY CHỌN) THU THẬP + SINH BÁO CÁO LOCAL
# =========================================================
if ($CollectReport) {
  Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
  Write-Host "  BƯỚC 4: Thu thập tài nguyên + sinh báo cáo" -ForegroundColor DarkCyan
  Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  & (Join-Path $scriptDir "collect-resources.ps1") -ParametersPath $ParametersPath -ReportDir $ReportDir
  if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Thu thập tài nguyên thất bại."
    exit 1
  }
}

Write-Host "`n✨ Xong! Tiếp theo: import pipeline 'azure-pipelines-report.yml' vào DevOps (xem docs/LIEN_KET_DEV_OPS_ACCOUNT3.md)." -ForegroundColor Cyan
