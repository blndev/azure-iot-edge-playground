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
terraform apply --auto-approve --parallelism=1

# ! *********************************************************
# ! Azure ARM provider for Terraform doesn’t support managing
# ! DPS enrollment groups. For now, you’ll need to use the 
# ! Azure CLI (Aug 2020)
# ! This is done in Terraform as well
# ! *********************************************************

vagrant up iot-edge-key1
vagrant up iot-edge-cert1

# or vagrant up for all devices

### Stop playground and remove all ressources
# vagrant destroy
# terraform destroy

