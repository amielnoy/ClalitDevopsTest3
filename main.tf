#provider "azurerm" {
#  features {}
#
#  subscription_id = "441b9518-6510-4fa6-9882-fa9d2d75513e"
#  client_id       = "5dc776b1-1400-4044-bba6-98dfe595d9b7"
#  client_secret   = "K1x8Q~hCLAGnNXvx66D8Jjz0WQgwBDBgAOjGtbXu"
#  tenant_id       = "eb942138-7243-491f-8654-718908188a40"
#}

resource "azurerm_resource_group" "amiel_az_resource" {
  name     = "amiel-resource-group"
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

resource "azurerm_app_service_plan" "azure_amiel_serice_plan" {
  name                = "amiel_app_service_plan"
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
  app_service_plan_id = azurerm_app_service_plan.azure_amiel_serice_plan.id
  version             = "~3"

  app_settings = {
    "AzureWebJobsStorage"                      = azurerm_storage_account.amiel_storage.primary_connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.amiel_storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = "azure-webjobs-hosts"
    "AzureWebJobsDashboard"                    = azurerm_storage_account.amiel_storage.primary_connection_string
  }

  storage_account_access_key = "2kLa2It+zMlqn+lsV9bdyu/DGEsW/kiHRICSkasAm8IuH1nasNgc/1gw0lj78ScTPCk9ilQ1wcvx+ASt5hRCYg=="
  storage_account_name       = "amielstorageaccount"
}

resource "azurerm_private_dns_zone" "amiel_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.amiel_az_resource.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "amiel_dns_vnet_link" {
  name                  = "amiel-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.amiel_az_resource.name
  private_dns_zone_name = azurerm_private_dns_zone.amiel_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.amiel_vpn.id
  registration_enabled  = true
}

resource "azurerm_private_endpoint" "amiel_private_endpoint" {
  name                  = "amiel-private-endpoint"
  location              = azurerm_resource_group.amiel_az_resource.location
  resource_group_name   = azurerm_resource_group.amiel_az_resource.name
  subnet_id             = azurerm_subnet.amiel_subnet.id

  private_service_connection {
    name                       = "amiel-private-connection"
    is_manual_connection       = false
    private_connection_resource_id = azurerm_function_app.amiel_az_func_app.id
    subresource_names          = ["sites"]
  }
}


resource "azurerm_private_endpoint" "amiel_storage_endpoint" {
  name                  = "amiel-storage-endpoint"
  location              = azurerm_resource_group.amiel_az_resource.location
  resource_group_name   = azurerm_resource_group.amiel_az_resource.name
  subnet_id             = azurerm_subnet.amiel_subnet.id

  private_service_connection {
    name                       = "amiel-storage-connection"
    is_manual_connection       = false
    private_connection_resource_id = azurerm_storage_account.amiel_storage.id
    subresource_names          = ["blob"]
  }
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
