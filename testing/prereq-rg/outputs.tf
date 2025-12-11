output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}
output "location" {
  value = data.azurerm_resource_group.main.location
}
