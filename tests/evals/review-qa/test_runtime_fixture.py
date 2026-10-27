import json
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from runtime_fixture import FixtureServer


class RuntimeFixtureTests(unittest.TestCase):
    def request(self, server, path, body=None, session=None, headers=None):
        headers = dict(headers or {})
        if session:
            headers['Authorization'] = 'Bearer ' + session
        data = None if body is None else json.dumps(body).encode()
        if data is not None:
            headers['Content-Type'] = 'application/json'
        try:
            response = urlopen(Request(server.url + path, data=data, headers=headers), timeout=3)
        except HTTPError as error:
            response = error
        with response:
            result = response.read()
            if response.headers.get_content_type() == 'application/json':
                result = json.loads(result)
            return response.status, result

    def state(self, server):
        return self.request(server, '/state')[1]

    def action(self, server, action, **fields):
        status, result = self.request(server, '/player/action', {'action': action, **fields})
        self.assertEqual(status, 200)
        statuses = []
        for event in result['events']:
            status, _ = self.request(server, '/telemetry/events', event, result['session'])
            statuses.append(status)
        return statuses

    def test_independent_component_pins_and_old_loaded_page(self):
        with FixtureServer('C012') as server:
            self.assertIn(b'const frontend="r1"', self.request(server, '/checkout')[1])
            self.request(server, '/checkout', {})
            self.request(server, '/control/revisions', {'frontend': 'r2'})
            self.request(server, '/catalog', {})
            self.request(server, '/checkout', {}, headers={'X-Frontend-Revision': 'r1'})
            state = self.state(server)
            self.assertEqual(state['revisions'], {'frontend': 'r2', 'api': 'a1', 'worker': 'w1'})
            self.assertEqual(state['actions'][0]['revisions']['frontend'], 'r1')
            self.assertEqual(state['actions'][2]['catalog_config'], 'c1')
            self.assertEqual(state['actions'][-1]['frontend'], 'r1')
            self.assertEqual(state['actions'][-1]['revisions']['frontend'], 'r2')
            self.assertIn(b'const frontend="r2"', self.request(server, '/checkout')[1])

    def test_worker_pin_is_processing_revision(self):
        with FixtureServer('C013') as server:
            self.request(server, '/exports', {})
            self.request(server, '/worker/drain', {})
            self.request(server, '/control/revisions', {'worker': 'w2'})
            self.request(server, '/exports', {})
            self.request(server, '/worker/drain', {})
            first, second = self.state(server)['jobs']
            self.assertEqual((first['worker'], first['format']), ('w1', 'v1'))
            self.assertEqual((second['worker'], second['format']), ('w2', 'v2'))
            self.assertEqual(first['enqueue_api'], second['enqueue_api'])
            self.assertEqual(self.request(server, '/exports/j1')[1], b'value\n1\n')
            self.assertEqual(self.request(server, '/exports/j2')[1], b'value\n1.00\n')

    def test_module_availability_not_bundle_count(self):
        for mode, expected in [('clean', 200), ('fault', 404)]:
            with self.subTest(mode=mode), FixtureServer('C015', mode) as server:
                self.assertEqual(self.request(server, '/reports')[0], expected)
                state = self.state(server)
                self.assertEqual(state['bundle_files'], 4)
                self.assertEqual('reports' in state['modules'], mode == 'clean')
                if mode == 'clean':
                    self.assertIn(b'id="report-control"', self.request(server, '/reports')[1])

    def test_natural_end_and_page_exit_flush_tail(self):
        for mode in ('clean', 'fault'):
            for duration, finish in [(25, 'end'), (23, 'exit')]:
                with self.subTest(mode=mode, finish=finish), FixtureServer('C030', mode) as server:
                    self.action(server, 'play')
                    self.action(server, 'advance', seconds=duration)
                    self.action(server, finish)
                    state = self.state(server)
                    self.assertEqual(state['reports']['web']['u1'], duration if mode == 'clean' else 20)
                    self.assertEqual(len(state['emitted']), 3 if mode == 'clean' else 2)
                    self.assertEqual(len(state['received']), len(state['stored']))
                    self.assertTrue(all(item['accepted'] for item in state['received']))

    def test_seek_without_viewing_and_replay(self):
        for mode, expected in [('clean', 10), ('fault', 95)]:
            with self.subTest(mode=mode), FixtureServer('C031', mode) as server:
                self.action(server, 'play')
                self.action(server, 'advance', seconds=5)
                self.action(server, 'seek', position=90)
                self.assertEqual(self.state(server)['reports']['web']['u1'], 5 if mode == 'clean' else 90)
                self.action(server, 'advance', seconds=5)
                self.action(server, 'seek', position=0)
                self.action(server, 'advance', seconds=5)
                self.action(server, 'end')
                state = self.state(server)
                self.assertEqual(state['reports']['web']['u1'], expected)
                event = state['stored'][-1]
                self.request(server, '/telemetry/events', event, 's1')
                self.assertEqual(len(self.state(server)['stored']), len(state['stored']))

    def test_queued_event_account_switch(self):
        for mode in ('clean', 'fault'):
            with self.subTest(mode=mode), FixtureServer('C032', mode) as server:
                self.action(server, 'defer', enabled=True)
                self.action(server, 'play')
                self.action(server, 'advance', seconds=5)
                self.action(server, 'end')
                self.action(server, 'switch', session='s2')
                self.assertEqual(self.action(server, 'flush'), [409] if mode == 'clean' else [200])
                state = self.state(server)
                self.assertEqual(state['emitted'][0]['user'], 'u1')
                self.assertEqual(state['received'][0]['authenticated_user'], 'u2')
                self.assertEqual(state['reports']['web']['u2'], 0 if mode == 'clean' else 5)

    def test_playing_interval_account_switch(self):
        for mode in ('clean', 'fault'):
            with self.subTest(mode=mode), FixtureServer('C032', mode) as server:
                self.action(server, 'play')
                self.action(server, 'advance', seconds=5)
                self.assertEqual(self.action(server, 'switch', session='s2'),
                                 [409] if mode == 'clean' else [])
                self.action(server, 'advance', seconds=5)
                self.action(server, 'end')
                state = self.state(server)
                self.assertEqual(state['reports']['web']['u2'], 5 if mode == 'clean' else 10)
                if mode == 'clean':
                    self.assertEqual(state['emitted'][0]['user'], 'u1')
                    self.assertEqual(state['emitted'][0]['interval'], [0, 5])
                    self.assertFalse(state['received'][0]['accepted'])
                    self.assertEqual(state['stored'][0]['interval'], [5, 10])

    def test_synthetic_client_collection_is_separate(self):
        for mode in ('clean', 'fault'):
            with self.subTest(mode=mode), FixtureServer('C033', mode) as server:
                self.action(server, 'client', client='native-synthetic')
                self.action(server, 'play')
                self.action(server, 'advance', seconds=10)
                state = self.state(server)
                self.assertEqual(state['reports']['native-synthetic']['u1'], 10 if mode == 'clean' else 0)
                self.assertEqual(state['reports']['web']['u1'], 0)
                self.assertIn('no native device', state['runtime'])

    def test_notification_deadline_receipt_and_duplicate(self):
        for mode in ('clean', 'fault'):
            with self.subTest(mode=mode), FixtureServer('C019', mode) as server:
                self.request(server, '/approve', {})
                self.request(server, '/approve', {})
                self.request(server, '/clock', {'seconds': 90})
                state = self.state(server)
                self.assertEqual(len(state['messages']), 1)
                self.assertEqual(len(state['receipts']), 1 if mode == 'clean' else 0)
                if mode == 'clean':
                    self.assertEqual(state['sent'][0]['link'], '/items/i1')
                    self.assertEqual(state['receipts'][0]['recipient'], 'r1')
                    self.assertLessEqual(state['receipts'][0]['delivered_at'], 60)

    def test_refund_rejection_and_late_provider_error(self):
        for mode in ('clean', 'fault'):
            with self.subTest(mode=mode), FixtureServer('C029', mode) as server:
                status, _ = self.request(server, '/refunds', {'amount': 50})
                self.assertEqual(status, 409 if mode == 'clean' else 202)
                state = self.state(server)
                for key in ('refunds', 'jobs', 'ledger'):
                    self.assertEqual(len(state[key]), 0 if mode == 'clean' else 1)
                self.assertEqual(self.request(server, '/refunds', {'amount': 10})[0], 202)
                self.request(server, '/worker/drain', {'provider_error': True})
                self.assertEqual(self.state(server)['jobs'][-1]['cause'], 'provider')

    @unittest.skipUnless(shutil.which('pdftoppm') and shutil.which('pdftotext'), 'PDF tools unavailable; render coverage blocked')
    def test_pdf_render_transparency_and_text(self):
        for mode, expected in [('clean', bytes((0, 0, 255))), ('fault', bytes((255, 255, 255)))]:
            with self.subTest(mode=mode), FixtureServer('C017', mode) as server, tempfile.TemporaryDirectory() as directory:
                status, pdf = self.request(server, '/certificate.pdf')
                self.assertEqual(status, 200)
                path = Path(directory) / 'certificate.pdf'
                path.write_bytes(pdf)
                text = subprocess.check_output(['pdftotext', str(path), '-'], stdin=subprocess.DEVNULL, timeout=5)
                self.assertIn(b'Recipient R - template t1', text)
                self.assertIn(b'/URI (/verify/x1)', pdf)
                self.assertEqual(self.request(server, '/verify/x1')[1],
                                 {'recipient': 'R', 'template': 't1', 'verified': True})
                ppm = subprocess.check_output(['pdftoppm', '-r', '72', '-singlefile', str(path)], stdin=subprocess.DEVNULL, timeout=5)
                header = re.match(rb'P6\s+(\d+)\s+(\d+)\s+255\s', ppm)
                self.assertIsNotNone(header)
                width = int(header[1])
                offset = header.end() + (72 * width + 62) * 3
                self.assertEqual(ppm[offset:offset + 3], expected)

    @unittest.skipUnless(shutil.which('ffmpeg') and shutil.which('ffprobe'), 'media tools unavailable; decode coverage blocked')
    def test_ready_media_has_actual_decodable_audio_video(self):
        for mode in ('clean', 'fault'):
            with self.subTest(mode=mode), FixtureServer('C018', mode) as server, tempfile.TemporaryDirectory() as directory:
                if self.state(server)['recording']['status'] == 'blocked':
                    self.skipTest(self.state(server)['recording']['error'])
                status, media = self.request(server, '/recording.mp4')
                self.assertEqual(status, 200)
                self.assertEqual(self.state(server)['recording']['status'], 'ready')
                path = Path(directory) / 'recording.mp4'
                path.write_bytes(media)
                decoded = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-progress', 'pipe:1', '-f', 'null', '-'],
                                         stdin=subprocess.DEVNULL, capture_output=True, timeout=10)
                self.assertEqual(decoded.returncode == 0, mode == 'clean')
                if mode == 'clean':
                    probe = subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(path)],
                                                    stdin=subprocess.DEVNULL, timeout=5)
                    streams = json.loads(probe)['streams']
                    self.assertEqual({s['codec_type'] for s in streams}, {'audio', 'video'})
                    self.assertTrue(all(float(s['duration']) >= 10 for s in streams))
                    self.assertTrue(any(int(t) >= 10000000 for t in re.findall(rb'out_time_us=(\d+)', decoded.stdout)))

    def test_owned_listener_stops_and_next_fixture_is_empty(self):
        with FixtureServer() as server:
            port = server.server.server_port
            self.request(server, '/approve', {})
        self.assertFalse(server.thread.is_alive())
        with socket.socket() as sock:
            sock.settimeout(1)
            self.assertNotEqual(sock.connect_ex(('127.0.0.1', port)), 0)
        with FixtureServer() as fresh:
            self.assertEqual(self.state(fresh)['messages'], [])

    def test_cli_has_bounded_lifetime(self):
        process = subprocess.run([sys.executable, str(Path(__file__).with_name('runtime_fixture.py')),
                                  '--case', 'C030', '--mode', 'clean', '--max-seconds', '1'],
                                 stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=4)
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertTrue(json.loads(process.stdout)['url'].startswith('http://127.0.0.1:'))


if __name__ == '__main__':
    unittest.main()
