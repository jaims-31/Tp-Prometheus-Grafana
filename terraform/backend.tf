terraform {
  backend "azurerm" {
    resource_group_name  = "rg-fbarry-student"
    storage_account_name = "franckstorage"
    container_name        = "tfstate"
    key                  = "monitoring-etendu-solo.tfstate"
  }
}