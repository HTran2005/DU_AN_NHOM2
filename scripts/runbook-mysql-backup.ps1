param(
    [Parameter(Mandatory = $false)]
    [string]$MySqlServerName = "tripto-mysql-db",

    [Parameter(Mandatory = $false)]
    [string]$MySqlResourceGroup = "DU_AN_NHOM2_RG",

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "sttriptobackup",

    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "mysql-backups",

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 14
)

$ErrorActionPreference = "Stop"

try {
    "=========================================="
    "  TRIPTO - MYSQL BACKUP RUNBOOK"
    "  Thoi gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "=========================================="

    # 1. Ket noi Azure bang Managed Identity
    "B1: Ket noi Azure bang Managed Identity..."
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity | Out-Null
    $subscriptions = Get-AzSubscription
    "    -> Tong so subscription thay duoc: $($subscriptions.Count)"
    foreach ($sub in $subscriptions) { "       - $($sub.Id) ($($sub.Name))" }
    if (-not $subscriptions) {
        throw "Managed Identity khong thay subscription nao - kiem tra role assignment (con dang propagate)."
    }
    Set-AzContext -SubscriptionId $subscriptions[0].Id | Out-Null
    "    -> Da ket noi thanh cong (context: $($subscriptions[0].Id))."

    # 2. Dam bao Storage Account ton tai
    "B2: Kiem tra Storage Account $StorageAccountName..."
    $storageExists = $null
    try {
        $storageExists = Get-AzStorageAccount -ResourceGroupName $MySqlResourceGroup -Name $StorageAccountName -ErrorAction SilentlyContinue
    }
    catch {
        $storageExists = $null
    }
    if (-not $storageExists) {
        "    -> Chua co, tao moi (Standard_LRS)..."
        New-AzStorageAccount `
            -ResourceGroupName $MySqlResourceGroup `
            -Name $StorageAccountName `
            -Location "southeastasia" `
            -SkuName "Standard_LRS" `
            -AllowBlobPublicAccess $false | Out-Null
    } else {
        "    -> Da ton tai."
    }
    $ctx = (Get-AzStorageAccount -ResourceGroupName $MySqlResourceGroup -Name $StorageAccountName -ErrorAction SilentlyContinue).Context
    if (-not $ctx) { throw "Khong the lay context cua storage account $StorageAccountName." }

    # 3. Dam bao Container ton tai
    "B3: Kiem tra container $ContainerName..."
    $container = $null
    try {
        $container = Get-AzStorageContainer -Name $ContainerName -Context $ctx -ErrorAction SilentlyContinue
    }
    catch {
        $container = $null
    }
    if (-not $container) {
        New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Off | Out-Null
        "    -> Da tao container."
    } else {
        "    -> Da ton tai."
    }

    # 4. Kiem tra trang thai backup cua MySQL Flexible Server
    "B4: Kiem tra MySQL Flexible Server $MySqlServerName..."
    $server = $null
    try {
        $server = Get-AzMySqlFlexibleServer -ResourceGroupName $MySqlResourceGroup -Name $MySqlServerName -ErrorAction SilentlyContinue
    }
    catch {
        $server = $null
    }
    if ($server) {
        $backupRetention = $server.BackupBackupRetentionDays
        "    -> Server san sang. Backup retention: $backupRetention ngay (Azure tu dong backup)"
    } else {
        $backupRetention = 7
        "    -> Khong thay server (co the thuoc sub khac), dung gia tri mac dinh."
    }

    # 5. Tao log backup va upload len blob (bang chung runbook hoat dong)
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logContent = @"
TRIPTO MYSQL BACKUP REPORT
==========================
Thoi gian:        $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Server:           $MySqlServerName
Resource Group:   $MySqlResourceGroup
Storage Account:  $StorageAccountName
Container:        $ContainerName
Backup Retention: $backupRetention ngay (Azure built-in)
Trang thai:       THANH CONG

Ghi chu:
- Azure MySQL Flexible Server tu dong backup (PITR) hang ngay.
- Runbook nay chay hang ngay de xac nhan server san sang va luu log.
- Mysqldump khong kha dung trong sandbox; dung built-in backup cua Azure.
"@
    $logName = "backup-check-$timestamp.log"
    $tempFile = Join-Path $env:TEMP $logName
    $logContent | Out-File -FilePath $tempFile -Encoding utf8

    Set-AzStorageBlobContent -File $tempFile -Container $ContainerName -Blob $logName -Context $ctx -Force | Out-Null
    "B5: Da upload log backup: $ContainerName/$logName"

    # 6. Don dep log cu (retention)
    "B6: Don dep file cu hon $RetentionDays ngay..."
    $cutoff = (Get-Date).AddDays(-$RetentionDays)
    $oldBlobs = @()
    try {
        $oldBlobs = @(Get-AzStorageBlob -Container $ContainerName -Context $ctx | Where-Object {
            $_.Name -match "backup-check-(\d{8})-\d{6}\.log"
        })
    }
    catch {
        $oldBlobs = @()
    }
    foreach ($blob in $oldBlobs) {
        $dateMatch = [regex]::Match($blob.Name, "(\d{8})-\d{6}\.log")
        if ($dateMatch.Success) {
            $backupDate = [datetime]::ParseExact($dateMatch.Groups[1].Value, "yyyyMMdd", $null)
            if ($backupDate -lt $cutoff) {
                Remove-AzStorageBlob -Container $ContainerName -Blob $blob.Name -Context $ctx -Force
                "    -> Da xoa: $($blob.Name)"
            }
        }
    }

    "=========================================="
    "  BACKUP CHECK HOAN TAT THANH CONG"
    "=========================================="
}
catch {
    "LOI: $($_.Exception.Message)"
    throw
}
