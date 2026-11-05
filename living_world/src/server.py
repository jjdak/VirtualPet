"""Loopback-only W1 runtime. No third-party packages or background model calls."""
import argparse
import atexit
from copy import deepcopy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
import time
from urllib.parse import urlsplit

from world import World

ROOT = Path(__file__).resolve().parents[2]
WEB = Path(__file__).resolve().parents[1] / 'web'
DEFAULT_SAVES = ROOT / '.runtime/living-world'


class Runtime:
    def __init__(self, save_dir=DEFAULT_SAVES):
        self.save_dir = Path(save_dir)
        self.save_dir.mkdir(parents=True, exist_ok=True)
        self.lock = threading.RLock()
        self.running, self.speed, self.error = False, 1, None
        self.world = World()
        self.restored = False
        if (self.save_dir / 'autosave.json').exists():
            self.world = self.read('autosave')
            self.restored = True
        self.stop = threading.Event()

    def read(self, slot):
        p = self.save_dir / f'{slot}.json'
        if p.stat().st_size > 1_000_000:
            raise ValueError('存档过大')
        return World.restore(json.loads(p.read_text()))

    def write(self, slot):
        path = self.save_dir / f'{slot}.json'
        temp = path.with_suffix('.tmp')
        temp.write_text(json.dumps(self.world.snapshot(), ensure_ascii=False, allow_nan=False), encoding='utf-8')
        temp.replace(path)

    def view(self):
        return dict(world=self.world.view(), running=self.running, speed=self.speed, error=self.error,
                    restored=self.restored, slots=[dict(slot=f'slot{i}', exists=(self.save_dir/f'slot{i}.json').exists())
                                                   for i in range(1, 4)])

    def command(self, body):
        if not isinstance(body, dict):
            raise ValueError('请求必须是对象')
        action = body.get('action')
        with self.lock:
            if action == 'play':
                self.running = True
            elif action == 'pause':
                self.running = False
            elif action == 'step':
                if self.running:
                    raise ValueError('请先暂停，再单步推进')
                self.world.step()
            elif action == 'speed':
                if type(body.get('value')) is not int or body['value'] not in (1, 2, 4):
                    raise ValueError('速度只支持 1、2、4')
                self.speed = body['value']
            elif action == 'environment':
                self.world.intervene(body.get('kind'), body.get('effect'), body.get('available'))
            elif action == 'hint':
                self.world.hint(body.get('actor'), body.get('kind'))
            elif action == 'save':
                self.write(self.slot(body))
            elif action in ('load', 'import', 'new'):
                if action == 'load':
                    candidate = self.read(self.slot(body))
                elif action == 'import':
                    candidate = World.restore(body.get('world'))
                else:
                    seed = body.get('seed', 42)
                    if type(seed) is not int or not 0 <= seed <= 999999:
                        raise ValueError('种子需为 0–999999 的整数')
                    candidate = World(seed)
                # Keep one recovery copy; never replace the current world on invalid input.
                self.write('before-restore')
                self.world, self.running = candidate, False
                self.restored = action != 'new'
            else:
                raise ValueError('未知操作')
            self.write('autosave')
            self.error = None
            return self.view()

    @staticmethod
    def slot(body):
        slot = body.get('slot')
        if slot not in ('slot1', 'slot2', 'slot3'):
            raise ValueError('只能使用三个指定存档槽')
        return slot

    def loop(self):
        deadline = time.monotonic()
        while not self.stop.wait(.025):
            with self.lock:
                now = time.monotonic()
                if not self.running:
                    deadline = now
                    continue
                if now < deadline:
                    continue
                try:
                    self.world.step()
                    if self.world.tick % 20 == 0:
                        self.write('autosave')
                    deadline = now + .5/self.speed
                except Exception as exc:
                    self.running = False
                    self.error = f'运行已暂停：{exc}'

    def close(self):
        self.stop.set()
        with self.lock:
            self.write('autosave')


def handler_for(runtime):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def send(self, status, data, content_type='application/json; charset=utf-8'):
            if not isinstance(data, bytes):
                data = json.dumps(data, ensure_ascii=False, allow_nan=False).encode()
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(data)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Content-Security-Policy', "default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'")
            self.end_headers()
            self.wfile.write(data)

        def trusted_host(self):
            port = self.server.server_port
            return self.headers.get('Host') in (f'127.0.0.1:{port}', f'localhost:{port}')

        def do_GET(self):
            if not self.trusted_host():
                return self.send(403, {'error': '仅允许本机访问'})
            path = urlsplit(self.path).path
            if path in ('/api/state', '/api/export'):
                with runtime.lock:
                    value = runtime.view() if path.endswith('state') else runtime.world.snapshot()
                    return self.send(200, value)
            files = {'/': ('index.html', 'text/html; charset=utf-8'),
                     '/app.js': ('app.js', 'text/javascript; charset=utf-8'),
                     '/style.css': ('style.css', 'text/css; charset=utf-8')}
            if path not in files:
                return self.send(404, {'error': '不存在的页面'})
            filename, mime = files[path]
            return self.send(200, (WEB / filename).read_bytes(), mime)

        def do_POST(self):
            if not self.trusted_host():
                return self.send(403, {'error': '仅允许本机访问'})
            origin = self.headers.get('Origin')
            if origin and origin != f'http://{self.headers.get("Host")}':
                return self.send(403, {'error': '拒绝跨站操作'})
            if self.path != '/api/command':
                return self.send(404, {'error': '不存在的操作'})
            if self.headers.get('Content-Type', '').split(';')[0] != 'application/json':
                return self.send(415, {'error': '需要 JSON 请求'})
            try:
                size = int(self.headers.get('Content-Length', '0'))
                if not 0 < size <= 1_050_000:
                    raise ValueError('请求大小不合法')
                body = json.loads(self.rfile.read(size))
                return self.send(200, runtime.command(body))
            except (ValueError, TypeError, KeyError, RecursionError) as exc:
                return self.send(400, {'error': str(exc)})
            except FileNotFoundError:
                return self.send(404, {'error': '该存档槽还没有保存内容'})
            except OSError as exc:
                return self.send(500, {'error': f'存档读写失败：{exc}'})
    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4193)
    parser.add_argument('--save-dir', type=Path, default=DEFAULT_SAVES)
    args = parser.parse_args()
    runtime = Runtime(args.save_dir)
    server = ThreadingHTTPServer(('127.0.0.1', args.port), handler_for(runtime))
    thread = threading.Thread(target=runtime.loop, daemon=True)
    thread.start()
    atexit.register(runtime.close)
    print(f'W1 小世界：http://127.0.0.1:{server.server_port}/ （初始暂停，存档：{args.save_dir}）', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        runtime.close()
        server.server_close()


if __name__ == '__main__':
    main()
