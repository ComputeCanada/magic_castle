#!/usr/bin/env python3

import base64
import json
import sys
from subprocess import Popen, PIPE

inputs = json.load(sys.stdin)
private_key = inputs['private_key']

cmd = ["openssl", "rsa", "-pubout", "-outform", "DER"]
ssl_cmd = Popen(cmd, stdin=PIPE, stdout=PIPE)
ssl_out = ssl_cmd.communicate(private_key.encode())[0]
public_key = base64.b64encode(ssl_out).decode()

output = {'public_key' : public_key}
print(json.dumps(output))
