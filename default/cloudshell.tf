########################################
# Network Profile for ACI
########################################

resource "azurerm_network_profile" "cloudshell" {
  name                = "np-cloudshell-${var.location}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  container_network_interface {
    name = "cloudshell-aci-nic"

    ip_configuration {
      name      = "ipconfig1"
      subnet_id = azurerm_subnet.cloudshell_container.id
    }
  }
}

########################################
# Azure Relay Namespace
########################################

resource "azurerm_relay_namespace" "cloudshell" {
  name                = local.relay_namespace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
  tags                = var.tags
}

########################################
# Relay Private Endpoint
########################################

resource "azurerm_private_endpoint" "relay" {
  name                = "pe-relay-${local.relay_namespace_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cloudshell_relay.id
  tags                = var.tags

  private_service_connection {
    name                           = "relay-connection"
    private_connection_resource_id = azurerm_relay_namespace.cloudshell.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "relay-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.relay.id]
  }
}

########################################
# Storage Account
########################################

resource "azurerm_storage_account" "cloudshell" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = var.tags
  # Note: shared_access_key_enabled defaults to true, which is required for Cloud Shell

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.cloudshell_container.id]
  }
}

########################################
# Storage File Share
########################################

resource "azurerm_storage_share" "cloudshell" {
  name               = "acsshare"
  storage_account_id = azurerm_storage_account.cloudshell.id
  quota              = 50
}

########################################
# Storage Private Endpoints
########################################

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-blob-${local.storage_account_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cloudshell_storage_pe.id
  tags                = var.tags

  private_service_connection {
    name                           = "storage-blob-connection"
    private_connection_resource_id = azurerm_storage_account.cloudshell.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }
}

resource "azurerm_private_endpoint" "storage_file" {
  name                = "pe-storage-file-${local.storage_account_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cloudshell_storage_pe.id
  tags                = var.tags

  private_service_connection {
    name                           = "storage-file-connection"
    private_connection_resource_id = azurerm_storage_account.cloudshell.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "storage-file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }
}

########################################
# Cloud Shell Role Assignments
########################################

# ACI Service needs Network Contributor on network profile for Cloud Shell VNet
# Required per Agents.md workflow step: "Provide network contributor access to ACI service"
resource "azurerm_role_assignment" "aci_network_profile_contributor" {
  scope                = azurerm_network_profile.cloudshell.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azuread_service_principal.aci.object_id
}

# ACI Service needs Contributor on Relay namespace for Cloud Shell VNet
# Required per Agents.md workflow step: "Provide contributor access to ACI service for Azure Relay"
resource "azurerm_role_assignment" "aci_relay_contributor" {
  scope                = azurerm_relay_namespace.cloudshell.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.aci.object_id
}
