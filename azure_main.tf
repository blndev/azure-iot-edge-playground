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
resource "null_resource" "create-dps-symkey" {
  provisioner "local-exec" {
    command = "az iot dps enrollment-group create -g ${azurerm_resource_group.rg.name} --dps-name ${azurerm_iothub_dps.dps.name} --enrollment-id \"symetric-key-demo\" --edge-enabled true --primary-key ${random_id.primarysecret.hex}  --secondary-key ${random_id.secondarysecret.hex}"
  }
  depends_on = [azurerm_iothub_dps.dps]
}


# ! ----------------------------------------------------------------------------
# ! This section needs to be moved to a provisioning service
# ! Hard coded values are fine only for the first version of this POC
# ! ----------------------------------------------------------------------------

resource "null_resource" "generate-output-folder" {
  provisioner "local-exec" {
    command = "mkdir .output"
  }
}

# This will generate a temporary ca and certificates for our Edges
locals {
  edge1="iot-edge-key1" 
  edge2="iot-edge-key2" 
}

# Edge 1 - Registration ID
resource "null_resource" "generate-derived-reg-edge-1" {
  provisioner "local-exec" {
    command = "echo ${local.edge1} > .output/${local.edge1}.reg" 
  }
  depends_on = [null_resource.generate-output-folder]
}

# Edge 1 - derived Key
resource "null_resource" "generate-derived-key-edge-1" {
  provisioner "local-exec" {
    command = "bash ./generate_edge-derive-key.sh ${local.edge1} ${random_id.primarysecret.hex} > .output/${local.edge1}.key"
  }
  depends_on = [null_resource.generate-output-folder]
}

# Edge 2 - Registration ID
resource "null_resource" "generate-derived-reg-edge-2" {
  provisioner "local-exec" {
    command = "echo ${local.edge2} > .output/${local.edge2}.reg" 
  }
  depends_on = [null_resource.generate-output-folder]
}

# Edge 2 - derived Key
resource "null_resource" "generate-derived-key-edge-2" {
  provisioner "local-exec" {
    command = "bash ./generate_edge-derive-key.sh ${local.edge2} ${random_id.primarysecret.hex} > .output/${local.edge2}.key"
  }
  depends_on = [null_resource.generate-output-folder]
}


# General
resource "null_resource" "store-dps-scopeid" {
  provisioner "local-exec" {
    command = "echo ${azurerm_iothub_dps.dps.id_scope} > .output/scope_id" 
  }
  depends_on = [null_resource.generate-output-folder]
}

resource "null_resource" "store-dps-primary-key" {
  provisioner "local-exec" {
    command = "echo ${random_id.primarysecret.hex} > .output/primary.key" 
  }
  depends_on = [null_resource.generate-output-folder]
}

resource "null_resource" "generate-certificates" {
  provisioner "local-exec" {
    command = "bash ./generate_certificates.sh"
  }
}

output "dps-scope_id" {
  value       = azurerm_iothub_dps.dps.id_scope
  description = "The Scope ID for iot-edge registration"
}

output "Folder_Certificates" {
  value       = ".certs/certs"
  description = "Folder of the generated certificates"
}

output "Folder_IoT-Edge-RegistrationData" {
  value       = ".output/"
  description = "Folder for the generated Registration Id"
}


# resource "local_file" "iothub_config_scopeid" {
#     content     = $azurerm_iothub_dps.dps
#     filename = "${path.module}/.output/scope_id"
# }

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
