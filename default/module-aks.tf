/* 
 * This Terraform code creates an Azure user-assigned managed identity and assigns it to 
 * various roles in different scopes.  The AKS cluster is deployed with a 
 * private DNS zone, a private ACR, and multiple node pools with different configurations. 
 * The code also includes dependencies on other resources such as a firewall, a subnet, 
 * and a log analytics workspace.
 */
resource "azurerm_user_assigned_identity" "managed-id" {
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  name = "aks-user-assigned-managed-id"
}

resource "azurerm_role_assignment" "aks-mi-roles" {
  scope                = azurerm_private_dns_zone.hub.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

# cluster-1
#

resource "azurerm_role_assignment" "aks-mi-roles-vnet-rg" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

# Network
resource "azurerm_role_assignment" "aks-mi-roles-aks-pvt" {
  scope                = azurerm_virtual_network.pvt-vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

resource "azurerm_role_assignment" "aks-mi-roles-default-vnet" {
  scope                = azurerm_virtual_network.default.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

resource "azurerm_role_assignment" "aks-mi-roles-aks-pvt-rt" {
  scope                = azurerm_route_table.aks-pvt-rt.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

# DNS
resource "azurerm_role_assignment" "aks-mi-roles-aks-pvt-dns-zone" {
  scope                = azurerm_private_dns_zone.aksPrivateZone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

module "aks" {
  depends_on = [
    module.firewall,
    azurerm_subnet_route_table_association.aks-pvt,
    # explict dependency on the firewall rules ensures they're in place before deploying private cluster
    azurerm_firewall_application_rule_collection.aks,
    azurerm_firewall_application_rule_collection.azureMonitor,
    azurerm_firewall_application_rule_collection.updates,
    azurerm_firewall_network_rule_collection.ntp,
    azurerm_private_dns_zone.acr,
    azurerm_role_assignment.aks-mi-roles,
    azurerm_virtual_network.pvt-vnet
  ]

  source = "./modules/aks"

  prefix = local.prefix
  suffix = local.suffix

  user_assigned_identity = azurerm_user_assigned_identity.managed-id

  # aks_admin_group_object_ids = var.aks_admin_group_object_ids

  admin_username = var.admin_username

  subnet_id      = azurerm_subnet.pvt-cluster.id
  resource_group = azurerm_resource_group.default

  # ACR
  container_registry_id = azurerm_container_registry.default.id
  acr_subnet_id         = azurerm_subnet.acr.id
  acr_private_dns_zone_ids = [
    azurerm_private_dns_zone.acr.id
  ]

  private_dns_zone_id = azurerm_private_dns_zone.aksPrivateZone.id
  cluster_name        = "pvt-cluster"
  aks_settings = {
    kubernetes_version      = "1.28.3"
    private_cluster_enabled = true
    identity                = "UserAssigned"
    outbound_type           = "userDefinedRouting"
    network_plugin          = "azure"
    network_policy          = "calico"
    load_balancer_sku       = "standard"
    service_cidr            = "10.174.128.0/17"
    dns_service_ip          = "10.174.128.10"
    admin_username          = var.admin_username
    ssh_key                 = "~/.ssh/id_rsa.pub"
  }

  default_node_pool = {
    name                         = "system"
    enable_auto_scaling          = true
    node_count                   = 2
    min_count                    = 2
    max_count                    = 3
    vm_size                      = "standard_d4_v5"
    type                         = "VirtualMachineScaleSets"
    os_disk_size_gb              = 30
    only_critical_addons_enabled = true
    zones                        = [1, 2]
  }

  user_node_pools = {
    "usernp" = {
      vm_size     = "standard_d4_v5"
      node_count  = 1
      node_labels = null
      node_taints = ["layer=fanout:NoSchedule"]
    }
  }
}
