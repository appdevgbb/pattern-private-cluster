/* 
 * This Terraform code defines the virtual network and subnet for the private AKS cluster.
 */
resource "azurerm_virtual_network" "pvt-vnet" {
  name                = "pvt-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.220.0.0/16"]
}

resource "azurerm_subnet" "pvt-cluster" {
  name                 = "snet-aks-pvt-cluster"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.pvt-vnet.name
  address_prefixes     = ["10.220.1.0/24"]
}
