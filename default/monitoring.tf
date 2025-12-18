########################################
# Log Analytics Workspace
########################################

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "log-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

########################################
# Container Insights Solution
########################################

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.aks.id
  workspace_name        = azurerm_log_analytics_workspace.aks.name
  tags                  = var.tags

  plan {
    product   = "OMSGallery/ContainerInsights"
    publisher = "Microsoft"
  }
}

########################################
# Azure Monitor Workspace for Managed Prometheus
########################################

resource "azurerm_monitor_workspace" "aks" {
  name                          = "amw-${var.cluster_name}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "aks" {
  name                          = "dce-${var.cluster_name}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  kind                          = "Linux"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_monitor_data_collection_rule" "aks" {
  name                        = "dcr-${var.cluster_name}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.aks.id
  kind                        = "Linux"
  tags                        = var.tags

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.aks.id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks" {
  name                    = "dcra-${var.cluster_name}"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks.id
}