#!/usr/bin/env python3
# Author: Daniel Bedarf
# Goal:   Modify Azure IoT Edge Configuration to enable DPS support

import yaml
import socket
edge_name=socket.gethostname()

from shutil import copyfile
copyfile('/etc/iotedge/config.yaml', '/etc/iotedge/config.yaml.org')

with open('/etc/iotedge/config.yaml') as f:
    data = yaml.load(f)
with open('./config/iotedge/scope_id') as fsid:
    sid=fsid.read().replace('\n', '')

data['provisioning']={}
data['provisioning']['source']='dps'
data['provisioning']['scope_id']=sid
data['provisioning']['global_endpoint']='https://global.azure-devices-provisioning.net'
data['provisioning']['attestation']={}
data['provisioning']['attestation']['method'] = 'x509'
#data['provisioning']['attestation']['registration_id'] = reg
data['provisioning']['attestation']['identity_cert'] = 'file:///etc/iotedge/iot-edge-device-identity-'+ edge_name +'-full-chain.cert.pem'
data['provisioning']['attestation']['identity_pk'] = 'file:///etc/iotedge/iot-edge-device-identity-'+ edge_name +'.key.pem'

with open('/etc/iotedge/config.yaml', 'w') as w:
    yaml.dump(data, w, default_flow_style=False)

print (data)