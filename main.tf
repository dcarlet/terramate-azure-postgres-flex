locals {
  module_tags = {
        ARKLOUD_RESOURCE_TRACKING = "${var.service_name}"
  }
}
#
# Data Blocks
#
data "azurerm_resource_group" "deployment_rg" {
  name = var.target_rg
}

data "azurerm_subnet" "flexible_server_subnet" {
  name                 = var.flexible_server_subnet
  virtual_network_name = var.target_vnet
  resource_group_name  = var.target_vnet_rg
}

data "azurerm_private_dns_zone" "target_dns_zone" {
  name                = var.dns_zone
  resource_group_name = var.target_vnet_rg
}

data "azurerm_key_vault" "project_keyvault" {
  name                = var.project_keyvault
  resource_group_name = var.target_rg
}

# End Data Blocks

resource "random_password" "postgresql_admin_password_random" {
  length           = 16
  special          = true
  upper            = true
}

#
# Postgres SQL server
#
resource "azurerm_postgresql_flexible_server" "pg_flex_svr" {
  name                   = var.pg_server_name
  resource_group_name    = data.azurerm_resource_group.deployment_rg.name
  location               = data.azurerm_resource_group.deployment_rg.location
  version                = var.pg_version
  delegated_subnet_id    = data.azurerm_subnet.flexible_server_subnet.id
  private_dns_zone_id    = data.azurerm_private_dns_zone.target_dns_zone.id
  administrator_login    = var.admin_username
  administrator_password = random_password.postgresql_admin_password_random.result
  zone                   = var.zone
  storage_mb             = var.storage_mb
  sku_name               = var.sku
  backup_retention_days  = var.backup_rentention_days

  tags = merge(local.module_tags, var.tags)
}

#
# Postgres SQL database
#
resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.postgres_db_name
  server_id = azurerm_postgresql_flexible_server.pg_flex_svr.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}

#
# Extensions
#
resource "azurerm_postgresql_flexible_server_configuration" "pgaudit_sll" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.pg_flex_svr.id
  value     = "pgAudit"
}

resource "azurerm_postgresql_flexible_server_configuration" "exts" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.pg_flex_svr.id
  value     = var.extensions_list
  depends_on = [
    azurerm_postgresql_flexible_server_configuration.pgaudit_sll
  ]
}

#
# Azure Key Vault Secrets
#

resource "azurerm_key_vault_secret" "dbadmuser" {
  name         = "${var.service_name}-pg-adm-usr"
  value        = var.admin_username
  key_vault_id = data.azurerm_key_vault.project_keyvault.id
}

resource "azurerm_key_vault_secret" "dbadmpw" {
  name         = "${var.service_name}-pg-adm-pw"
  value        = azurerm_postgresql_flexible_server.pg_flex_svr.administrator_password
  key_vault_id = data.azurerm_key_vault.project_keyvault.id
}

