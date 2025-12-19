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

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for Container Insights."
  value       = azurerm_log_analytics_workspace.aks.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.aks.name
}

########################################
# Firewall Outputs
########################################

output "firewall_name" {
  description = "The name of the Azure Firewall."
  value       = azurerm_firewall.aks.name
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall."
  value       = azurerm_firewall.aks.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "The public IP address of the Azure Firewall."
  value       = azurerm_public_ip.firewall.ip_address
}

########################################
# Bastion Outputs
########################################

output "bastion_name" {
  description = "The name of the Azure Bastion host."
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_dns_name" {
  description = "The DNS name of the Azure Bastion host."
  value       = azurerm_bastion_host.bastion.dns_name
}

########################################
# Jumpbox Outputs
########################################

output "jumpbox_vm_name" {
  description = "The name of the Windows jumpbox VM."
  value       = azurerm_windows_virtual_machine.jumpbox.name
}

output "jumpbox_private_ip" {
  description = "The private IP address of the Windows jumpbox."
  value       = azurerm_network_interface.jumpbox.private_ip_address
}

output "jumpbox_admin_username" {
  description = "The admin username for the Windows jumpbox."
  value       = azurerm_windows_virtual_machine.jumpbox.admin_username
}
