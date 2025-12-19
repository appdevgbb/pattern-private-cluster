########################################
# Azure Firewall Subnet
########################################

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet" # Name must be exactly this
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 10)] # x.x.10.0/24
}

########################################
# Azure Firewall Public IP
########################################

resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

########################################
# Azure Firewall
########################################

resource "azurerm_firewall" "aks" {
  name                = "fw-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.aks.id
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

########################################
# Azure Firewall Policy
########################################

resource "azurerm_firewall_policy" "aks" {
  name                = "fwpolicy-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  tags                = var.tags
}

########################################
# Firewall Network Rules - AKS Required
########################################

resource "azurerm_firewall_policy_rule_collection_group" "aks_network_rules" {
  name               = "aks-network-rules"
  firewall_policy_id = azurerm_firewall_policy.aks.id
  priority           = 100

  network_rule_collection {
    name     = "aks-required-network-rules"
    priority = 100
    action   = "Allow"

    # Azure Global - Time sync
    rule {
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    # Azure Cloud services - Required for AKS
    rule {
      name              = "azure-cloud"
      protocols         = ["TCP"]
      source_addresses  = ["*"]
      destination_addresses = [
        "AzureCloud.${var.location}"
      ]
      destination_ports = ["443", "9000", "1194"]
    }

    # AzureMonitor service tag
    rule {
      name              = "azure-monitor"
      protocols         = ["TCP"]
      source_addresses  = ["*"]
      destination_addresses = [
        "AzureMonitor"
      ]
      destination_ports = ["443"]
    }

    # Internet access for package downloads (temporary for troubleshooting)
    rule {
      name                  = "internet-http-https"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
    }
  }
}

########################################
# Firewall Application Rules - AKS Required
########################################

resource "azurerm_firewall_policy_rule_collection_group" "aks_application_rules" {
  name               = "aks-application-rules"
  firewall_policy_id = azurerm_firewall_policy.aks.id
  priority           = 200

  application_rule_collection {
    name     = "aks-required-fqdns"
    priority = 200
    action   = "Allow"

    # AKS Core Services
    rule {
      name = "aks-core-services"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.azmk8s.io",
        "*.${var.location}.azmk8s.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "*.hcp.${var.location}.azmk8s.io",
        "*.tun.${var.location}.azmk8s.io"
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Linux (Mariner) packages
    rule {
      name = "azure-linux-packages"
      source_addresses = ["*"]
      destination_fqdns = [
        "packages.microsoft.com",
        "azurelinuxstorage.blob.core.windows.net",
        "*.azureedge.net"
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Monitor
    rule {
      name = "azure-monitor"
      source_addresses = ["*"]
      destination_fqdns = [
        "dc.services.visualstudio.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com"
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    # Container registries
    rule {
      name = "container-registries"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.blob.core.windows.net",
        "*.azurecr.io",
        "*.gcr.io",
        "gcr.io",
        "storage.googleapis.com",
        "ghcr.io",
        "*.ghcr.io",
        "*.pkg.dev"
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    # Ubuntu/Debian updates  
    rule {
      name = "ubuntu-updates"
      source_addresses = ["*"]
      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
        "archive.ubuntu.com",
        "ports.ubuntu.com"
      ]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }

    # Additional required services
    rule {
      name = "additional-services"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.ubuntu.com",
        "*.core.windows.net",
        "*.azure.com"
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}

########################################
# Route Table for AKS with Firewall
########################################

resource "azurerm_route_table" "aks" {
  name                = "rt-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_route" "firewall" {
  name                   = "route-to-firewall"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.aks.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.aks.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks_subnet.id
  route_table_id = azurerm_route_table.aks.id
}

resource "azurerm_subnet_route_table_association" "jumpservers" {
  subnet_id      = azurerm_subnet.jumpservers.id
  route_table_id = azurerm_route_table.aks.id
}
