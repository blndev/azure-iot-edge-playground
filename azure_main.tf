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

# This will generate a temporary CA and certificates for our Edges
resource "null_resource" "generate-root-certificates" {
  provisioner "local-exec" {
    command = "bash ./generate_certificates.sh"
  }
}

# This defines our Edges and is used to generate Registrations Keys and Certificates
# !Attention: this names must fit to teh VM names in the vagrant - file
locals {
  edges=[
    "iot-edge-key1",
    "iot-edge-key2",
    "iot-edge-cert1",
    "iot-edge-cert2",
    "iot-edge-tpm1",
    "iot-edge-tpm2"
  ]
  edge1="cv"
  edge2="hh"
}

resource "null_resource" "generate-derived-reg-ids" {
  for_each = toset(local.edges)
  provisioner "local-exec" {
      command = "echo ${each.key} > .output/${each.key}.reg" 
    }
  depends_on = [null_resource.generate-output-folder]
}

resource "null_resource" "generate-derived-reg-keys" {
  for_each = toset(local.edges)
  provisioner "local-exec" {
    command = "bash ./generate_edge-derive-key.sh ${each.key} ${random_id.primarysecret.hex} > .output/${each.key}.key"
    }
  depends_on = [null_resource.generate-output-folder]
}

resource "null_resource" "generate-edge_device_identity_certificate" {
  for_each = toset(local.edges)
  provisioner "local-exec" {
    command = "bash ./.certs/certGen.sh create_edge_device_identity_certificate ${each.key}"
    }
  depends_on = [null_resource.generate-root-certificates]
}

resource "null_resource" "generate-edge-device_certificate" {
  for_each = toset(local.edges)
  provisioner "local-exec" {
    command = "bash ./.certs/certGen.sh create_device_certificate ${each.key}-primary"
    }
  depends_on = [null_resource.generate-root-certificates, null_resource.generate-edge_device_identity_certificate]
  triggers = {
     always_run = "${timestamp()}"
   }
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
