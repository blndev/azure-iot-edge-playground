# *********************************************************
# Initialization of the Playground 
# ---------------------------------------------------------
# make sure that you have created Service Principal and 
# configured the environment variables. 
# See credentials-template
# *********************************************************


# load environment variables to build the playground
source credentials-apply.sh
# create cloud resources
terraform apply --auto-approve

# ! *********************************************************
# ! Azure ARM provider for Terraform doesn’t support managing
# ! DPS enrollment groups. For now, you’ll need to use the 
# ! Azure CLI (Aug 2020)
# ! This is done in Terraform as well
# ! *********************************************************

vagrant up

#create enrollment group with x509 certificate
#az iot dps enrollment-group create -g {resource_group_name} --dps-name {dps_name} --enrollment-id {enrollment_id} --primary-key {primary_key} --secondary-key {secondary_key}
#vagrant up iot-edge-3 iot-edge-4



### Stop playground and remove all ressources
# vagrant destroy
# terraform destroy

