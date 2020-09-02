

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
