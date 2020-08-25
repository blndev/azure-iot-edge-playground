
#variable "client_secret" {}
provider "azurerm" {
    features {}
}


#   ----------------------------------------------------------------------------
#   Developer Information
#   ----------------------------------------------------------------------------

locals {
  architecture = "0.1"
  status = "development"
}

## Snippet to Manage Tags 
# tags = "${merge(map( 
#     "newtag", "newtagvalue"
#     ), 
#     local.default_tags 
# )}" 


#   ----------------------------------------------------------------------------
#   Resourcegroups
#   ----------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = local.deploymentname
  location = var.location
  tags     = local.default_tags
}



resource "azurerm_iothub" "example" {
  name                = "${lower(local.deploymentname)}-iothub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.default_tags

  sku {
    name     = "S1"
    capacity = "1"
  }
}


resource "azurerm_iothub" "hub1" {
  # (resource arguments)
}
