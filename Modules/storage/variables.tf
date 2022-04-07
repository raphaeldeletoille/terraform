variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "ip_rules" {
  type = list(any)
}

variable "virtual_network_subnet_ids" {
  type = list(any)
}

