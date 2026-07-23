data "azurerm_resource_group" "rg" {
  name = "fbarryRG"
}

# Creation of the App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "plan-fbarry-monitoring"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 3. Creation of the Linux Web App
resource "azurerm_linux_web_app" "app" {
  name                = "app-fbarry-monitoring-unique"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  # # Environment variable forcing Azure to automatically build the Flask app
  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }
}