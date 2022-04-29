#!/usr/bin/env python3
import base64
import hashlib
import json
import sys

ALGORITHMS = {
    'ssh-rsa' : '1',
    'ssh-dss' : '2',
    'ssh-ecdsa' : '3',
    'ssh-ed25519' : '4'
}

outputs = {}

inputs = json.load(sys.stdin)

for alg, ssh_key in inputs.items():
    key_type, key = ssh_key.split()
    key_bytes = base64.b64decode(key)
    alg_index = ALGORITHMS[key_type]
    fp_sha256 = hashlib.sha256(key_bytes).hexdigest()

    outputs['{alg}_algorithm'.format(alg=alg)] = alg_index
    outputs['{alg}_sha256'.format(alg=alg)] = fp_sha256

print(json.dumps(outputs))
