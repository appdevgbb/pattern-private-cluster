########################################
# AKS Managed Identities
########################################

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "id-aks-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "kubelet_identity" {
  name                = "id-kubelet-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

########################################
# AKS Cluster
########################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # SKU Tier - Standard/Premium includes Uptime SLA
  sku_tier = var.aks_sku_tier

  # Automatic upgrade channels
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  # Azure Policy for governance
  azure_policy_enabled = true

  # Private cluster configuration
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  private_dns_zone_id                 = "System"

  # Disable local accounts only when Azure AD groups are configured
  local_account_disabled = length(var.aks_admin_group_object_ids) > 0

  # Enable OIDC issuer and workload identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "system"
    node_count     = var.default_node_count
    vm_size        = var.default_node_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    os_sku         = "AzureLinux"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  api_server_access_profile {
    virtual_network_integration_enabled = true
    subnet_id                           = azurerm_subnet.api_server_subnet.id
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = length(var.aks_admin_group_object_ids) > 0 ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aks_admin_group_object_ids
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "none"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.aks.id
    msi_auth_for_monitoring_enabled = true
  }

  bootstrap_profile {
    artifact_source       = "Cache"
    container_registry_id = azurerm_container_registry.acr.id
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "06:00"
    utc_offset  = "+00:00"
  }

  depends_on = [
    azurerm_role_assignment.aks_network_contributor,
    azurerm_role_assignment.aks_identity_operator,
    azurerm_role_assignment.kubelet_acr_pull,
    azurerm_private_endpoint.acr,
    azurerm_container_registry_cache_rule.aks_managed
  ]
}

########################################
# AKS Role Assignments
########################################

# AKS identity needs Network Contributor on VNet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

# AKS identity needs Managed Identity Operator on kubelet identity
resource "azurerm_role_assignment" "aks_identity_operator" {
  scope                = azurerm_user_assigned_identity.kubelet_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

# Current user - Cluster Admin Role (control plane access)
resource "azurerm_role_assignment" "aks_cluster_admin_current_user" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Current user - RBAC Cluster Admin (data plane access)
resource "azurerm_role_assignment" "aks_rbac_cluster_admin_current_user" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
