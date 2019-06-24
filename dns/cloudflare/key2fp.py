#!/usr/bin/env python3
import base64
import hashlib
import json
import sys

inputs = json.load(sys.stdin)
ssh_key = inputs['ssh_key']

key_type, key = ssh_key.split()
key_bytes = base64.b64decode(key)

alg = {'ssh-rsa' : '1', 'ssh-dss' : '2', 'ssh-ecdsa' : '3', 'ssh-ed25519': '4'}[key_type]
fp_sha1 = hashlib.sha1(key_bytes).hexdigest()
fp_sha256 = hashlib.sha256(key_bytes).hexdigest()

outputs = {}
outputs['algorithm'] = alg
outputs['sha1'] = fp_sha1
outputs['sha256'] = fp_sha256
print(json.dumps(outputs))

