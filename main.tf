
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



# resource "azurerm_iothub" "example" {
#   name                = "Example-IoTHub"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location

#   sku {
#     name     = "S1"
#     capacity = "1"
#   }

#   endpoint {
#     type                       = "AzureIotHub.StorageContainer"
#     connection_string          = azurerm_storage_account.example.primary_blob_connection_string
#     name                       = "export"
#     batch_frequency_in_seconds = 60
#     max_chunk_size_in_bytes    = 10485760
#     container_name             = azurerm_storage_container.example.name
#     encoding                   = "Avro"
#     file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
#   }
# }