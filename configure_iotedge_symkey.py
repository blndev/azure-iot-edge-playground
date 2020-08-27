#!/usr/bin/env python3
# Author: Daniel Bedarf
# Goal:   Modify Azure IoT Edge Configuration to enable DPS support

import yaml
from shutil import copyfile
copyfile('/etc/iotedge/config.yaml', '/etc/iotedge/config.yaml.org')

with open('/etc/iotedge/config.yaml') as f:
    data = yaml.load(f)
with open('./config/iotedge/scope_id') as fsid:
    sid=fsid.read().replace('\n', '')
with open('./config/iotedge/iot-edge-1.key') as fkey:
    key=fkey.read().replace('\n', '')
with open('./config/iotedge/iot-edge-1.reg') as freg:
    reg=freg.read().replace('\n', '')

data['provisioning']['source']='dps'
data['provisioning']['scope_id']=sid
data['provisioning']['global_endpoint']='https://global.azure-devices-provisioning.net'
data['provisioning']['attestation']['method'] = 'symmetric_key'
data['provisioning']['attestation']['registration_id'] = reg
data['provisioning']['attestation']['symmetric_key'] = key

with open('/etc/iotedge/config.yaml', 'w') as w:
    
    yaml.dump(data, w, default_flow_style=False)

print (data)