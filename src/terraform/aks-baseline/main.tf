data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

data "azurerm_resource_group" "main" {
  name = "rg-pvt-aks-cluster-tf-test"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "aks${var.application_name}${random_string.suffix.result}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}
