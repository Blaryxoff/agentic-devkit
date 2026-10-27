#!/usr/bin/env python3
import argparse
import copy
import json
import os
import shutil
import signal
import subprocess
import tempfile
import threading
import zlib
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlsplit


CASES = ('C012', 'C013', 'C015', 'C017', 'C018', 'C019', 'C020', 'C021', 'C029', 'C030', 'C031', 'C032', 'C033')


def certificate(opaque=False):
    rgb, alpha = bytearray(), bytearray()
    for y in range(16):
        for x in range(16):
            inside = (x - 7.5) ** 2 + (y - 7.5) ** 2 < 36
            rgb.extend((220, 20, 20) if inside else (255, 255, 255))
            alpha.append(255 if inside else 0)

    def stream(metadata, data):
        return (f'<< {metadata} /Length {len(data)} >>\nstream\n'.encode()
                + data + b'\nendstream')

    drawing = b'0 0 1 rg 20 20 160 100 re f\nq 80 0 0 80 60 30 cm /Seal Do Q\nBT /F1 14 Tf 20 145 Td (Recipient R - template t1) Tj ET'
    objects = [
        b'<< /Type /Catalog /Pages 2 0 R >>',
        b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 240 180] /Resources << /Font << /F1 4 0 R >> /XObject << /Seal 6 0 R >> >> /Contents 5 0 R /Annots [8 0 R] >>',
        b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        stream('', drawing),
        stream('/Type /XObject /Subtype /Image /Width 16 /Height 16 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode'
               + ('' if opaque else ' /SMask 7 0 R'), zlib.compress(rgb)),
        stream('/Type /XObject /Subtype /Image /Width 16 /Height 16 /ColorSpace /DeviceGray /BitsPerComponent 8 /Filter /FlateDecode', zlib.compress(alpha)),
        b'<< /Type /Annot /Subtype /Link /Rect [20 20 180 120] /Border [0 0 0] /A << /S /URI /URI (/verify/x1) >> >>',
    ]
    result, offsets = bytearray(b'%PDF-1.4\n'), [0]
    for number, obj in enumerate(objects, 1):
        offsets.append(len(result))
        result.extend(f'{number} 0 obj\n'.encode() + obj + b'\nendobj\n')
    xref = len(result)
    result.extend(f'xref\n0 {len(offsets)}\n0000000000 65535 f \n'.encode())
    for offset in offsets[1:]:
        result.extend(f'{offset:010d} 00000 n \n'.encode())
    result.extend(f'trailer\n<< /Size {len(offsets)} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode())
    return bytes(result)


def union_duration(intervals):
    total, end = 0, 0
    for start, stop in sorted(intervals):
        total += max(0, stop - max(start, end))
        end = max(end, stop)
    return total


class Fixture:
    def __init__(self, case='C030', mode='clean'):
        if case not in CASES or mode not in ('clean', 'fault'):
            raise ValueError('unsupported case or mode')
        self.case, self.mode = case, mode
        self.revisions = {'frontend': 'r1' if case == 'C012' else 'r2',
                          'api': 'a1' if case == 'C012' else 'a2', 'worker': 'w1'}
        self.clock = 0
        self.actions, self.jobs, self.sent, self.receipts = [], [], [], []
        self.messages, self.refunds, self.ledger = [], [], []
        self.balance = 20
        self.sessions = {'s1': 'u1', 's2': 'u2'}
        self.session, self.client = 's1', 'web'
        self.position, self.interval_start = 0, 0
        self.pending, self.events, self.received, self.stored = [], [], [], []
        self.playing, self.defer = False, False
        self.media, self.media_error = None, None

    def broken(self, case):
        return self.case == case and self.mode == 'fault'

    def record(self, action, **fields):
        item = {'sequence': len(self.actions) + 1, 'clock': self.clock,
                'action': action, **fields}
        self.actions.append(item)
        return item

    def state(self):
        reports = {}
        for client in ('web', 'native-synthetic'):
            reports[client] = {}
            for user in self.sessions.values():
                records = [e for e in self.stored if e['user'] == user and e['client'] == client]
                reports[client][user] = (
                    max((e['position'] for e in records), default=0) if self.broken('C031')
                    else union_duration([e['interval'] for e in records if e['watched']]))
        return copy.deepcopy({
            'revisions': self.revisions, 'clock': self.clock, 'actions': self.actions,
            'modules': ['home', 'profile'] + ([] if self.broken('C015') else ['reports']),
            'bundle_files': 4, 'jobs': self.jobs, 'messages': self.messages,
            'sent': self.sent, 'receipts': self.receipts, 'balance': self.balance,
            'refunds': self.refunds, 'ledger': self.ledger,
            'player': {'position': self.position, 'playing': self.playing,
                       'session': self.session, 'client': self.client, 'pending': self.pending},
            'emitted': self.events, 'received': self.received, 'stored': self.stored,
            'reports': reports, 'runtime': 'synthetic; no native device or Safari proof',
            'recording': {'status': 'ready' if self.media is not None else 'blocked',
                          'error': self.media_error},
        })

    def emit(self, watched=True):
        event = {'id': f'e{len(self.events) + 1}', 'user': self.sessions[self.session],
                 'session': self.session, 'client': self.client, 'position': self.position,
                 'watched': watched, 'interval': [self.interval_start, self.position]}
        self.interval_start = self.position
        if not (self.broken('C033') and self.client == 'native-synthetic'):
            self.events.append(copy.deepcopy(event))
            self.pending.append(event)

    def player_action(self, body):
        action = body['action']
        if action == 'play':
            self.playing = True
        elif action == 'advance':
            seconds = int(body['seconds'])
            if seconds < 0 or seconds > 100:
                raise ValueError('seconds must be 0..100')
            for _ in range(seconds):
                self.clock += 1
                if self.playing:
                    self.position += 1
                    if self.position - self.interval_start >= 10:
                        self.emit()
        elif action in ('end', 'exit', 'pause'):
            if self.position > self.interval_start and not (
                    self.broken('C030') and action in ('end', 'exit')):
                self.emit()
            self.playing = False
        elif action == 'seek':
            position = int(body['position'])
            if position < 0 or position > 100:
                raise ValueError('position must be 0..100')
            if self.position > self.interval_start:
                self.emit()
            self.position = self.interval_start = position
            self.emit(watched=False)
        elif action == 'defer':
            self.defer = bool(body['enabled'])
        elif action == 'switch':
            session = body['session']
            if session not in self.sessions:
                raise ValueError('unknown session')
            if session != self.session and not self.broken('C032') and self.position > self.interval_start:
                self.emit()
            self.session = session
        elif action == 'client':
            client = body['client']
            if client not in ('web', 'native-synthetic'):
                raise ValueError('unknown client')
            self.client = client
        elif action != 'flush':
            raise ValueError('unknown player action')
        self.record('player.' + action, position=self.position, session=self.session)
        delivery = []
        if not self.defer or action == 'flush':
            delivery, self.pending = self.pending, []
            if self.broken('C032'):
                delivery = [{**e, 'session': self.session,
                             'user': self.sessions[self.session]} for e in delivery]
        return {'events': delivery, 'session': self.session, 'position': self.position}

    def collect(self, body, token):
        event = {key: body[key] for key in
                 ('id', 'user', 'session', 'client', 'position', 'watched', 'interval')}
        authenticated = self.sessions.get(token)
        accepted = authenticated is not None and event['user'] == authenticated and event['session'] == token
        self.received.append({'event': event, 'authenticated_user': authenticated,
                              'authenticated_session': token, 'accepted': accepted})
        if not accepted:
            return 409, {'error': 'stale or unauthenticated event'}
        if not any(e['id'] == event['id'] for e in self.stored):
            self.stored.append(event)
        return 200, {'stored': event['id']}

    def post(self, path, body, headers):
        if path == '/control/revisions':
            if not body or any(k not in self.revisions or not isinstance(v, str) for k, v in body.items()):
                raise ValueError('expected component revision strings')
            self.revisions.update(body)
            return 200, self.record('revision.change', revisions=dict(self.revisions))
        if path in ('/checkout', '/catalog', '/touch', '/form'):
            return 200, self.record(path[1:], revisions=dict(self.revisions),
                                    frontend=headers.get('X-Frontend-Revision', self.revisions['frontend']),
                                    catalog_config='c1', **body)
        if path == '/exports':
            job = {'id': f'j{len(self.jobs) + 1}', 'kind': 'export', 'state': 'queued',
                   'enqueue_api': self.revisions['api']}
            self.jobs.append(job)
            return 202, job
        if path == '/worker/drain':
            for job in self.jobs:
                if job['state'] != 'queued':
                    continue
                job['worker'] = self.revisions['worker']
                job['state'] = 'ready'
                if job['kind'] == 'export':
                    job['format'] = 'v2' if job['worker'] == 'w2' else 'v1'
                    job['artifact'] = 'value\n1.00\n' if job['format'] == 'v2' else 'value\n1\n'
                elif body.get('provider_error') or job['amount'] > self.balance:
                    job['state'] = 'failed'
                    job['cause'] = 'provider' if body.get('provider_error') else 'balance'
            return 200, {'jobs': self.jobs}
        if path == '/approve':
            if not self.messages:
                self.messages.append({'id': 'm1', 'recipient': 'r1', 'channel': 'email',
                                      'subject': 'Approved', 'link': '/items/i1', 'queued_at': self.clock})
            return 202, {'queued': 'm1'}
        if path == '/clock':
            seconds = int(body['seconds'])
            if seconds < 0:
                raise ValueError('clock must advance')
            self.clock += seconds
            if self.messages and not self.broken('C019'):
                message = self.messages[0]
                if self.clock >= message['queued_at'] + 4 and not self.sent:
                    self.sent.append({**message, 'sent_at': message['queued_at'] + 4})
                if self.clock >= message['queued_at'] + 6 and not self.receipts:
                    self.receipts.append({'message': 'm1', 'recipient': 'r1', 'status': 'delivered',
                                          'delivered_at': message['queued_at'] + 6})
            return 200, {'clock': self.clock}
        if path == '/refunds':
            amount = int(body['amount'])
            if amount <= 0:
                raise ValueError('positive amount required')
            if amount > self.balance and not self.broken('C029'):
                return 409, {'error': 'insufficient balance'}
            refund = {'id': f'f{len(self.refunds) + 1}', 'amount': amount, 'state': 'accepted'}
            self.refunds.append(refund)
            self.ledger.append({'refund': refund['id'], 'amount': amount})
            self.jobs.append({'id': f'j{len(self.jobs) + 1}', 'kind': 'refund', 'amount': amount,
                              'state': 'queued'})
            return 202, refund
        if path == '/player/action':
            return 200, self.player_action(body)
        if path == '/telemetry/events':
            return self.collect(body, headers.get('Authorization', '').removeprefix('Bearer '))
        return 404, {'error': 'unknown route'}

    def html(self):
        overlay = 'auto' if self.broken('C020') else 'none'
        scroll = 'hidden' if self.broken('C021') else 'auto'
        return PAGE.replace('__REVISION__', json.dumps(self.revisions['frontend'])).replace(
            '__OVERLAY__', overlay).replace('__SCROLL__', scroll)


PAGE = '''<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Runtime fixture</title><style>
body{font:16px sans-serif;margin:20px}button,input{font:inherit;padding:12px}
#tabs{position:relative;width:240px;height:64px}#details-tab{width:240px;height:64px}
#overlay{position:absolute;inset:0;background:transparent;pointer-events:__OVERLAY__}
#form-frame{height:45vh;overflow:__SCROLL__;border:1px solid #777;margin-top:16px}
#form-space{height:55vh}#result{white-space:pre-wrap}
</style><h1>Runtime fixture</h1><output id="revision"></output>
<p><button id="checkout">Checkout</button><button id="catalog">Catalog</button></p>
<div id="tabs"><button id="details-tab">Details</button><div id="overlay"></div></div>
<p id="details" hidden>Details are visible</p>
<div id="form-frame"><label>Note <input id="note"></label><div id="form-space"></div>
<button id="submit">Submit</button></div>
<p><button id="play">Play</button><button id="advance">Advance 5 synthetic seconds</button>
<button id="end">End</button><button id="exit">Exit</button></p><pre id="result"></pre>
<script>
const frontend=__REVISION__;
document.querySelector('#revision').textContent='Loaded frontend '+frontend;
async function post(path,body={},session=null){
 const headers={'Content-Type':'application/json','X-Frontend-Revision':frontend};
 if(session)headers.Authorization='Bearer '+session;
 const response=await fetch(path,{method:'POST',headers,body:JSON.stringify(body)});
 const data=await response.json();document.querySelector('#result').textContent=JSON.stringify(data,null,2);
 return {status:response.status,data};
}
window.playerAction=async body=>{
 const {data}=await post('/player/action',body);
 const delivery=[];
 for(const event of data.events)delivery.push(await post('/telemetry/events',event,data.session));
 return {activity:data,delivery};
};
window.touchEvents=[];
for(const id of ['details-tab','overlay'])document.getElementById(id).addEventListener('pointerdown',event=>{
 touchEvents.push({target:id,pointerType:event.pointerType,trusted:event.isTrusted});
});
document.getElementById('details-tab').onclick=async event=>{
 document.getElementById('details').hidden=false;
 await post('/touch',{target:'details-tab',trusted:event.isTrusted,pointerType:event.pointerType||'unknown'});
};
document.getElementById('overlay').onclick=event=>post('/touch',{target:'overlay',trusted:event.isTrusted,pointerType:event.pointerType||'unknown'});
for(const id of ['checkout','catalog','submit'])document.getElementById(id).onclick=()=>post(id==='submit'?'/form':'/'+id);
for(const action of ['play','end','exit'])document.getElementById(action).onclick=()=>playerAction({action});
document.getElementById('advance').onclick=()=>playerAction({action:'advance',seconds:5});
</script>'''


class FixtureServer:
    def __init__(self, case='C030', mode='clean'):
        fixture = self.fixture = Fixture(case, mode)
        if case == 'C018':
            executable = shutil.which('ffmpeg')
            if executable is None:
                fixture.media_error = 'ffmpeg unavailable; generation blocked'
            else:
                with tempfile.TemporaryDirectory(prefix='review-qa-media-') as directory:
                    output = Path(directory) / 'recording.mp4'
                    try:
                        subprocess.run([executable, '-v', 'error', '-f', 'lavfi', '-i',
                                        'color=c=blue:s=64x64:r=5:d=10', '-f', 'lavfi', '-i',
                                        'sine=frequency=440:sample_rate=8000:duration=10',
                                        '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p',
                                        '-c:a', 'aac', '-movflags', '+faststart', '-shortest', str(output)],
                                       stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                       stderr=subprocess.PIPE, check=True, timeout=20)
                        fixture.media = b'invalid media container' if fixture.broken('C018') else output.read_bytes()
                    except (subprocess.SubprocessError, OSError) as error:
                        fixture.media_error = f'media generation blocked: {type(error).__name__}'

        class Handler(BaseHTTPRequestHandler):
            def setup(self):
                super().setup()
                self.connection.settimeout(2)

            def log_message(self, *_):
                pass

            def reply(self, status, data, content_type='application/json'):
                encoded = json.dumps(data).encode() if content_type == 'application/json' else (
                    data if isinstance(data, bytes) else data.encode())
                self.send_response(status)
                self.send_header('Content-Type', content_type)
                self.send_header('Content-Length', str(len(encoded)))
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                self.wfile.write(encoded)

            def do_GET(self):
                path = urlsplit(self.path).path
                if path in ('/state', '/revisions', '/modules'):
                    state = fixture.state()
                    self.reply(200, state if path == '/state' else state[path[1:]])
                elif path == '/reports' and fixture.broken('C015'):
                    self.reply(404, {'error': 'module not registered'})
                elif path == '/reports':
                    self.reply(200, '<h1>Reports</h1><button id="report-control" onclick="fetch(\'/exports\', {method: \'POST\'})">Generate report</button>', 'text/html')
                elif path in ('/', '/checkout', '/catalog', '/touch', '/keyboard', '/player'):
                    self.reply(200, fixture.html(), 'text/html; charset=utf-8')
                elif path == '/verify/x1':
                    self.reply(200, {'recipient': 'R', 'template': 't1', 'verified': True})
                elif path == '/certificate.pdf':
                    self.reply(200, certificate(fixture.broken('C017')), 'application/pdf')
                elif path == '/recording':
                    self.reply(200, '<p id="status">Ready</p><video controls src="/recording.mp4"></video>', 'text/html')
                elif path == '/recording.mp4':
                    if fixture.media is None:
                        self.reply(503, {'error': fixture.media_error or 'media not configured'})
                    else:
                        self.reply(200, fixture.media, 'video/mp4')
                elif path.startswith('/exports/'):
                    job = next((j for j in fixture.jobs if j['id'] == path.rsplit('/', 1)[1]), None)
                    if job and 'artifact' in job:
                        self.reply(200, job['artifact'], 'text/csv')
                    else:
                        self.reply(404, {'error': 'artifact unavailable'})
                else:
                    self.reply(404, {'error': 'unknown route'})

            def do_POST(self):
                try:
                    size = int(self.headers.get('Content-Length', 0))
                    if size < 0 or size > 65536:
                        raise ValueError('body too large')
                    body = json.loads(self.rfile.read(size) or b'{}')
                    if not isinstance(body, dict):
                        raise ValueError('expected JSON object')
                    status, data = fixture.post(urlsplit(self.path).path, body, self.headers)
                    self.reply(status, data)
                except (ValueError, KeyError, TypeError) as error:
                    self.reply(400, {'error': str(error)})

        self.server = HTTPServer(('127.0.0.1', 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, kwargs={'poll_interval': 0.02}, daemon=True)
        self.url = f'http://127.0.0.1:{self.server.server_port}'

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *_):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)
        if self.thread.is_alive():
            raise RuntimeError('fixture server failed to stop')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--case', choices=CASES, required=True)
    parser.add_argument('--mode', choices=('clean', 'fault'), required=True)
    parser.add_argument('--max-seconds', type=int, default=120)
    args = parser.parse_args()
    if not 1 <= args.max_seconds <= 3600:
        parser.error('--max-seconds must be 1..3600')
    stopped = threading.Event()
    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, lambda *_: stopped.set())
    with FixtureServer(args.case, args.mode) as server:
        print(json.dumps({'url': server.url, 'pid': os.getpid()}), flush=True)
        stopped.wait(args.max_seconds)


if __name__ == '__main__':
    main()
