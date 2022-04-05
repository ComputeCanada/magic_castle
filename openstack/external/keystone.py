import json
import os

from os.path import expanduser, exists

try:
    from yaml import safe_load
except ImportError:
    yaml_avail = False
else:
    yaml_avail = True

cloudmap = { }
if 'OS_AUTH_URL' in os.environ:
    cloudmap['auth_url'] = os.environ['OS_AUTH_URL']
elif 'OS_CLOUD' in os.environ:
    clouds = os.environ.get(
        'OS_CLIENT_CONFIG_FILE',
        expanduser("~/.config/openstack/clouds.yaml")
    )
    if exists(clouds):
        cloud_name = os.environ['OS_CLOUD']
        if yaml_avail:
            with open(clouds) as f:
                content = safe_load(f)
                if cloud_name in content['clouds']:
                    cloudmap['auth_url'] = content['clouds'][cloud_name]['auth']['auth_url']
        else:
            found = False
            key = cloud_name
            search_level = 0
            with open(clouds) as file:
                for line in file:
                    line_lstripped = line.lstrip()
                    # Skip commented lines
                    if line_lstripped[:1] == '#':
                        continue
                    cur_level = len(line) - len(line_lstripped)
                    if cur_level < search_level:
                        break
                    line_stripped = line_lstripped.rstrip().rstrip(':').strip('"\'')
                    if found and line_stripped[:9] ==  'auth_url:':
                        cloudmap['auth_url'] = line_stripped[9:].strip()
                        break
                    elif line_stripped == key:
                        found = True
                        search_level = cur_level + 1

if 'auth_url' in cloudmap:
    parsed_url = cloudmap['auth_url']
    cloudmap['name'] = parsed_url[8:].split('.')[0]
else:
    cloudmap['auth_url'] = ''
    cloudmap['name'] = ''

print(json.dumps(cloudmap))