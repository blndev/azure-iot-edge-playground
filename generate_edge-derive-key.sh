#!/bin/bash
# creates a derived key for azure-iot-edge dps group registration by using teh following parameters
# 1 = registration id --> mostly the host name or serial number (must be unique in the iot hub!)
# 2 = primary or secondary key of the DPS enrollment group which should be used
# Source: https://docs.microsoft.com/en-us/azure/iot-edge/how-to-auto-provision-symmetric-keys#linux-workstations
REG_ID=$1
KEY=$2

#echo $REG_ID
#echo $KEY

keybytes=$(echo $KEY | base64 --decode | xxd -p -u -c 1000)
echo -n $REG_ID | openssl sha256 -mac HMAC -macopt hexkey:$keybytes -binary | base64
