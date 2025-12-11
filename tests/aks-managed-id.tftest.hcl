provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "24a4c592-bfaf-492f-beaf-f10b3b67f03f"
}

variables {
  location = "westus3"
}

run "name" {
  module {
    source = "./testing/prereq-name"
  }
}

run "resource_group" {
  module {
    source = "./testing/prereq-rg"
  }
}

run "network" {
  module {
    source = "./testing/prereq-network"
  }

  variables {
    resource_group_name = run.resource_group.resource_group_name
    location            = var.location
    application_name    = "tft-${run.name.suffix}"
    environment_name    = "test"
    vnet_address_space  = "10.1.0.0/16"
  }
}

run "vm_size" {
  module {
    source = "./testing/prereq-vm-size"
  }

  variables {
    location      = var.location
    vcpu_min      = 2
    vcpu_max      = 8
    memory_gb_min = 4
    memory_gb_max = 8
    name_filter   = "D"
  }

  providers = {
    azurerm = azurerm
  }

}

# Provision the AKS Cluster
run "provision" {

  command = apply

  module {
    source = "./src/terraform/aks-managed-id"
  }

  variables {
    resource_group_name = run.resource_group.resource_group_name
    location            = var.location
    application_name    = "tft-${run.name.suffix}"
    environment_name    = "test"
    vm_size             = run.vm_size.candidate_sku
    aks_subnet_id       = run.network.aks_subnet_id
    aks_api_subnet_id   = run.network.api_server_subnet_id
    acr_subnet_id       = run.network.acr_subnet_id
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.main.name) > 0
    error_message = "Must have a valid AKS Cluster Name"
  }
}
