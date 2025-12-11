output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}
output "api_server_subnet_id" {
  value = azurerm_subnet.api_server.id
}
output "acr_subnet_id" {
  value = azurerm_subnet.acr.id
}
output "vnet_id" {
  value = azurerm_virtual_network.main.id
}
