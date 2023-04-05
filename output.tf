output "fqdn" {
  description = "URL of the resource"
  value       = azurerm_postgresql_flexible_server.pg_flex_svr.fqdn
}