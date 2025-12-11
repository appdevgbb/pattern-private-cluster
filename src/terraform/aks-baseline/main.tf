resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.application_name}-${var.environment_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "aks${var.application_name}"

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
