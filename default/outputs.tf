output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.rg.name
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "acr_name" {
  description = "The name of the Azure Container Registry."
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry."
  value       = azurerm_container_registry.acr.login_server
}

output "kubeconfig" {
  description = "The kubeconfig for the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity federation."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "cloudshell_container_subnet_id" {
  description = "Subnet hosting Cloud Shell containers."
  value       = azurerm_subnet.cloudshell_container.id
}

output "cloudshell_storage_account_name" {
  description = "Storage account for Cloud Shell."
  value       = azurerm_storage_account.cloudshell.name
}

output "cloudshell_relay_namespace_name" {
  description = "Relay namespace used by Cloud Shell."
  value       = azurerm_relay_namespace.cloudshell.name
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for Container Insights."
  value       = azurerm_log_analytics_workspace.aks.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.aks.name
}
