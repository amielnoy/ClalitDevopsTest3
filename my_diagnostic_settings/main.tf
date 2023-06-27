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
  name               = "my-diagnostics"
  target_resource_id = var.virtual_network.id

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  storage_account_id = var.storage_account_id
}




output "diagnostic_setting_id" {
  value = azurerm_monitor_diagnostic_setting.existing_monitor_diag.id
}
