##########################################
# Postgres_specific variables.
##########################################
variable "flexible_server_subnet" {
  type    = string
  default = ""
  description = "The subnet in target_vnet that is delegated to Azure Postgres Flexible Server"
}

variable "pg_server_name" {
  type        = string
  description = "Name of postgres database server."
}

variable "pg_version" {
  type        = string
  description = "PostgreSQL Server version to deploy"
}

variable "admin_username" {
  type        = string
  description = "Username for Postgres admin user"
}

variable "zone" {
  type = number
  description = "The Availability Zone to deploy into; default 1."
}

variable "storage_mb" {
  type = number  
  description = "PostgreSQL Storage in MB"
  default = 32768

}

variable "sku" {
  type = string
  description = "PostgreSQL SKU Name"
  default     = "GP_Standard_D2s_v3"

}

variable "backup_rentention_days" {
  type = number
  default = 30
  description = "Number of days to retain the backup.  Defaults to 30."
}

variable "postgres_db_name" {
  type = string
}

variable "extensions_list" {
  type = string
  description = "The comma separated list of all extensions to install.  Ex: PG_TRGM,BTREE_GIST"
}

