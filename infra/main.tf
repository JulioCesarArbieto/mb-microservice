provider "azurerm" {
  features {}
  #subscription_id = "xxx"
  #client_id       = "xxx"
  #client_secret   = "xxx"
  #tenant_id       = "xxx"
}

resource "azurerm_resource_group" "rg" {
  name     = "mibanco-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mibanco-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "mibancoaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "mibancoacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Azure API Management
resource "azurerm_api_management" "apim" {
  name                = "mibanco-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Mibanco"
  publisher_email     = "admin@mibanco.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "api" {
  name                = "mibanco-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Mibanco API"
  path                = "mibanco"
  protocols           = ["https"]
  service_url         = "https://${azurerm_api_management.apim.gateway_url}"
}

resource "azurerm_api_management_api_operation" "get_hello" {
  operation_id        = "get-hello"
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Hello"
  method              = "GET"
  url_template        = "/"
  response {
    status_code  = 200
    description = "OK"
  }
}

resource "azurerm_api_management_api_policy" "policy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
</policies>
XML
}