/*
 * Creates private DNS zones and virtual network links for Azure resources.
 * 
 * This file creates several private DNS zones and virtual network links for use with Azure resources. 
 * These resources are used to enable private communication between resources within a virtual network.
 * 
 * Resources:
 * - azurerm_private_dns_zone.hub
 * - azurerm_private_dns_zone_virtual_network_link.hub
 * - azurerm_private_dns_zone.acr
 * - azurerm_private_dns_zone_virtual_network_link.acr
 * - azurerm_private_dns_zone_virtual_network_link.acr-aks-pvt
 * - azurerm_private_dns_zone.aksPrivateZone
 * - azurerm_private_dns_zone_virtual_network_link.aksPrivateZoneDefaultVnet
 * - azurerm_private_dns_zone.aksTestClientPrivateZone
 * - azurerm_private_dns_zone_virtual_network_link.aksTestClientPrivateZoneDefaultVnet
 */
resource "azurerm_private_dns_zone" "hub" {
  name                = local.zone_name
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "hubDnsLink"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.hub.name
  virtual_network_id    = azurerm_virtual_network.default.id
  registration_enabled  = true
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-privatelink"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

/* pvt AKS Cluster */
resource "azurerm_private_dns_zone_virtual_network_link" "acr-aks-pvt" {
  name                  = "acr-privatelink-aks-pvt"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.pvt-vnet.id
}

resource "azurerm_private_dns_zone" "aksPrivateZone" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aksPrivateZoneDefaultVnet" {
  name                  = "aks-privatelink-default"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.aksPrivateZone.name
  virtual_network_id    = azurerm_virtual_network.default.id
}

/* Test Client AKS Cluster */
resource "azurerm_private_dns_zone" "aksTestClientPrivateZone" {
  name                = "testclient.privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aksTestClientPrivateZoneDefaultVnet" {
  name                  = "aks-testclient-privatelink"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.aksTestClientPrivateZone.name
  virtual_network_id    = azurerm_virtual_network.default.id
}
