import json
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'opnsense', 'scripts', 'OPNsense', 'Speedtest'))
import speedtest as s  # noqa: E402

ok = json.dumps({'type': 'result', 'ping': {'jitter': 1.5, 'latency': 10.2},
                 'download': {'bandwidth': 12500000}, 'upload': {'bandwidth': 2500000},
                 'isp': 'X', 'server': {'name': 'S', 'location': 'L'}, 'result': {'url': 'u'}})
r = s.parse_output('{"type":"testStart"}\n' + ok + '\n')
assert r['ok'] and r['down'] == 100.0 and r['up'] == 20.0 and r['server'] == 'S (L)', r

e = s.parse_output('{"type":"log","level":"error","message":"Cannot connect"}\n')
assert not e['ok'] and e['error'] == 'Cannot connect', e
assert not s.parse_output('garbage')['ok']
print('ok')
