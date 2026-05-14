terraform {
  backend "azurerm" {
    resource_group_name  = "REPLACE_WITH_TFSTATE_RESOURCE_GROUP"
    storage_account_name = "REPLACE_WITH_TFSTATE_STORAGE_ACCOUNT"
    container_name       = "terraform"
    key                  = "dcs-apps.tfstate"
  }
}
