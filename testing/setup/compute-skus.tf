data "azurerm_client_config" "current" {}

data "azapi_resource_action" "skus" {
  type                   = "Microsoft.Compute@2021-07-01"
  resource_id            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Compute"
  action                 = "skus?api-version=2021-07-01&$filter=location%20eq%20'${var.location}'"
  method                 = "GET"
  response_export_values = ["*"]
}

locals {
  raw_vm_skus = [
    for sku in data.azapi_resource_action.skus.output.value : {
      name         = sku.name
      resourceType = sku.resourceType
      tier         = sku.tier
      size         = sku.size
      family       = sku.family
      capabilities = {
        for capability in sku.capabilities :
        capability.name => capability.value
      }
    }
    if(sku.resourceType == "virtualMachines")
  ]

  all_vm_skus = [
    for sku in local.raw_vm_skus : {
      name         = sku.name
      resourceType = sku.resourceType
      tier         = sku.tier
      size         = sku.size
      family       = sku.family
      resources = {
        vcpus           = tonumber(sku.capabilities["vCPUs"])
        vcpus_available = tonumber(sku.capabilities["vCPUsAvailable"])
        vcpus_per_core  = tonumber(sku.capabilities["vCPUsPerCore"])
        memory_gb       = tonumber(sku.capabilities["MemoryGB"])
        gpus            = tonumber(lookup(sku.capabilities, "GPUs", "0"))
      }
    }
  ]
  matching_vm_skus = [
    for sku in local.all_vm_skus : sku
    if(
      (sku.resources.vcpus >= var.vcpu_min && sku.resources.vcpus <= var.vcpu_max) &&
      (sku.resources.memory_gb >= var.memory_gb_min && sku.resources.memory_gb <= var.memory_gb_max) &&
      (strcontains(sku.size, var.name_filter))
    )
  ]
}
resource "random_integer" "vm_sku_index" {
  min = 0
  max = length(local.matching_vm_skus) - 1
}
locals {
  selected_vm_sku = local.matching_vm_skus[random_integer.vm_sku_index.result]
}
