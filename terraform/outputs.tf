output "app_url" {
  value       = azurerm_linux_web_app.app.default_hostname
  description = "L'URL de ton application Azure App Service"
}

output "dce_id" {
  value = azurerm_monitor_workspace.amw.default_data_collection_endpoint_id
}

output "dcr_id" {
  value = azurerm_monitor_workspace.amw.default_data_collection_rule_id
}

output "prometheus_vm_public_ip" {
  value = azurerm_linux_virtual_machine.prometheus_vm.public_ip_address
}