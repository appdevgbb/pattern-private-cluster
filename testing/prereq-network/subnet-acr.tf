resource "azurerm_subnet" "acr" {
  name                 = "acr-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 3)] # x.x.3.0/24
}
