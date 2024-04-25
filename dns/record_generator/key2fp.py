#!/usr/bin/env python3
"""
Generate SSHFP fingerprint dictionary where:
- key correspond to SSHFP algorithm i.e: ssh-...
- value corresponds to SHA256 fingerprint of the hostkey

Terraform external data source can only output map (dict)
where both keys and values can only be string.

This external data source is required because the latest available release of
Terraform (1.8.2) can only process UTF-8 strings when decoding base64 and computing
sha256 checksums. SSH hostkeys are base64 encoded bytes, therefore trying to
decode them directly with Terraform functions fail.
"""
import base64
import hashlib
import json
import sys

outputs = {}

inputs = json.load(sys.stdin)

for alg, ssh_key in inputs.items():
    key_type, key = ssh_key.split()
    key_bytes = base64.b64decode(key)
    fp_sha256 = hashlib.sha256(key_bytes).hexdigest()
    outputs[key_type] = fp_sha256

print(json.dumps(outputs))
