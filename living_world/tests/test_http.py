import json
from pathlib import Path
import sys
import tempfile
import threading
import time
import unittest
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import Request, build_opener, ProxyHandler

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'src'))
from server import Runtime, handler_for


class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.runtime=Runtime(self.temp.name)
        self.server=ThreadingHTTPServer(('127.0.0.1',0),handler_for(self.runtime))
        self.url=f'http://127.0.0.1:{self.server.server_port}'
        self.opener=build_opener(ProxyHandler({}))
        self.thread=threading.Thread(target=self.server.serve_forever,daemon=True);self.thread.start()

    def tearDown(self):
        self.runtime.close();self.server.shutdown();self.server.server_close();self.temp.cleanup()

    def request(self,path,body=None,headers=None):
        h={'Content-Type':'application/json',**(headers or {})}
        req=Request(self.url+path,data=json.dumps(body).encode() if body is not None else None,headers=h)
        try:
            with self.opener.open(req,timeout=3) as r:return r.status,r.read()
        except HTTPError as e:
            with e:return e.code,e.read()

    def test_roundtrip_and_rejected_requests_do_not_mutate(self):
        code,_=self.request('/api/command',{'action':'hint','actor':'B','kind':'q'});self.assertEqual(200,code)
        original=json.loads(self.request('/api/export')[1])
        self.assertEqual([],original['residents']['A']['hints'])
        self.assertEqual(1,len(original['residents']['B']['hints']))
        self.request('/api/command',{'action':'step'})
        self.assertEqual(200,self.request('/api/command',{'action':'import','world':original})[0])
        self.assertEqual(original,json.loads(self.request('/api/export')[1]))
        for body in [{'action':'load','slot':'../../other'},{'action':'import','world':{}},{'action':'speed','value':0},[]]:
            self.assertEqual(400,self.request('/api/command',body)[0])
            self.assertEqual(original,json.loads(self.request('/api/export')[1]))
        self.assertEqual(404,self.request('/api/command',{'action':'load','slot':'slot3'})[0])

    def test_local_origin_static_scope_and_response_headers(self):
        before=self.runtime.world.snapshot()
        self.assertEqual(403,self.request('/api/command',{'action':'step'},{'Origin':'https://example.com'})[0])
        self.assertEqual(403,self.request('/api/state',headers={'Host':'evil.example'})[0])
        self.assertEqual(404,self.request('/../../docs/live2d/continuation.json')[0])
        self.assertEqual(before,self.runtime.world.snapshot())
        for path in ['/','/app.js','/style.css']:
            with self.opener.open(self.url+path,timeout=3) as r:
                self.assertEqual(200,r.status);self.assertEqual('no-store',r.headers['Cache-Control'])
                self.assertIn("frame-ancestors 'none'",r.headers['Content-Security-Policy'])

    def test_real_clock_pause_and_restart(self):
        thread=threading.Thread(target=self.runtime.loop,daemon=True);thread.start()
        self.request('/api/command',{'action':'speed','value':4})
        self.request('/api/command',{'action':'play'})
        end=time.monotonic()+3
        while self.runtime.world.tick<4 and time.monotonic()<end:time.sleep(.02)
        self.request('/api/command',{'action':'pause'})
        tick=self.runtime.world.tick;self.assertGreaterEqual(tick,4)
        time.sleep(.2);self.assertEqual(tick,self.runtime.world.tick)
        restored=Runtime(self.temp.name)
        self.assertEqual(self.runtime.world.snapshot(),restored.world.snapshot());self.assertFalse(restored.running)
        self.runtime.stop.set();thread.join(timeout=1)


if __name__=='__main__':unittest.main()
