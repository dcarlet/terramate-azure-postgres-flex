# 1. Specify the version of the AzureRM Provider to use
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.9.0"
    }
  }
}

locals {
  module_tags = {
        ARKLOUD_RESOURCE_TRACKING = "${var.service-name}"
  }
}
#
# Data Blocks
#
data "azurerm_resource_group" "deployment-rg" {
  name = var.target-rg
}

data "azurerm_subnet" "flexible-server-subnet" {
  name                 = var.flexible-server-subnet
  virtual_network_name = var.target-vnet
  resource_group_name  = var.target-vnet-rg
}

data "azurerm_private_dns_zone" "target-dns-zone" {
  name                = var.dns-zone
  resource_group_name = var.target-vnet-rg
}

data "azurerm_key_vault" "project-keyvault" {
  name                = var.project-keyvault
  resource_group_name = var.target-rg
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
resource "azurerm_postgresql_flexible_server" "pg-flex-svr" {
  name                   = var.pg_server_name
  resource_group_name    = data.azurerm_resource_group.deployment-rg.name
  location               = data.azurerm_resource_group.deployment-rg.location
  version                = var.pg_version
  delegated_subnet_id    = data.azurerm_subnet.flexible-server-subnet.id
  private_dns_zone_id    = data.azurerm_private_dns_zone.target-dns-zone.id
  administrator_login    = var.admin_username
  administrator_password = random_password.postgresql_admin_password_random.result
  zone                   = var.zone
  storage_mb             = var.storage_mb
  sku_name               = var.sku
  backup_retention_days  = var.backup_rentention_days

  tags = merge(locals.module_tags, var.tags)
}

#
# Postgres SQL database
#
resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.postgres_db_name
  server_id = azurerm_postgresql_flexible_server.pg-flex-svr.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}

#
# Extensions
#
resource "azurerm_postgresql_flexible_server_configuration" "pgaudit-sll" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.pg-flex-svr.id
  value     = "pgAudit"
}

resource "azurerm_postgresql_flexible_server_configuration" "exts" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.pg-flex-svr.id
  value     = var.extensions-list
  depends_on = [
    azurerm_postgresql_flexible_server_configuration.pgaudit-sll
  ]
}

#
# Azure Key Vault Secrets
#

resource "azurerm_key_vault_secret" "dbadmuser" {
  name         = "${var.service-name}-pg-adm-usr"
  value        = var.admin_username
  key_vault_id = data.azurerm_key_vault.team-kv.id
}

resource "azurerm_key_vault_secret" "dbadmpw" {
  name         = "${var.service-name}-pg-adm-pw"
  value        = azurerm_postgresql_flexible_server.pg-flex-svr.administrator_password
  key_vault_id = data.azurerm_key_vault.team-kv.id
}

