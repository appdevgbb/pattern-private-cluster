/*
 * Outputs for the private AKS cluster deployment.
 */
output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_managed_id" {
  value = {
    client_id = azurerm_user_assigned_identity.managed-id.client_id
    name      = azurerm_user_assigned_identity.managed-id.name
  }
}

output "kubeconfig" {
  value     = module.aks.kube_config
  sensitive = true
}
