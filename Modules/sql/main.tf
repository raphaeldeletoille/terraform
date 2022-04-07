resource "azurerm_mssql_database" "sql_database" {
  name                        = var.name
  collation                   = var.collation
  server_id                   = var.server_id
  min_capacity                = var.min_capacity
  max_size_gb                 = var.max_size_gb
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  sku_name                    = var.sku_name
}

#MONITOR DATABASES
module "function_monitor" {
  source = "../logs"

  target_resource_name = azurerm_mssql_database.sql_database.name
  target_resource_id   = azurerm_mssql_database.sql_database.id

  log_analytics_workspace_name = var.log_analytics_workspace_name
  log_analytics_workspace_id   = var.log_analytics_workspace_id
}