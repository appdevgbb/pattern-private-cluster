terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.2.0"
    }
  }
}
