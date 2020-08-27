# see https://docs.microsoft.com/de-de/azure/iot-edge/how-to-create-test-certificates#set-up-on-linux for details
mkdir .certs
wget https://raw.githubusercontent.com/Azure/iotedge/master/tools/CACertificates/certGen.sh -q -O ./.certs/certGen.sh
wget https://raw.githubusercontent.com/Azure/iotedge/master/tools/CACertificates/openssl_root_ca.cnf -q -O ./.certs/openssl_root_ca.cnf
cd .certs
chmod u+x certGen.sh
./certGen.sh create_root_and_intermediate

./certGen.sh create_edge_device_identity_certificate "iot-edge-3"
./certGen.sh create_device_certificate "iot-edge-3-primary"
./certGen.sh create_device_certificate "iot-edge-3-secondary"

./certGen.sh create_edge_device_identity_certificate "iot-edge-4"
./certGen.sh create_device_certificate "iot-edge-4-primary"
./certGen.sh create_device_certificate "iot-edge-4-secondary"

chmod u+w certs/*