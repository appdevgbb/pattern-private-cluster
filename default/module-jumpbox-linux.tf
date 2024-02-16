/*
 * This module creates a Linux jumpbox VM in the specified subnet.
 * It also creates a NAT rule in the Azure Firewall to allow SSH access to the jumpbox.
 */
module "jumpbox" {
  depends_on = [
    module.firewall,
    module.aks
  ]

  source = "./modules/jumpbox-linux"

  prefix = local.prefix
  suffix = local.suffix

  subnet_id      = azurerm_subnet.jumpbox.id
  resource_group = azurerm_resource_group.default

  admin_username = var.admin_username
}


resource "azurerm_firewall_nat_rule_collection" "ssh" {
  name                = "JumpboxSshNatRule"
  azure_firewall_name = module.firewall.name
  resource_group_name = azurerm_resource_group.default.name
  priority            = 200
  action              = "Dnat"

  rule {
    name = "JumpboxSSH"

    source_addresses = [
      data.http.myip.response_body
    ]

    destination_ports = [
      "22",
    ]

    destination_addresses = [
      module.firewall.public_ip_address
    ]

    translated_port = 22

    translated_address = module.jumpbox.ip_address

    protocols = [
      "TCP"
    ]
  }
}