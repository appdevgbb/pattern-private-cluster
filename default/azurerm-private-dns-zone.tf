/*
 * Creates private DNS zone for the private AKS cluster.
 */
resource "azurerm_private_dns_zone" "aksPrivateZone" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aksPrivateZoneVnet" {
  name                  = "aks-privatelink"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.aksPrivateZone.name
  virtual_network_id    = azurerm_virtual_network.pvt-vnet.id
}
