terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azuread_group" "group_for_studient" {
  display_name     = "group_studient"
  security_enabled = true
}

resource "azuread_group_member" "add_users_group_for_studient" {
  count            = 50
  group_object_id  = azuread_group.group_for_studient.id
  member_object_id = azuread_user.users[count.index].id
}

resource "azuread_user" "users" {
  count               = 50
  user_principal_name = "Demo${count.index}@deletoilleprooutlook.onmicrosoft.com"
  display_name        = "Demo${count.index}"
  mail_nickname       = "Demo${count.index}"
  password            = random_password.password_generation.result
}

resource "azurerm_resource_group" "resource_group" {
  name     = "rg-password"
  location = "West Europe"
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "kv-pwd-ipssi"
  location                    = azurerm_resource_group.resource_group.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
  }
}

resource "azurerm_key_vault_secret" "password_secret" {
  name         = "password-users"
  value        = random_password.password_generation.result
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on = [
    azurerm_key_vault.key_vault
  ]
}

resource "random_password" "password_generation" {
  length           = 8
  special          = true
  override_special = "_%@!"
}

##ADD RIGHTS NEEDED INTO AAD TO THE GROUP, ENJOY :)