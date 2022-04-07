# NOM
# UN TYPE
# UNE value

variable "location" {
  type    = string
  default = "West Europe"
}

variable "name" {
  type    = string
  default = "raph"
}

variable "soft_delete_retention_days" {
  type    = number
  default = 7
}

variable "secret_permissions" {
  type = list(string)
  default = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

variable "ip_vnet" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "resource_group" {
  type = map(any)
  default = {
    "rg01" = {
      name     = "rg-raph-europe"
      location = "West Europe"
    },
    "rg02" = {
      name     = "rg-raph-us"
      location = "West US"
    },
  }
}

variable "disk" {
  type = map(any)
  default = {
    "disk01" = {
      name         = "raph-disk01"
      disk_size_gb = "10"
      lun          = "1"
      tags = {
        disk = "1"
      }
    },
    "disk01" = {
      name         = "raph-disk02"
      disk_size_gb = "5"
      lun          = "2"
      tags = {
        disk = "2"
      }
    },
    "disk03" = {
      name         = "raph-disk03"
      disk_size_gb = "20"
      lun          = "3"
      tags = {
        disk = "3"
      }
    },
  }
}

variable "databases" {
  type = map(any)
  default = {
    "raphdatabase01" = {
      collation                   = "SQL_LATIN1_GENERAL_CP1_CI_AS"
      max_size_gb                 = "10"
      min_capacity                = "1"
      auto_pause_delay_in_minutes = "60"
      sku_name                    = "GP_S_Gen5_1"

    },
  }
}