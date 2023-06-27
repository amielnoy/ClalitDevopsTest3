resource "azurerm_resource_group" "amiel_az_resource" {
  count = var.create_resource_group ? 1 : 0

  name     = "amiel-resource-group2"
  location = "West US"
}

resource "azurerm_virtual_network" "amiel_vpn" {
  name                = "amiel-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.amiel_az_resource[0].location
  resource_group_name = azurerm_resource_group.amiel_az_resource[0].name
}

resource "azurerm_storage_account" "amiel_storage" {
  name                     = "amielstorageaccount"
  resource_group_name      = azurerm_resource_group.amiel_az_resource[0].name
  location                 = azurerm_resource_group.amiel_az_resource[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "azure_amiel_service_plan" {
  count                = var.create_resource_group ? 1 : 0
  name                = "amiel-app-service-plan"
  location            = azurerm_resource_group.amiel_az_resource[count.index].location
  resource_group_name = azurerm_resource_group.amiel_az_resource[count.index].name
  kind                = "FunctionApp"
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "amiel_az_func_app" {
  name                = "amiel-function-app"
  location            = azurerm_resource_group.amiel_az_resource[0].location
  resource_group_name = azurerm_resource_group.amiel_az_resource[0].name
  app_service_plan_id = azurerm_app_service_plan.azure_amiel_service_plan[0].id
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

resource "azurerm_private_dns_zone" "amiel_dns_zone" {
  count                = var.create_resource_group ? 1 : 0
  name                 = "privatelink.azurewebsites.net"
  resource_group_name  = azurerm_resource_group.amiel_az_resource[count.index].name
}


resource "azurerm_subnet" "amiel_subnet" {
  count                  = var.create_resource_group ? 1 : 0
  name                 = "amiel-subnet"
  resource_group_name  = azurerm_resource_group.amiel_az_resource[count.index].name
  virtual_network_name = azurerm_virtual_network.amiel_vpn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_role_assignment" "amiel_role_assignment" {
  scope                = azurerm_storage_account.amiel_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.amiel_az_func_app.identity[0].principal_id
}

resource "azurerm_private_endpoint" "function_app_private_endpoint" {
  count                  = var.create_resource_group ? 1 : 0
  name                  = "func-app-private-endpoint"
  location              = azurerm_resource_group.amiel_az_resource[count.index].location
  resource_group_name   = azurerm_resource_group.amiel_az_resource[count.index].name
  subnet_id             = azurerm_subnet.amiel_subnet[count.index].id

  private_service_connection {
    name                       = azurerm_function_app.amiel_az_func_app.name
    is_manual_connection       = false
    private_connection_resource_id = azurerm_function_app.amiel_az_func_app.id
    subresource_names          = ["sites"]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "amiel_dns_vnet_link" {
  count                  = var.create_resource_group ? 1 : 0
  name                   = "amiel-dns-vnet-link"
  resource_group_name    = azurerm_resource_group.amiel_az_resource[count.index].name
  private_dns_zone_name  = azurerm_private_dns_zone.amiel_dns_zone[count.index].name
  virtual_network_id     = azurerm_virtual_network.amiel_vpn.id
  registration_enabled   = true
}

resource "azurerm_private_endpoint" "storage_private_endpoint" {
  count                  = var.create_resource_group ? 1 : 0
  name                  = "storage-private-endpoint"
  location              = azurerm_resource_group.amiel_az_resource[count.index].location
  resource_group_name   = azurerm_resource_group.amiel_az_resource[count.index].name
  subnet_id             = azurerm_subnet.amiel_subnet[count.index].id

  private_service_connection {
    name                       = azurerm_storage_account.amiel_storage.name
    is_manual_connection       = false
    private_connection_resource_id = azurerm_storage_account.amiel_storage.id
    subresource_names          = ["blob"]
  }
}




module "diagnostic_settings" {
  source                        = "./my_diagnostic_settings"
  enable_diagnostic_settings    = var.create_resource_group
  virtual_network_resource_group = azurerm_resource_group.amiel_az_resource[0]
  virtual_network               = azurerm_virtual_network.amiel_vpn
  storage_account_id            = azurerm_storage_account.amiel_storage.id
}
