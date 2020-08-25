# azure-iot-edge-playground
Azure IoT Edge - Tests and provisioning


# Prerequisites
To install this Lab, you need to fulfill some requirements.

## Install

* Azure CLI >= 2.0.70 https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest
* Terraform >= 0.12.6 https://learn.hashicorp.com/terraform/azure/install_az
* Python 3

## Authentication

Use 'az login' to connect to your Azure environment or use https://shell.azure.com which already contains az and terraform.

### Create a Service Principal

So we have first to cerate an Service Principle Account.
If something is unclear follow https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest= 

[source,bash]
----
az ad sp create-for-rbac --name TerraformDeploy - o json
----

Note the output PWD and AppID

Now make sure that these account has the correct rights (contributor)

[source,bash]
----
az role assignment list --assignee APP_ID
az role assignment create --assignee APP_ID --role Contributor
----


### Using the Credentials
Export the credentials into an environment variable or add them in the header of our terraform - script (not suggested!).

.credentials.sh
[source,bash]
----
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
----

### a little Helper
There is a maintained file which can be used for dev environments. It's called "credentials-template.sh".
Usually i create a copy of "credentials-template.sh" and name it "credentials-apply.sh". This file is ignored by git and will never checked in. 
Then i can add my credentials into "credentials-apply.sh" and execute ```source credentials-apply.sh``` once, before doing anything with terraform.
That prevents on development systems that the credentials are shown in the bash history and that they are mixed up for different projects because of global environment variables. 

## Create your Playground on Azure

Please check that on plan/apply the database will not be destroyed.
If so, then you will use all of your in the past collected data.


[source,bash]
----
terraform init  # download all required modules
terraform plan  # check credentials and configuration
terraform apply # install or upgrade solution
----

