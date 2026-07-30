// ============================================================
// MODULE: Recovery Services Vault (Backup)
// ============================================================
param vaultName string
param location string

resource vault 'Microsoft.RecoveryServices/vaults@2022-10-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Bật geo-redundancy cho backup
resource vaultBackupConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2023-01-01' = {
  parent: vault
  name: 'vaultconfig'
  properties: {
    storageType: 'GeoRedundant'
    storageTypeState: 'Locked'
  }
}

output vaultId string = vault.id
output vaultName string = vault.name
