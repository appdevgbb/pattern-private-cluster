provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "24a4c592-bfaf-492f-beaf-f10b3b67f03f"
}

variables {
  application_name = "aks-tf-tests"
  environment_name = "test"
  location         = "westus3"
}

// Sample Setup. This could setup any pre-requisites needed for the test. 
//  Perhaps stage some data or files in a storage account.
run "setup" {
  module {
    source = "./testing/setup"
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
    source = "./src/terraform/aks-baseline"
  }

  variables {
    vm_size = run.setup.candidate_sku
  }

  providers = {
    azurerm = azurerm
  }

  assert {
    condition     = length(data.azurerm_resource_group.main.name) > 0
    error_message = "Must have a valid Resource Group Name"
  }
}

