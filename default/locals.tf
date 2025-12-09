########################################
# Computed Names for Globally Unique Resources
########################################

locals {
  # Generate a deterministic 6-character suffix from subscription ID
  # This ensures the same subscription always gets the same suffix
  auto_suffix = substr(md5(var.subscription_id), 0, 6)

  # Use user-provided suffix if specified, otherwise auto-generate
  name_suffix = var.name_suffix != "" ? var.name_suffix : local.auto_suffix

  # Computed names for globally unique resources
  # These are the actual names that will be created in Azure
  acr_name             = "${var.acr_name}${local.name_suffix}"
  storage_account_name = "${var.storage_account_name}${local.name_suffix}"
  relay_namespace_name = "${var.relay_namespace_name}-${local.name_suffix}"
}
