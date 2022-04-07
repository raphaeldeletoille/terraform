data "azurerm_monitor_diagnostic_categories" "logs" {
  resource_id = var.target_resource_id
}

resource "azurerm_monitor_diagnostic_setting" "monitordiagnosticsetting" {
  name                       = "Send ${var.target_resource_name} logs to ${var.log_analytics_workspace_name}"
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.logs.logs
    content {
      category = log.key
      enabled  = true
      retention_policy {
        days    = 30
        enabled = true
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.logs.metrics
    content {   
      category = metric.key
      enabled  = true
      retention_policy {
        days    = 30
        enabled = true
      }
    }
  }
}