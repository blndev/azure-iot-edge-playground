# load environment variables to build the playground
source credentials-apply.sh
# create cloud resources
terraform apply --auto-approve

#create  enrollment group with symetric key
az iot dps enrollment-group create -g {resource_group_name} --dps-name {dps_name} --enrollment-id {enrollment_id} --primary-key {primary_key} --secondary-key {secondary_key}
vagrant up iot-edge-1 iot-edge-2

#create enrollment group with x509 certificate
az iot dps enrollment-group create -g {resource_group_name} --dps-name {dps_name} --enrollment-id {enrollment_id} --primary-key {primary_key} --secondary-key {secondary_key}
vagrant up iot-edge-3 iot-edge-4



### Stop playground and remove all ressources
# vagrant destroy
# terraform destroy

