variable "application_name" {
  type = string
}
variable "environment_name" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "vm_size" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "aks_sku_tier" {
  type    = string
  default = "Standard"
}
variable "aks_admin_group_object_ids" {
  type    = list(string)
  default = []
}
variable "kubernetes_version" {
  type    = string
  default = "1.32.0"
}
variable "log_analytics_retention_days" {
  type    = number
  default = 30
}
variable "default_node_count" {
  type    = number
  default = 3
}
variable "aks_subnet_id" {
  type = string
}
variable "pod_cidr" {
  type = string
}
variable "service_cidr" {
  type = string
}
variable "dns_service_ip" {
  type = string
}
