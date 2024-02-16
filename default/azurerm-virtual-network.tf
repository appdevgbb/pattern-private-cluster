/* 
 * This Terraform code defines the virtual networks and subnets for the Refinitiv on Azure pattern. 
 * It creates a hub virtual network with three subnets: AzureFirewallSubnet, AcrSubnet, and JumpboxSubnet. 
 * It also creates a spoke virtual network called pvt-vnet with three subnets: snet-aks-pvt-cluster, 
 * TestServerSubnet, and snet-aks-pvt-testclient-cluster. 
 *
 * Finally, it creates two virtual network peerings: hub-to-spoke-1 and spoke-1-to-hub, which connect the hub
 * and spoke virtual networks.
 */
# hub
# 
resource "azurerm_virtual_network" "default" {
  name                = "hub-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.255.0.0/16"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.255.1.0/24"]
}

resource "azurerm_subnet" "acr" {
  name                                      = "AcrSubnet"
  resource_group_name                       = azurerm_resource_group.default.name
  virtual_network_name                      = azurerm_virtual_network.default.name
  private_endpoint_network_policies_enabled = false
  address_prefixes                          = ["10.255.2.0/24"]
}

resource "azurerm_subnet" "jumpbox" {
  name                 = "JumpboxSubnet"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.255.3.0/24"]
}

# spokes
#

# pvt Cluster, pvt TestClient Cluster, Test Client (VMSS) and Test Server (VMSS)
# VNet Definition
resource "azurerm_virtual_network" "pvt-vnet" {
  name                = "pvt-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.220.0.0/16"]
}

# Subnets
resource "azurerm_subnet" "pvt-cluster" {
  name                                      = "snet-aks-pvt-cluster"
  resource_group_name                       = azurerm_resource_group.default.name
  virtual_network_name                      = azurerm_virtual_network.pvt-vnet.name
  private_endpoint_network_policies_enabled = false
  address_prefixes                          = ["10.220.1.0/24"]
}

# Test Server
resource "azurerm_subnet" "testserver" {
  name                                      = "TestServerSubnet"
  resource_group_name                       = azurerm_resource_group.default.name
  virtual_network_name                      = azurerm_virtual_network.pvt-vnet.name
  private_endpoint_network_policies_enabled = true
  address_prefixes                          = ["10.220.2.0/24"]
}

resource "azurerm_subnet" "pvt-testclient-cluster" {
  name                                      = "snet-aks-pvt-testclient-cluster"
  resource_group_name                       = azurerm_resource_group.default.name
  virtual_network_name                      = azurerm_virtual_network.pvt-vnet.name
  private_endpoint_network_policies_enabled = false
  address_prefixes                          = ["10.220.3.0/24"]
}

# peerings
#
# hub-to-spoke-1
resource "azurerm_virtual_network_peering" "hub-to-spoke-1" {
  name                      = "hub-to-spoke-1"
  resource_group_name       = azurerm_resource_group.default.name
  virtual_network_name      = azurerm_virtual_network.default.name
  remote_virtual_network_id = azurerm_virtual_network.pvt-vnet.id
}

resource "azurerm_virtual_network_peering" "spoke-1-to-hub" {
  name                      = "spoke-1-to-hub"
  resource_group_name       = azurerm_resource_group.default.name
  virtual_network_name      = azurerm_virtual_network.pvt-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.default.id
}
