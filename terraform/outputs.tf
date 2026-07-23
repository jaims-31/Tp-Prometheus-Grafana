output "app_url" {
  value       = azurerm_linux_web_app.app.default_hostname
  description = "L'URL de ton application Azure App Service"
}