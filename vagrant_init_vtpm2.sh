# https://snapcraft.io/install/tpm2-simulator-chrisccoulson/ubuntu
sudo apt install -y tpm2-tools
sudo snap install tpm2-simulator-chrisccoulson --edge
tpm2-simulator-chrisccoulson.tpm2-simulator &
tpm2_listpcrs -g 0xB
# Install Azure IoT Edge SDK for TPM Tools
# https://docs.microsoft.com/en-us/azure/iot-edge/how-to-auto-provision-simulated-device-linux
sudo apt install -y software-properties-common
sudo apt install -y cmake build-essential pkg-config
sudo apt install -y libcurl4-openssl-dev uuid-dev
git clone https://github.com/Azure/azure-iot-sdk-c.git
cd azure-iot-sdk-c
# latest LTS (check github release tags)
git checkout 2bff372a9b22b54d3d4bc9a3e74e349f68fcde46
git submodule update --init
mkdir cmake
cd cmake
#cmake ..
cmake -Duse_prov_client:BOOL=ON ..
cmake --build .
cd provisioning_client/tools/tpm_device_provision
make
#step is not possible to automate because it's waiting for "any key"
#./tpm_device_provision