########################################
# Azure Monitor Private Link Scope (AMPLS)
########################################

resource "azurerm_monitor_private_link_scope" "aks" {
  name                = "ampls-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Link Data Collection Endpoint to AMPLS
resource "azurerm_monitor_private_link_scoped_service" "dce" {
  name                = "dce-scoped-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.aks.name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.aks.id
}

# Link Log Analytics Workspace to AMPLS
resource "azurerm_monitor_private_link_scoped_service" "law" {
  name                = "law-scoped-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.aks.name
  linked_resource_id  = azurerm_log_analytics_workspace.aks.id
}

########################################
# Private DNS Zones for Azure Monitor
########################################

resource "azurerm_private_dns_zone" "monitor" {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "oms" {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "ods" {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "agentsvc" {
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Link DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "monitor" {
  name                  = "monitor-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms" {
  name                  = "oms-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.oms.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods" {
  name                  = "ods-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.ods.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc" {
  name                  = "agentsvc-vnetlink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = var.tags
}

########################################
# Private Endpoint for AMPLS
########################################

resource "azurerm_private_endpoint" "ampls" {
  name                = "pe-ampls-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.aks_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "ampls-privateserviceconnection"
    private_connection_resource_id = azurerm_monitor_private_link_scope.aks.id
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
  }

  private_dns_zone_group {
    name                 = "ampls-dns-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor.id,
      azurerm_private_dns_zone.oms.id,
      azurerm_private_dns_zone.ods.id,
      azurerm_private_dns_zone.agentsvc.id
    ]
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.dce,
    azurerm_monitor_private_link_scoped_service.law
  ]
}
