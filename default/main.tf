terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "all"
}

variable "location" {
  description = "The Azure region to deploy resources to."
  type        = string
  default     = "westus3"
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
  default     = "pvt-cluster-example"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-pvt-cluster-example"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "private_aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "pvt-example"

  sku_tier = "Free"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  identity {
    type = "SystemAssigned"
  }

  private_cluster_enabled = true
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.private_aks.name
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.private_aks.kube_config_raw
  sensitive = true
}
