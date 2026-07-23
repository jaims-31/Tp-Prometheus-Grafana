terraform {
  backend "azurerm" {
    resource_group_name  = "fbarryRG"
    storage_account_name = "stfbarrytfstate"
    container_name        = "tfstate"
    key                  = "monitoring-etendu-solo.tfstate"
  }
}