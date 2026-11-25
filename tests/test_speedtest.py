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
now = 100 * 86400
rows = [{'ok': True, 'time': now - 40 * 86400, 'down': 900, 'up': 100, 'ping': 99, 'jitter': 9, 'loss': 9},
        {'ok': True, 'time': now - 86400, 'down': 100, 'up': 10, 'ping': 4, 'jitter': 1, 'loss': 2},
        {'ok': True, 'time': now, 'down': 300, 'up': 30, 'ping': 6, 'jitter': 3, 'loss': None},
        {'ok': False, 'time': now, 'error': 'x'}]
m = s.summarize(rows, now)
assert m == {'max': 900, 'down': 300, 'avg_down': 200.0, 'up': 30, 'avg_up': 20.0, 'ping': 6, 'avg_ping': 5.0,
             'jitter': 3, 'avg_jitter': 2.0, 'loss': None, 'avg_loss': 2.0}, m
assert s.summarize([], now)['avg_down'] is None
print('ok')
