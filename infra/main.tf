provider "azurerm" {
  features {}
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
    vm_size    = "Standard_B2s"
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