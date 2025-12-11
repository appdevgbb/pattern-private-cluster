resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "id-${var.application_name}-${var.environment_name}-cluster"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "kubelet_identity" {
  name                = "id-${var.application_name}-${var.environment_name}-kubelet"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}


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
