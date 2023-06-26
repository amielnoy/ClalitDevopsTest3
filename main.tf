resource "azurerm_resource_group" "amiel_az_resource" {
  name     = "amiel-resource-group2"
  location = "West US"
}

resource "azurerm_virtual_network" "amiel_vpn" {
  name                = "amiel-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.amiel_az_resource.location
  resource_group_name = azurerm_resource_group.amiel_az_resource.name
}

resource "azurerm_subnet" "amiel_subnet" {
  name                 = "amiel-subnet"
  resource_group_name  = azurerm_resource_group.amiel_az_resource.name
  virtual_network_name = azurerm_virtual_network.amiel_vpn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "amiel_storage" {
  name                     = "amielstorageaccount"
  resource_group_name      = azurerm_resource_group.amiel_az_resource.name
  location                 = azurerm_resource_group.amiel_az_resource.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "azure_amiel_service_plan" {
  name                = "amiel-app-service-plan"
  location            = azurerm_resource_group.amiel_az_resource.location
  resource_group_name = azurerm_resource_group.amiel_az_resource.name
  kind                = "FunctionApp"
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "amiel_az_func_app" {
  name                = "amiel-function-app"
  location            = azurerm_resource_group.amiel_az_resource.location
  resource_group_name = azurerm_resource_group.amiel_az_resource.name
  app_service_plan_id = azurerm_app_service_plan.azure_amiel_service_plan.id
  version             = "~3"

  app_settings = {
    "AzureWebJobsStorage"                      = azurerm_storage_account.amiel_storage.primary_connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.amiel_storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = "azure-webjobs-hosts"
    "AzureWebJobsDashboard"                    = azurerm_storage_account.amiel_storage.primary_connection_string
    "storage_account_name"                     = azurerm_storage_account.amiel_storage.name
    "storage_account_access_key"               = azurerm_storage_account.amiel_storage.primary_access_key
  }

  identity {
    type = "SystemAssigned"
  }
  storage_account_name       = azurerm_storage_account.amiel_storage.name
  storage_account_access_key = azurerm_storage_account.amiel_storage.primary_access_key
}

resource "azurerm_role_assignment" "amiel_role_assignment" {
  scope                = azurerm_storage_account.amiel_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.amiel_az_func_app.identity[0].principal_id
}



resource "azurerm_private_dns_zone" "amiel_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.amiel_az_resource.name
}



resource "azurerm_private_endpoint" "amiel_private_endpoint" {
  name                  = "amiel-private-endpoint"
  location              = azurerm_resource_group.amiel_az_resource.location
  resource_group_name   = azurerm_resource_group.amiel_az_resource.name
  subnet_id             = azurerm_subnet.amiel_subnet.id

  private_service_connection {
    name                       = azurerm_function_app.amiel_az_func_app.name
    is_manual_connection       = false
    private_connection_resource_id = azurerm_function_app.amiel_az_func_app.id
    subresource_names          = ["sites"]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "amiel_dns_vnet_link" {
  name                  = "amiel-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.amiel_az_resource.name
  private_dns_zone_name = azurerm_private_dns_zone.amiel_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.amiel_vpn.id
  registration_enabled  = true
}

resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                  = "storage-private-endpoint"
  location              = azurerm_resource_group.amiel_az_resource.location
  resource_group_name   = azurerm_resource_group.amiel_az_resource.name
  subnet_id             = azurerm_subnet.amiel_subnet.id

  private_service_connection {
    name                       = azurerm_storage_account.amiel_storage.name
    is_manual_connection       = false
    private_connection_resource_id = azurerm_storage_account.amiel_storage.id
    subresource_names          = ["blob"]
  }
}


output "resource_group_name" {
  value = azurerm_resource_group.amiel_az_resource.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.amiel_vpn.name
}

output "subnet_name" {
  value = azurerm_subnet.amiel_subnet.name
}

output "storage_account_name" {
  value = azurerm_storage_account.amiel_storage.name
}

output "app_service_plan_name" {
  value = azurerm_app_service_plan.azure_amiel_service_plan.name
}

output "function_app_name" {
  value = azurerm_function_app.amiel_az_func_app.name
}

output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.amiel_dns_zone.name
}

resource "azurerm_monitor_diagnostic_setting" "amiel_monitor_diag" {
  name               = "my-diagnostics"
  target_resource_id = azurerm_virtual_network.amiel_vpn.id
  storage_account_id = azurerm_storage_account.amiel_storage.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
