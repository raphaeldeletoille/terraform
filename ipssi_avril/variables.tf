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
      name     = "rg01"
      location = "West Europe"
    },
    "rg02" = {
      name     = "rg02"
      location = "West US"
    }
  }
}

