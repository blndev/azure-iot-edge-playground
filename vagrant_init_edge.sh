# source: https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge-linux
curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install moby-engine -y
sudo apt-get install iotedge -y
sudo systemctl enable docker iotedge
# --> registration stuff