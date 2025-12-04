/*
 * This block sets up the required providers for the Terraform configuration.
 */ 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "all"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine_scale_set {
      force_delete                  = true
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = false
    }
  }
}

data "azurerm_subscription" "current" {
}

resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = false
}

locals {
  prefix        = var.prefix
  suffix        = var.suffix
}