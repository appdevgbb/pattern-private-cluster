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
variable "tags" {
  type    = map(string)
  default = {}
}
variable "vnet_address_space" {
  type = string
}
