
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


# Create IoT Hub
resource "azurerm_iothub" "iothub" {
  name                = "${lower(local.deploymentname)}-iothub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.default_tags

  sku {
    name     = "S1"
    capacity = "1"
  }
}

# resource  "azurerm_iothub_shared_access_policy" "iothubowner" {
#   name                = "${lower(local.deploymentname)}-sap-iothubowner"
#   resource_group_name = azurerm_resource_group.rg.name
#   iothub_name         = azurerm_iothub.iothub.name

#   registry_read  = true
#   registry_write = true
#   service_connect = true
#   device_connect = true
# }

data "azurerm_iothub_shared_access_policy" "iothubowner" {
  name                = "iothubowner"
  resource_group_name = azurerm_resource_group.rg.name
  iothub_name         = azurerm_iothub.iothub.name
}

# Create Device Provisioning Service
resource "azurerm_iothub_dps" "dps" {
  name                = "${lower(local.deploymentname)}-dps"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = local.default_tags

  sku {
    name     = "S1"
    capacity = 1
  }

  linked_hub {
    connection_string = data.azurerm_iothub_shared_access_policy.iothubowner.primary_connection_string
    location          = var.location
  }
}

resource "null_resource" "create-dps-symkey" {
  provisioner "local-exec" {
    command = "az iot dps enrollment-group create -g ${azurerm_resource_group.rg.name} --dps-name ${azurerm_iothub_dps.dps.name} --enrollment-id \"symetric-key-demo\" --edge-enabled true --primary-key ${random_id.primarysecret.hex}  --secondary-key ${random_id.secondarysecret.hex}"
  }
  depends_on = [azurerm_iothub_dps.dps]
}
#
# resource "azurerm_iothub_dps_certificate" "example" {
#   name                = "example"
#   resource_group_name = azurerm_resource_group.example.name
#   iot_dps_name        = azurerm_iothub_dps.example.name

#   certificate_content = filebase64("example.cer")
# }

# resource "local_file" "iothub_connectionstring" {
#     content     = "${azurerm_iothub_shared_access_policy.iothubowner.primary_connection_string}"
#     filename = "${path.module}/output/connectionstring"
# }
