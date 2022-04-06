# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.70.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.name}d"
  location = var.location
}

#DEPLOYER STORAGE ACCOUNT EN REPLICATION "LRS"

resource "azurerm_storage_account" "storage" {
  name                     = "raphstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

#DEPLOYER UN CONTENEUR SUR SON STORAGE ACCOUNT

resource "azurerm_storage_container" "container" {
  name                  = "raphcontainer"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

#DEPLOYER UN KEYVAULT 

resource "azurerm_key_vault" "keyvault" {
  name                       = "raphkeyvaultv2"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = false

  sku_name = "standard"

  network_acls {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = ["2.10.224.249"]
    virtual_network_subnet_ids = azurerm_subnet.subnet[*].id
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_group.group_studient.object_id

    secret_permissions = var.secret_permissions
  }
}


#DEPLOYER UN MSSQL SERVER (PAS DE DATABASE POUR LE MOMENT) DANS MON RESOURCE GROUP "rg-raphd".

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "raph-sqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = random_password.mdpsql.result
  minimum_tls_version          = "1.2"

  #   azuread_administrator {
  #     login_username = "AzureAD Admin"
  #     object_id      = data.azuread_group.group_studient.object_id
  #   }
}

resource "random_password" "mdpsql" {
  length           = 16
  special          = true
  min_numeric      = 1
  min_upper        = 1
  min_special      = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "mdpsql" {
  name         = "mdpsql"
  value        = random_password.mdpsql.result
  key_vault_id = azurerm_key_vault.keyvault.id
}


#DEPLOYER MOI 3 LOG ANALYTICS (MONITORING) EN UN SEUL BLOCK, COUNT.

resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = "raphlog"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = 30
}

#ENVOYER LES LOGS "AUDITEVENT" DE VOTRE KEYVAULT VERS VOTRE LOG ANALYTICS. 

# resource "azurerm_monitor_diagnostic_setting" "sendlog" {
#   name                       = "Send AuditEvent"
#   target_resource_id         = azurerm_key_vault.keyvault.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.loganalytics.id

#   log {
#     category = "AuditEvent"
#     enabled  = true

#     retention_policy {
#       enabled = false
#     }
#   }
# }

#RESEAU
#1 VNET
#3 SUBNETS (COUNT OU PAS)

resource "azurerm_virtual_network" "vnet" {
  name                = "raphvnet"
  address_space       = var.ip_vnet
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  count                                          = 4
  name                                           = "raphsubnet${count.index}"
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = ["10.0.${count.index}.0/24"]
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = ["Microsoft.KeyVault"]
}

resource "azurerm_private_endpoint" "private-endpoint" {
  name                = "raphendpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet[0].id

  private_service_connection {
    name                           = "raphconnection"
    private_connection_resource_id = azurerm_key_vault.keyvault.id
    is_manual_connection           = false
    subresource_names              = ["vault"] #GROUP_ID
  }
}

resource "azurerm_private_endpoint" "private-endpoint2" {
  name                = "raphendpoint2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet[0].id

  private_service_connection {
    name                           = "raphconnection"
    private_connection_resource_id = azurerm_mssql_server.sqlserver.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"] #GROUP_ID
  }
}

#DEPLOYER UNE VM WINDOWS SERVER, AVEC LA SIZE LA MOINS CHER Standard_B1ls. #NO SCALE. #NO REDUNDANCY. HDD DISK .#NO PUBLIC IP


#DEPLOYER 1 DISK SUPPLEMENTAIRE A ATTACHER A VOTRE VM


#A FAIRE SI VOUS VOULEZ : BOOT DIAGNOSTIC

resource "azurerm_public_ip" "publicip" {
  name                = "raphIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "networkcard" {
  name                = "raph-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "raph-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.networkcard.id,
  ]

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

#CREER 2 RG, 1 AUX US, 1 EN EUROPE

resource "azurerm_resource_group" "all_rg" {
  for_each = var.resource_group

  name     = each.value.name
  location = each.value.location
}

#AJOUTER 3 DISKS EN FOREACH ET LES ATTACHER SUR NOTRE VM. 
#1 = 10
#2 = 5
#3 = 20

#AJOUTER DES TAGS DIFFERENTS 
#1 = tag = disk = 1
#2 = tag = disk = 2
#3 = tag = disk = 3

resource "azurerm_managed_disk" "all_disk" {
  for_each             = var.disk
  name                 = each.value.name
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  tags                 = each.value.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_all_disk" {
  for_each           = var.disk
  managed_disk_id    = azurerm_managed_disk.all_disk[each.key].id  
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = each.value.lun
  caching            = "ReadWrite"
}