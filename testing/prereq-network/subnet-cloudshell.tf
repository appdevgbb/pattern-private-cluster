resource "azurerm_subnet" "cloudshell_container" {
  name                 = "cloudshellsubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 4)] # x.x.4.0/24

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
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 5)] # x.x.5.0/24
}

resource "azurerm_subnet" "cloudshell_storage_pe" {
  name                 = "storage-pe-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 6)] # x.x.6.0/24

  # Enable network policies for private endpoints per MS Cloud Shell best practices
  private_endpoint_network_policies = "Enabled"
}

# NSG for Cloud Shell - requires outbound internet
resource "azurerm_network_security_group" "cloudshell" {
  name                = "nsg-cloudshell"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
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
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.cloudshell.name
}

resource "azurerm_subnet_network_security_group_association" "cloudshell" {
  subnet_id                 = azurerm_subnet.cloudshell_container.id
  network_security_group_id = azurerm_network_security_group.cloudshell.id
}
