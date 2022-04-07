#SQL DATABASE

variable "name" {
  type = string
}

variable "collation" {
  type = string
}

variable "server_id" {
  type = string
}

variable "min_capacity" {
  type = string
}

variable "max_size_gb" {
  type = string
}

variable "auto_pause_delay_in_minutes" {
  type = string
}


variable "sku_name" {
  #you can list the available names with the cli: shell az sql db list-editions -l westus -o table. For further information please see Azure CLI - az sql db.
  type = string
}


variable "log_analytics_workspace_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}