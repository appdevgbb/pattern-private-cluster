
resource "azurerm_monitor_diagnostic_setting" "example" {
  name                           = "${azurerm_firewall.default.name}-diag-settings"
  target_resource_id             = azurerm_firewall.default.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.azfw.id
  log_analytics_destination_type = "AzureDiagnostics"

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AzureFirewallApplicationRule"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWThreatIntel"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNetworkRuleAggregation"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNetworkRule"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNatRuleAggregation"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNatRule"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWIdpsSignature"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWApplicationRule"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWApplicationRuleAggregation"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWDnsQuery"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWFatFlow"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWFqdnResolveFailure"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [
      log
    ]
  }

}