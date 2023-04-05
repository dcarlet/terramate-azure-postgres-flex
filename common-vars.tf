##########################################
# Common variables.
##########################################
variable "target_rg" {
  type        = string
  description = "The resource group to put the resource in."
}

variable "target_vnet" {
  type        = string
  description = "The vnet to put the resource in."
}

variable "target_vnet_rg" {
  type        = string
  description = "The rg for the vnet to put the resource in."
}

variable "dns_zone" {
  type    = string
  description = "The name for the private DNS zone to integrate with."
  default = "privatelink.postgres.database.usgovcloudapi.net"
}

variable "tags" {
  type = map
  description = "Set the tags for the module"
}

variable "project_keyvault" {
  type = string
  description = "The name of the keyvault to put the username and password secrets in."
}

variable "service_name" {
  type = string
  description = "This is the name of the service this database server is being created for.  Used in KV secrets and tags."
}