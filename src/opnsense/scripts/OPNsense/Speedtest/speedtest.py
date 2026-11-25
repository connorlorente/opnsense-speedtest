#!/usr/local/bin/python3
"""configd helper: speedtest.py run|status|results|servers"""
import json
import os
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

CLI = '/usr/local/bin/speedtest'
DB = '/var/db/speedtest'
HIST = DB + '/results.jsonl'
LOCK = DB + '/run.lock'
BASE = [CLI, '--format=json', '--accept-license', '--accept-gdpr']
# configd/cron give no usable HOME; the CLI stores its licence acceptance there
ENV = {'HOME': DB, 'PATH': '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin'}


def cli(args, timeout):
    os.makedirs(DB, mode=0o750, exist_ok=True)
    return subprocess.run(BASE + args, stdin=subprocess.DEVNULL, capture_output=True, text=True,
                          timeout=timeout, env=ENV)


def load_config():
    try:
        root = ET.parse('/conf/config.xml').getroot()
    except (OSError, ET.ParseError):
        return ET.Element('opnsense'), {}
    node = root.find('OPNsense/Speedtest/general')
    return root, ({c.tag: (c.text or '').strip() for c in node} if node is not None else {})


def parse_output(out):
    """Last 'result' JSON line -> history row; otherwise an error row."""
    err = 'no result in speedtest output'
    for line in reversed(out.splitlines()):
        try:
            j = json.loads(line)
        except ValueError:
            continue
        if j.get('type') == 'result':
            try:
                return {
                    'ok': True,
                    'down': round(j['download']['bandwidth'] * 8 / 1e6, 2),  # bytes/s -> Mbit/s
                    'up': round(j['upload']['bandwidth'] * 8 / 1e6, 2),
                    'ping': j['ping']['latency'],
                    'jitter': j['ping']['jitter'],
                    'loss': j.get('packetLoss'),
                    'server': '%s (%s)' % (j['server']['name'], j['server']['location']),
                    'isp': j.get('isp', ''),
                    'url': j.get('result', {}).get('url', ''),
                }
            except (KeyError, TypeError) as e:
                return {'ok': False, 'error': 'unexpected result format: %s' % e}
        if j.get('type') == 'log' and j.get('level') == 'error':
            err = j.get('message', err)
    return {'ok': False, 'error': err}


def read_rows():
    try:
        with open(HIST) as f:
            return [json.loads(l) for l in f if l.strip()]
    except OSError:
        return []


def summarize(rows, now):
    """Latest and 30-day average speeds for the gauges."""
    # shortcut: the average only sees stored results; raise retention if tests run more than ~16x a day
    good = [r for r in rows if r.get('ok')]
    month = [r for r in good if r['time'] >= now - 30 * 86400]

    def avg(key):
        return round(sum(r[key] for r in month) / len(month), 2) if month else None

    return {
        'down': good[-1]['down'] if good else None,
        'up': good[-1]['up'] if good else None,
        'avg_down': avg('down'),
        'avg_up': avg('up'),
        'max': max((max(r['down'], r['up']) for r in good), default=None),
    }


def run():
    import fcntl
    os.makedirs(DB, mode=0o750, exist_ok=True)
    lock = open(LOCK, 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return  # a test is already running
    root, cfg = load_config()
    if cfg.get('accept_license') != '1':  # the user must accept Ookla's terms in Settings first
        return record({'ok': False, 'time': int(time.time()), 'iface': '',
                       'error': 'Accept the Ookla terms in Settings before running a test.'}, cfg)
    args = []
    if cfg.get('server_id', '').isdigit():
        args.append('--server-id=' + cfg['server_id'])
    iface = cfg.get('interface', '')
    if iface.isalnum():  # logical name (wan, opt1) -> device (igb0, pppoe0)
        dev = root.findtext('interfaces/%s/if' % iface)
        if dev:
            args.append('--interface=' + dev)
    try:
        p = cli(args, 300)
        row = parse_output(p.stdout)
        if not row['ok'] and p.stderr.strip():
            row['error'] += ': ' + p.stderr.strip()[:200]
    except (OSError, subprocess.TimeoutExpired) as e:
        row = {'ok': False, 'error': str(e)}
    row['time'] = int(time.time())
    row['iface'] = iface
    record(row, cfg)


def record(row, cfg):
    keep = max(1, int(cfg.get('retention') or 500))
    rows = (read_rows() + [row])[-keep:]
    with open(HIST + '.tmp', 'w') as f:
        f.writelines(json.dumps(r) + '\n' for r in rows)
    os.replace(HIST + '.tmp', HIST)


def running():
    import fcntl
    try:
        f = open(LOCK, 'a')
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return False
    except FileNotFoundError:
        return False
    except OSError:
        return True


def servers():
    if load_config()[1].get('accept_license') != '1':
        return {'servers': []}
    try:
        p = cli(['--servers'], 60)
        for line in p.stdout.splitlines():
            j = json.loads(line)
            if 'servers' in j:
                return {'servers': [{k: s.get(k) for k in ('id', 'name', 'location', 'country')}
                                    for s in j['servers']]}
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    return {'servers': []}


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'run':
        run()
    elif cmd == 'status':
        print(json.dumps({'running': running(), 'cli': os.access(CLI, os.X_OK),
                          'license': load_config()[1].get('accept_license') == '1'}))
    elif cmd == 'clear':
        try:
            os.remove(HIST)
        except FileNotFoundError:
            pass
        print(json.dumps({'status': 'ok'}))
    elif cmd == 'results':
        print(json.dumps(read_rows()))
    elif cmd == 'summary':
        print(json.dumps(summarize(read_rows(), time.time())))
    elif cmd == 'servers':
        print(json.dumps(servers()))
    else:
        sys.exit('usage: speedtest.py run|status|results|summary|servers|clear')
