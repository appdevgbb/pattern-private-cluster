########################################
# Data Sources
########################################

# Current Azure client configuration (used for role assignments)
data "azurerm_client_config" "current" {}

# Azure Container Instance service principal (well-known application ID)
# Used for Cloud Shell VNet integration - required per Agents.md workflow
data "azuread_service_principal" "aci" {
  client_id = "6bb8e274-af5d-4df2-98a3-4fd78b4cafd9"
}
