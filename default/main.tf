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
  subscription_id                 = "<SUBSCRIPTION_ID>"
  storage_use_azuread             = true
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

variable "azure_container_instance_oid" {
  description = "Object ID of the Azure Container Instance Service enterprise app."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for Cloud Shell (must be globally unique)."
  type        = string
}

variable "relay_namespace_name" {
  description = "Azure Relay namespace name for Cloud Shell."
  type        = string
  default     = "arn-cloudshell"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)."
  type        = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "api_server_subnet" {
  name                 = "api-server-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
  delegation {
    name = "aks-delegation"
    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Cloud Shell subnets
resource "azurerm_subnet" "cloudshell_container" {
  name                 = "cloudshellsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.3.0/24"]

  delegation {
    name = "cloudshell-delegation"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet" "cloudshell_relay" {
  name                 = "relaysubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.4.0/24"]
}

resource "azurerm_subnet" "cloudshell_storage_pe" {
  name                 = "storage-pe-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.5.0/24"]
}

resource "azurerm_subnet" "acr_subnet" {
  name                 = "acr-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.6.0/24"]
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "aks-identity-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_user_assigned_identity" "kubelet_identity" {
  name                = "kubelet-identity-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

# ACR Resources for Network Isolation
resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Premium"
  public_network_access_enabled = false
  admin_enabled                 = false
}

# ACR Cache Rule - CRITICAL for network isolated clusters
resource "azurerm_container_registry_cache_rule" "aks_managed" {
  name                  = "aks-managed-mcr"
  container_registry_id = azurerm_container_registry.acr.id
  source_repo           = "mcr.microsoft.com/*"
  target_repo           = "aks-managed-repository/*"
  credential_set_id     = null
}

# Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_link" {
  name                  = "acr-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Private Endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  name                = "acr-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.acr_subnet.id

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

# Grant AcrPull role to Kubelet identity
resource "azurerm_role_assignment" "kubelet_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet_identity.principal_id
}

# Grant Managed Identity Operator role to AKS control plane identity over kubelet identity
resource "azurerm_role_assignment" "aks_identity_operator" {
  scope                = azurerm_user_assigned_identity.kubelet_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azurerm_kubernetes_cluster" "private_aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "pvt-example"

  default_node_pool {
    name           = "system"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false

  api_server_access_profile {
    virtual_network_integration_enabled = true
    subnet_id                           = azurerm_subnet.api_server_subnet.id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "none"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  bootstrap_profile {
    artifact_source           = "Cache"
    container_registry_id = azurerm_container_registry.acr.id
  }

  depends_on = [
    azurerm_role_assignment.network_contributor,
    azurerm_role_assignment.kubelet_acr_pull,
    azurerm_role_assignment.aks_identity_operator,
    azurerm_private_endpoint.acr,
    azurerm_container_registry_cache_rule.aks_managed
  ]
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.private_aks.name
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.private_aks.kube_config_raw
  sensitive = true
}

########################################
# Cloud Shell Infrastructure
########################################

data "azurerm_client_config" "current" {}

# Network Security Group for Cloud Shell
resource "azurerm_network_security_group" "cloudshell" {
  name                = "nsg-cloudshell"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "cloudshell_outbound_internet" {
  name                        = "AllowOutboundInternet"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cloudshell.name
}

resource "azurerm_subnet_network_security_group_association" "container_nsg" {
  subnet_id                 = azurerm_subnet.cloudshell_container.id
  network_security_group_id = azurerm_network_security_group.cloudshell.id
}

# Relay Namespace
resource "azurerm_relay_namespace" "cloudshell" {
  name                = var.relay_namespace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

# Private DNS for Relay
resource "azurerm_private_dns_zone" "relay" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "relay_link" {
  name                  = "${var.relay_namespace_name}-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.relay.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# Private Endpoint for Relay
resource "azurerm_private_endpoint" "relay" {
  name                = "cloudshellRelayEndpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cloudshell_relay.id

  private_service_connection {
    name                           = "cloudshellRelayConnection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_relay_namespace.cloudshell.id
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "relay-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.relay.id]
  }
}

# Network Profile for ACI
resource "azurerm_network_profile" "cloudshell_aci" {
  name                = "aci-networkProfile-${var.location}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "cloudshell-aci-nic"

    ip_configuration {
      name      = "ipconfig1"
      subnet_id = azurerm_subnet.cloudshell_container.id
    }
  }
}

# Role assignment for Azure Container Instance SP
resource "azurerm_role_assignment" "aci_contributor_on_relay" {
  scope                = azurerm_relay_namespace.cloudshell.id
  role_definition_name = "Contributor"
  principal_id         = var.azure_container_instance_oid
}

# Storage account for Cloud Shell
resource "azurerm_storage_account" "cloudshell" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_link" {
  name                  = "storage-blob-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_link" {
  name                  = "storage-file-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# Private Endpoints for Storage
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "cloudshell-storage-blob-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cloudshell_storage_pe.id

  private_service_connection {
    name                           = "storage-blob-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.cloudshell.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }
}

resource "azurerm_private_endpoint" "storage_file" {
  name                = "cloudshell-storage-file-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cloudshell_storage_pe.id

  private_service_connection {
    name                           = "storage-file-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.cloudshell.id
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "storage-file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }
}

# Storage share
resource "azurerm_storage_share" "cloudshell" {
  name               = "acsshare"
  storage_account_id = azurerm_storage_account.cloudshell.id
  quota              = 50
}

# Cloud Shell outputs
output "cloudshell_container_subnet_id" {
  value       = azurerm_subnet.cloudshell_container.id
  description = "Subnet hosting Cloud Shell containers."
}

output "cloudshell_storage_account_name" {
  value       = azurerm_storage_account.cloudshell.name
  description = "Storage account for Cloud Shell."
}

output "cloudshell_relay_namespace_name" {
  value       = azurerm_relay_namespace.cloudshell.name
  description = "Relay namespace used by Cloud Shell."
}