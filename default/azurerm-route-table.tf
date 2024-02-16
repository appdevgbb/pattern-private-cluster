/*
 * This Terraform code defines the configuration for Azure route tables and their associations with subnets.
 * It creates a default route table with a default route that goes to the Azure Firewall, and associates it with the jumpbox subnet.
 * It also creates two additional route tables for two AKS clusters, and associates them with their respective subnets.
 */
resource "azurerm_route_table" "default" {
  depends_on = [
    module.firewall
  ]

  name                = "defaultRouteTable"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_route" "default" {
  name                   = "defaultRoute"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.default.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.ip_address
}

resource "azurerm_subnet_route_table_association" "jumpbox" {
  subnet_id      = azurerm_subnet.jumpbox.id
  route_table_id = azurerm_route_table.default.id
}

# spokes
#

/* 
 * spoke
 * AKS pvt Cluster
 */

/* default route goes to the Azure Firewall */
resource "azurerm_route" "defaultRtSpoke1" {
  name                   = "defaultRoute"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.aks-pvt-rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.ip_address
}

resource "azurerm_route_table" "aks-pvt-rt" {
  depends_on = [
    module.firewall
  ]

  name                = "akspvtRouteTable"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_route_table_association" "aks-pvt" {
  subnet_id      = azurerm_subnet.pvt-cluster.id
  route_table_id = azurerm_route_table.aks-pvt-rt.id
}

/* Test Client AKS Cluster */
resource "azurerm_route" "defaultRouteTestClientCluster" {
  name                   = "defaultRoute"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.aks-testclient-rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.ip_address
}
resource "azurerm_route_table" "aks-testclient-rt" {
  depends_on = [
    module.firewall
  ]

  name                = "aksTestClientRouteTable"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_route_table_association" "pvt-testclient-cluster" {
  subnet_id      = azurerm_subnet.pvt-testclient-cluster.id
  route_table_id = azurerm_route_table.aks-testclient-rt.id
}