data "azurerm_client_config" "current" {}

data "azurerm_subscription" "primary" {
}

data "azuread_group" "group_studient" {
  display_name = "group_studient"
}

# data "azurerm_resource_group" "raph-rg" {
#   name     = "rg-raphd"
# }