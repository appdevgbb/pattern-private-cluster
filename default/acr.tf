########################################
# Azure Container Registry
########################################

resource "azurerm_container_registry" "acr" {
  name                          = local.acr_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Premium"
  public_network_access_enabled = false
  tags                          = var.tags
}

########################################
# ACR Cache Rules
########################################

# CRITICAL for network isolated clusters - caches ALL MCR images for AKS bootstrap
# BYO ACR requires EXACT settings per MS docs:
#   - name: aks-managed-mcr
#   - source_repo: mcr.microsoft.com/*
#   - target_repo: aks-managed-repository/*
# DO NOT modify this cache rule - it is required for cluster creation/functioning/upgrading
resource "azurerm_container_registry_cache_rule" "aks_managed" {
  name                  = "aks-managed-mcr"
  container_registry_id = azurerm_container_registry.acr.id
  source_repo           = "mcr.microsoft.com/*"
  target_repo           = "aks-managed-repository/*"
  credential_set_id     = null
}

########################################
# ACR Private Endpoint
########################################

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${local.acr_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.acr_subnet.id
  tags                = var.tags

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

########################################
# ACR Role Assignments
########################################

resource "azurerm_role_assignment" "kubelet_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.kubelet_identity.principal_id
  skip_service_principal_aad_check = true
}
