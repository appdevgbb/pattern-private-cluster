locals {
  cluster_name = "aks-${var.application_name}-${var.environment_name}"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.cluster_name
  tags                = var.tags

  sku_tier                            = var.aks_sku_tier # SKU Tier - Standard/Premium includes Uptime SLA
  kubernetes_version                  = var.kubernetes_version
  automatic_upgrade_channel           = "patch" # Automatic upgrade channels
  node_os_upgrade_channel             = "NodeImage"
  azure_policy_enabled                = true # Azure Policy for governance
  private_cluster_enabled             = true # Private cluster configuration
  private_cluster_public_fqdn_enabled = false
  private_dns_zone_id                 = "System"
  local_account_disabled              = true # Disable local accounts for enhanced security
  oidc_issuer_enabled                 = true # Enable OIDC issuer and workload identity
  workload_identity_enabled           = true

  default_node_pool {
    name           = "system"
    node_count     = var.default_node_count
    vm_size        = var.vm_size
    vnet_subnet_id = var.aks_subnet_id

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

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aks_admin_group_object_ids
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

}
