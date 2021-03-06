#   ----------------------------------------------------------------------------
#   Author: Daniel Bedarf, Aug 2020
#   ----------------------------------------------------------------------------
#   Automated Deployment of Azure IoT Hub and Device Provisioning Services
#   as a Playground and for testing purposes
#   
#   At the end of this file you will see certificate and key generation which 
#   will be moved at a later point to a own provisioning service as Azure 
#   function, container or VM. Currently they are here and hard coded
#   ----------------------------------------------------------------------------

provider "azurerm" {
    features {}
}

terraform {
  required_version = ">= 0.12"
}

#   ----------------------------------------------------------------------------
#   Developer Information
#   ----------------------------------------------------------------------------

locals {
  architecture = "1.0"
  status = "development"
}

resource "azurerm_resource_group" "rg" {
  name     = local.deploymentname
  location = var.location
  tags     = local.default_tags
}


#   ----------------------------------------------------------------------------
#   Create Infrastructure
#   ----------------------------------------------------------------------------

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

## not longer required, we can use teh build in shared access policy via data object
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
  depends_on = [azurerm_iothub.iothub]
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


# ! *********************************************************
# ! Azure ARM provider for Terraform doesn’t support managing
# ! DPS enrollment groups. For now, you’ll need to use the 
# ! Azure CLI (Aug 2020)
# ! Thats why it is placed here as local az command
# ! *********************************************************

# Details: https://docs.microsoft.com/en-us/cli/azure/ext/azure-iot/iot/dps/enrollment-group?view=azure-cli-latest#ext-azure-iot-az-iot-dps-enrollment-group-create
# Attention: (Aug/2020) requires still the az cli iot edge extensions, see readme - install section
resource "null_resource" "create-dps-symkey-enrollement" {
  provisioner "local-exec" {
    command = "az iot dps enrollment-group create -g ${azurerm_resource_group.rg.name} --dps-name ${azurerm_iothub_dps.dps.name} --enrollment-id \"symmetric-enrollement-1\" --edge-enabled true  --initial-twin-tags \"{'location':{'region':'EU/Slovakia'}}\"  --primary-key ${random_id.primarysecret.hex}  --secondary-key ${random_id.secondarysecret.hex}"
  }
  depends_on = [azurerm_iothub_dps.dps]
}


resource "null_resource" "create-dps-upload-certificate" {
  provisioner "local-exec" {
    command = "az iot dps certificate create -g ${azurerm_resource_group.rg.name} --dps-name ${azurerm_iothub_dps.dps.name} --name \"root_ca\" --path ${path.module}/.certs/certs/azure-iot-test-only.root.ca.cert.pem"
  }
  depends_on = [azurerm_iothub_dps.dps, null_resource.generate-root-certificates]
}



resource "null_resource" "create-dps-certificate-enrollement" {
  provisioner "local-exec" {
    command = "az iot dps enrollment-group create -g ${azurerm_resource_group.rg.name} --dps-name ${azurerm_iothub_dps.dps.name} --enrollment-id \"certificate-enrollement-1\" --edge-enabled true --initial-twin-tags \"{'location':{'region':'EU/Germany'}}\" --ca-name \"root_ca\""
  }
  depends_on = [null_resource.create-dps-upload-certificate]
}

#   ----------------------------------------------------------------------------
#   Snippets to be used later on or never ;)
#   ----------------------------------------------------------------------------

# resource "null_resource" "generate-derived-key-edge-2" {
#   provisioner "local-exec" {
#     command = "..." {
#       value = ""
#     }"
#   }
#    triggers = {
#      always_run = "${timestamp()}"
#    }
# }