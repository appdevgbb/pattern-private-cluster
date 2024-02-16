/*
 * This block of code sets up the required providers for the Terraform configuration, 
 * including the azurerm provider and the azapi provider. It also configures the azurerm provider 
 * to enable certain features, such as preventing deletion of resource groups that contain 
 * resources and rolling instances when required. Additionally, it defines several resources, 
 * including a random string suffix, a random password for a certificate, and a local variable 
 * for the zone name.
 */ 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.88.0"
    }
  }
}

provider "azurerm" {
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

data "http" "myip" {
  url = "https://api.ipify.org/"
}

resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = false
}

resource "random_password" "cert_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

locals {
  prefix        = var.prefix
  suffix        = var.suffix
  cert_password = random_password.cert_password.result
  zone_name     = "${var.location}.${var.custom_domain}"
}