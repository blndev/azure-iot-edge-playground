#   ----------------------------------------------------------------------------
#   Configuration Variables
#   ----------------------------------------------------------------------------

variable "location" { 
    default = "westeurope"
    description="use \"az account list-locations\" to see available locations"
}
variable "deploymentprefix" { 
    description = "A Shortname which is placed before every ressource created at azure. E.g template-vm-master-01"
    default = "Template" 
}

variable "sshUser" {
    description = "Name of the User to connect to the host"
    default = "linux"
}

variable "servercount" {
    description = "Amount of Servers in the Cluster"
    default = "1"
}
variable "serversize" {
    default = "Standard_B2ms"
}

#   ----------------------------------------------------------------------------
#   General Settings
#   ----------------------------------------------------------------------------



#   ----------------------------------------------------------------------------
#   Tags
#   ----------------------------------------------------------------------------
variable "tagOwner" { 
    description = "Added as Tag to all created Resources called 'owner'. Used to identify you."
}

variable "tagPurpose" { 
    description = "Added as Tag to all created Resources called 'Purpose'"
    default = "Evaluation"
}
variable "tagDescription" { 
    description = "This Text will be added as a Tag 'Info' to all created resources"
    default = "Azure IoT Edge Playground" 
}

#   ----------------------------------------------------------------------------
#   Calculated Variables - please do not change them
#   ----------------------------------------------------------------------------

resource "random_id" "deploymentsuffix" {
    keepers = {
        # Generate a new ID only when a new prefix is defined
        resource_group = "${var.deploymentprefix}"
    }
    byte_length = 2
}

locals {
  deploymentname = "${var.deploymentprefix}-${random_id.deploymentsuffix.hex}"
  deploymentnameCN = "${lower(var.deploymentprefix)}${lower(random_id.deploymentsuffix.hex)}" # only characters and numbers e.g. for storage accounts
}

locals {
default_tags = { 
    Owner               = "${var.tagOwner}" 
    Purpose             = "${var.tagPurpose}"
    DevelopmentStatus   = "${local.status}"
    Architecture        = "${local.architecture}"
    Deployment          = "${local.deploymentname}"
    Info                = "${var.tagDescription}"
  } 
} 