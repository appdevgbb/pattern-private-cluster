/* 
 * This Terraform code creates a set of firewall rules for an Azure Firewall instance. 
 * The rules include network and application rules for various services such as AKS, Azure Monitor, NTP, 
 * and Ubuntu updates. The code also includes a module that creates the Azure Firewall instance.
*/
module "firewall" {
  source         = "./modules/firewall"
  prefix         = var.prefix
  suffix         = var.suffix
  subnet_id      = azurerm_subnet.firewall.id
  resource_group = azurerm_resource_group.default
}

resource "azurerm_firewall_network_rule_collection" "jumpbox" {
  name                = "testcollection"
  azure_firewall_name = module.firewall.name
  resource_group_name = module.firewall.resource_group.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "defaultRule"

    source_addresses = azurerm_subnet.jumpbox.address_prefixes

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "Any",
    ]
  }
}

# resource "azurerm_firewall_network_rule_collection" "dnsForwarder" {
#   name                = "dnsForwarderCollection"
#   azure_firewall_name = module.firewall.name
#   resource_group_name = module.firewall.resource_group.name
#   priority            = 200
#   action              = "Allow"

#   rule {
#     name = "dnsForwarderRule"

#     source_addresses = azurerm_subnet.dnsForwarder.address_prefixes

#     destination_ports = [
#       "53",
#     ]

#     destination_addresses = [
#       "*"
#     ]

#     protocols = [
#       "TCP",
#       "UDP",
#     ]
#   }
# }

# resource "azurerm_firewall_network_rule_collection" "vpn" {
#   name                = "vpnForwarderCollection"
#   azure_firewall_name = module.firewall.name
#   resource_group_name = module.firewall.resource_group.name
#   priority            = 300
#   action              = "Allow"

#   rule {
#     name = "vpnClientAllowRule"

#     source_addresses = concat(["172.16.201.0/24"], azurerm_subnet.dnsForwarder.address_prefixes)

#     destination_ports = [
#       "*",
#     ]

#     destination_addresses = [
#       "*"
#     ]

#     protocols = [
#       "Any",
#     ]
#   }
# }

resource "azurerm_firewall_application_rule_collection" "aks" {
  name                = "aksRequiredRules${var.suffix}"
  azure_firewall_name = module.firewall.name
  resource_group_name = module.firewall.resource_group.name
  priority            = 120
  action              = "Allow"

  rule {
    name = "updateInfraRules"

    source_addresses = concat([], azurerm_virtual_network.pvt-vnet.address_space)

    target_fqdns = [
      "*.hcp.${module.firewall.resource_group.location}.azmk8s.io",
      "mcr.microsoft.com",
      "*.cdn.mcr.io",
      "*.data.mcr.microsoft.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "dc.services.visualstudio.com",
      "*.ods.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.monitoring.azure.com",
      "packages.microsoft.com",
      "acs-mirror.azureedge.net",
      "azure.archive.ubuntu.com",
      "security.ubuntu.com",
      "changelogs.ubuntu.com",
      "launchpad.net",
      "ppa.launchpad.net",
      "keyserver.ubuntu.com",
      "*.docker.com",
      "*.docker.io",
      "*.kusto.windows.net",
      "*.core.windows.net"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "azureMonitor" {
  name                = "azureMonitorRequiredRules${var.suffix}"
  azure_firewall_name = module.firewall.name
  resource_group_name = module.firewall.resource_group.name
  priority            = 110
  action              = "Allow"

  rule {
    name = "azureMonitorRules"

    source_addresses = concat([], azurerm_virtual_network.default.address_space)

    target_fqdns = [
      "dc.services.visualstudio.com",
      "*.ods.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.monitoring.azure.com"
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "ntp" {
  name                = "ntpRule${var.suffix}"
  azure_firewall_name = module.firewall.name
  resource_group_name = module.firewall.resource_group.name
  priority            = 150
  action              = "Allow"

  rule {
    name = "ubuntuNTP"

    source_addresses = concat([], azurerm_virtual_network.pvt-vnet.address_space)

    destination_ports = [
      "123",
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "UDP",
    ]
  }
}

resource "azurerm_firewall_application_rule_collection" "updates" {
  name                = "ubuntuUpdateInfrastructure${var.suffix}"
  azure_firewall_name = module.firewall.name
  resource_group_name = module.firewall.resource_group.name
  priority            = 400
  action              = "Allow"

  rule {
    name = "updateInfraRules"

    source_addresses = concat([], azurerm_virtual_network.default.address_space)

    target_fqdns = [
      "azure.archive.ubuntu.com",
      "security.ubuntu.com",
      "changelogs.ubuntu.com",
      "launchpad.net",
      "ppa.launchpad.net",
      "keyserver.ubuntu.com",
      "mirror.centos.org"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}