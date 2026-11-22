from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import sys
import threading
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))
from departure_scene import Scene, frame
from departure_server import Handler, ThreadingHTTPServer


def hint(offset):
    return {'offset': offset, 'kind': 'q'}


class DepartureTests(unittest.TestCase):
    def test_fork_opens_after_a_tastes_but_before_b_hears(self):
        opening = frame('fork', 0, None)
        self.assertEqual(opening['start'], 336)
        self.assertEqual(opening['people']['A']['firsthand']['q']['id'], 'A:336')
        self.assertNotEqual(opening['people']['B']['heard'].get('q', {}).get('id'), 'A:336')
        self.assertEqual(opening['people']['B']['phase'], 'rest')
        self.assertEqual([e['type'] for e in opening['events']], ['experience'])

    def test_control_is_computed_only_at_actual_departure(self):
        with patch('departure_scene.Scene', wraps=Scene) as create:
            for elapsed in range(10):
                current = frame('camp', elapsed, None)
                self.assertNotIn('result', current)
                self.assertFalse(current['ended'])
                self.assertTrue(all(e['tick'] <= current['start'] + elapsed for e in current['events']))
            self.assertEqual(create.call_count, 10)
            self.assertTrue(frame('camp', 10, None)['ended'])
            self.assertEqual(create.call_count, 12)

    def test_early_and_last_moment_q_hint_change_actual_destination(self):
        decision = {'offset': 2, 'kind': 'q'}
        waiting = {'offset': 2, 'kind': 'p'}
        for offset in (0, 1):
            self.assertEqual(frame('fork', offset, hint(offset))['elapsed'], offset)
            end = frame('fork', 2, hint(offset))
            self.assertEqual(end['result'], dict(actual=decision, waiting=waiting,
                                               first=dict(speaker='player', offset=offset),
                                               waiting_first=None))
            self.assertEqual([e['type'] for e in end['events']].count('hint'), 1)
        end = frame('fork', 2, None)
        self.assertEqual(end['result']['actual'], waiting)
        self.assertEqual(end['result']['waiting'], waiting)

    def test_late_reminder_after_report_is_allowed_until_departure(self):
        heard = frame('camp', 3, None)
        self.assertEqual(heard['people']['B']['heard']['q']['id'], 'A:536')
        for offset, speaker in ((0, 'player'), (3, 'A'), (9, 'A')):
            result = frame('camp', 10, hint(offset))['result']
            self.assertEqual(result['actual'], {'offset': 10, 'kind': 'q'})
            self.assertEqual(result['actual'], result['waiting'])
            self.assertEqual(result['first']['speaker'], speaker)
            self.assertEqual(result['waiting_first'], {'offset': 3, 'speaker': 'A'})

    def test_simulation_order_excludes_report_after_decision_on_same_tick(self):
        scene = Scene('fork')
        scene.advance(2)
        scene.world.emit('message', '测试同一步但出发后的传话。', sender='A', receiver='B',
                         evidence_tick=scene.start)
        self.assertEqual([e['type'] for e in scene.events()][-2:], ['decision', 'message'])
        self.assertIsNone(scene.speech())

    def test_end_and_malformed_inputs(self):
        for opening, limit in (('fork', 2), ('camp', 10)):
            for elapsed, reminder in ((limit, hint(limit)), (limit + 1, None),
                                      (1, hint(2)), (1, {'offset': False, 'kind': 'q'}),
                                      (1, {'offset': 0, 'kind': 'p'}),
                                      (1, {'offset': 0, 'kind': []}),
                                      (1, [hint(0), hint(1)]), (False, None)):
                with self.subTest(opening=opening, elapsed=elapsed, reminder=reminder):
                    with self.assertRaises(ValueError):
                        frame(opening, elapsed, reminder)
        scene = Scene('fork')
        scene.advance(0, hint(0))
        with self.assertRaisesRegex(ValueError, '一次'):
            scene.advance(1, hint(1))


class DepartureHTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, recipe, headers=None):
        url = f'http://127.0.0.1:{self.server.server_port}/api/frame'
        request = Request(url, json.dumps(recipe).encode(),
                          {'Content-Type': 'application/json', **(headers or {})})
        with urlopen(request, timeout=3) as response:
            return json.load(response)

    def test_concurrent_sessions_retry_and_restart_from_same_opening(self):
        waiting = dict(opening='fork', elapsed=2, hint=None)
        reminded = dict(waiting, hint=hint(1))
        with ThreadPoolExecutor(4) as executor:
            results = list(executor.map(self.request, [waiting, reminded, waiting, reminded]))
        self.assertEqual(results[0], results[2])
        self.assertEqual(results[1], results[3])
        self.assertEqual(results[0]['result']['actual']['kind'], 'p')
        self.assertEqual(results[1]['result']['actual']['kind'], 'q')
        restart = self.request(dict(waiting, elapsed=0))
        self.assertEqual(restart, json.loads(json.dumps(frame('fork', 0, None))))
        self.assertNotIn('result', restart)

    def test_http_rejects_wrong_host_cross_origin_and_invalid_recipe(self):
        recipe = dict(opening='fork', elapsed=0, hint=None)
        for headers, code in (({'Origin': 'https://example.invalid'}, 403),
                              ({'Host': 'example.invalid'}, 403),
                              ({'Sec-Fetch-Site': 'cross-site'}, 403),
                              ({'Content-Type': 'text/plain'}, 415)):
            with self.assertRaises(HTTPError) as error:
                self.request(recipe, headers)
            self.assertEqual(error.exception.code, code)
            error.exception.close()
        for bad in (dict(recipe, opening='invalid'), dict(recipe, unknown=True), 'a' * 512):
            with self.assertRaises(HTTPError) as error:
                self.request(bad)
            self.assertEqual(error.exception.code, 400)
            error.exception.close()


if __name__ == '__main__':
    unittest.main()
