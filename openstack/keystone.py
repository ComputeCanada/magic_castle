import json
import os

from os.path import expanduser, exists

cloudmap = { }
if 'OS_AUTH_URL' in os.environ:
    cloudmap['auth_url'] = os.environ['OS_AUTH_URL']
elif 'OS_CLOUD' in os.environ:
    clouds = expanduser("~/.config/openstack/clouds.yaml")
    if exists(clouds):
        cloud_name = os.environ['OS_CLOUD']
        found = False
        key = cloud_name + ':'
        search_level = 0
        with open(clouds) as file:
            for line in file:
                line_lstripped = line.lstrip()
                if line_lstripped[:1] == '#':
                    continue
                cur_level = len(line) - len(line_lstripped)
                if cur_level < search_level:
                    break
                line_stripped = line_lstripped.rstrip()
                # Skip commented lines
                if line_stripped == key:
                    found = True
                    search_level = cur_level + 1
                elif found and line_stripped[:9] ==  'auth_url:':
                    cloudmap['auth_url'] = line_stripped[9:].strip()
                    break

if 'auth_url' in cloudmap:
    parsed_url = cloudmap['auth_url']
    cloudmap['name'] = parsed_url[8:].split('.')[0]
else:
    cloudmap['auth_url'] = ''
    cloudmap['name'] = ''

print(json.dumps(cloudmap))
