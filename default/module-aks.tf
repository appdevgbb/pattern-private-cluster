/* 
 * This Terraform code creates an Azure user-assigned managed identity and assigns it to 
 * required roles for the private AKS cluster deployment.
 */
resource "azurerm_user_assigned_identity" "managed-id" {
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  name = "aks-user-assigned-managed-id"
}

resource "azurerm_role_assignment" "aks-mi-roles-vnet-rg" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

resource "azurerm_role_assignment" "aks-mi-roles-aks-pvt" {
  scope                = azurerm_virtual_network.pvt-vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

resource "azurerm_role_assignment" "aks-mi-roles-aks-pvt-dns-zone" {
  scope                = azurerm_private_dns_zone.aksPrivateZone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-id.principal_id
}

module "aks" {
  depends_on = [
    azurerm_role_assignment.aks-mi-roles-vnet-rg,
    azurerm_role_assignment.aks-mi-roles-aks-pvt,
    azurerm_role_assignment.aks-mi-roles-aks-pvt-dns-zone,
    azurerm_private_dns_zone.aksPrivateZone,
    azurerm_virtual_network.pvt-vnet
  ]

  source = "./modules/aks"

  prefix = local.prefix
  suffix = local.suffix

  user_assigned_identity = azurerm_user_assigned_identity.managed-id

  admin_username = var.admin_username

  subnet_id      = azurerm_subnet.pvt-cluster.id
  resource_group = azurerm_resource_group.default

  private_dns_zone_id = azurerm_private_dns_zone.aksPrivateZone.id
  cluster_name        = "pvt-cluster"
  
  aks_settings = {
    kubernetes_version      = "1.31"
    private_cluster_enabled = true
    identity                = "UserAssigned"
    outbound_type           = "loadBalancer"
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
