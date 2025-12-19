########################################
# Azure Bastion
########################################

# Bastion Subnet - must be named AzureBastionSubnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 0)] # x.x.0.0/24
}

# Jump Server Subnet - for VMs accessed via Bastion
resource "azurerm_subnet" "jumpservers" {
  name                 = "jumpservers-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 7)] # x.x.7.0/24
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                   = "bastion-${var.cluster_name}"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  sku                    = "Standard"
  copy_paste_enabled     = true
  file_copy_enabled      = true
  tunneling_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = false

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}

########################################
# Network Security Group for Jump Servers
########################################

resource "azurerm_network_security_group" "jumpservers" {
  name                = "nsg-jumpservers"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Allow RDP from Bastion
resource "azurerm_network_security_rule" "jumpserver_allow_rdp_from_bastion" {
  name                        = "AllowRdpFromBastion"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = cidrsubnet(var.vnet_address_space, 8, 0) # Bastion subnet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.jumpservers.name
}

# Deny all other inbound traffic
resource "azurerm_network_security_rule" "jumpserver_deny_all_inbound" {
  name                        = "DenyAllInbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.jumpservers.name
}

resource "azurerm_subnet_network_security_group_association" "jumpservers" {
  subnet_id                 = azurerm_subnet.jumpservers.id
  network_security_group_id = azurerm_network_security_group.jumpservers.id
}
