variable "enable_diagnostic_settings" {
  description = "Flag to enable/disable diagnostic settings"
  type        = bool
  default     = false
}

variable "virtual_network_resource_group" {
  description = "Resource group containing the virtual network"
  type        = object({
    name     = string
    location = string
  })
}

variable "virtual_network" {
  description = "Virtual network to apply diagnostic settings"
  type        = object({
    name                = string
    resource_group_name = string
    id                  = string
  })
}

variable "storage_account_id" {
  description = "ID of the storage account to store diagnostic logs"
  type        = string
}

resource "azurerm_monitor_diagnostic_setting" "existing_monitor_diag" {
  name               = "my-diagnostics-111"
  target_resource_id = "/subscriptions/441b9518-6510-4fa6-9882-fa9d2d75513e/resourceGroups/amiel-resource-group2/providers/Microsoft.Network/virtualNetworks/amiel-vnet"
  storage_account_id = "/subscriptions/441b9518-6510-4fa6-9882-fa9d2d75513e/resourceGroups/amiel-resource-group2/providers/Microsoft.Storage/storageAccounts/amielstorageaccount111"

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

output "diagnostic_setting_id" {
  value = azurerm_monitor_diagnostic_setting.existing_monitor_diag.id
}
