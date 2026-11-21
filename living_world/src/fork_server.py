"""Read-only paired replay and W4 intervention story service. Never opens or replaces personal saves."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
from urllib.parse import parse_qs, urlsplit

from context_world import ContextWorld
from intervention_story import explain

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / 'living_world/web/w3'
REVIEW = ROOT / 'docs/sim/living-world/w3/review'
MAX_BODY = 1_050_000


def example(kind):
    if kind not in ('study', 'step700', 'reversal'):
        raise ValueError('未知示例')
    if kind == 'study':
        snapshot = json.loads((REVIEW / 'example.json').read_text())
        info = json.loads((REVIEW / 'example-info.json').read_text())
        label = '固定网格筛选示例'
    elif kind == 'reversal':
        snapshot = json.loads((REVIEW / 'reversal-example.json').read_text())
        info = json.loads((REVIEW / 'reversal.json').read_text())['first_relay']
        label = '食物效果互换 · 机制示例'
    else:
        snapshot = json.loads((ROOT / 'docs/sim/living-world/w2/review/step700-example.json').read_text())
        info, label = {'actor': 'A', 'kind': 'q'}, 'W2 第 700 步示例'
    ContextWorld.restore(snapshot)
    return {'snapshot': snapshot, 'info': info, 'label': label}


def handler_for():
    # Bound concurrent CPU work. Each request restores its own independent worlds.
    gate = threading.BoundedSemaphore(2)

    class Handler(BaseHTTPRequestHandler):
        def setup(self):
            super().setup()
            self.connection.settimeout(12)

        def log_message(self, *_):
            pass

        def send(self, status, data, mime='application/json; charset=utf-8'):
            if not isinstance(data, bytes):
                data = json.dumps(data, ensure_ascii=False, allow_nan=False).encode()
            self.send_response(status)
            for name, value in {
                'Content-Type': mime, 'Content-Length': str(len(data)),
                'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff',
                'Content-Security-Policy': "default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'",
            }.items():
                self.send_header(name, value)
            self.end_headers()
            try:
                self.wfile.write(data)
            except (BrokenPipeError, ConnectionResetError):
                pass

        def trusted(self):
            host = self.headers.get('Host')
            return host in (f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}')

        def do_GET(self):
            if not self.trusted():
                return self.send(403, {'error': '仅允许本机访问'})
            url = urlsplit(self.path)
            if url.path == '/api/example':
                try:
                    return self.send(200, example(parse_qs(url.query).get('kind', ['study'])[0]))
                except FileNotFoundError:
                    return self.send(404, {'error': '所选示例尚未生成，请选择 W2 第 700 步或导入存档'})
                except (ValueError, OSError) as exc:
                    return self.send(400, {'error': str(exc)})
            files = {'/': ('index.html', 'text/html; charset=utf-8'),
                     '/app.js': ('app.js', 'text/javascript; charset=utf-8'),
                     '/style.css': ('style.css', 'text/css; charset=utf-8')}
            if url.path not in files:
                return self.send(404, {'error': '不存在的页面'})
            name, mime = files[url.path]
            return self.send(200, (WEB / name).read_bytes(), mime)

        def do_POST(self):
            if not self.trusted():
                return self.send(403, {'error': '仅允许本机访问'})
            origin = self.headers.get('Origin')
            if origin and origin != f'http://{self.headers.get("Host")}':
                return self.send(403, {'error': '拒绝跨站操作'})
            if self.headers.get('Sec-Fetch-Site') == 'cross-site':
                return self.send(403, {'error': '拒绝跨站操作'})
            if self.path != '/api/compare':
                return self.send(404, {'error': '不存在的操作'})
            if self.headers.get('Content-Type', '').split(';')[0].strip() != 'application/json':
                return self.send(415, {'error': '需要 JSON 请求'})
            try:
                size = int(self.headers.get('Content-Length', '0'))
                if not 0 < size <= MAX_BODY or self.headers.get('Transfer-Encoding'):
                    raise ValueError('请求不能超过 1 MB')
                body = json.loads(self.rfile.read(size))
                if not isinstance(body, dict) or set(body) != {'snapshot', 'actor', 'kind'}:
                    raise ValueError('需要完整 W2 存档、收件人和建议地点')
                if body['actor'] not in ('A', 'B') or body['kind'] not in ('p', 'q'):
                    raise ValueError('无效的收件人或建议地点')
                snapshot = body['snapshot']
                ContextWorld.restore(snapshot)
                if not gate.acquire(blocking=False):
                    return self.send(429, {'error': '正在计算，请稍后重试'})
                try:
                    result = explain(snapshot, body['actor'], body['kind'], horizon=240)
                finally:
                    gate.release()
                return self.send(200, result)
            except (ValueError, KeyError, TypeError, RecursionError, UnicodeError) as exc:
                return self.send(400, {'error': f'存档或请求无效：{exc}'})
            except TimeoutError:
                return self.send(408, {'error': '读取请求超时'})

    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=4195)
    args = parser.parse_args()
    server = ThreadingHTTPServer(('127.0.0.1', args.port), handler_for())
    server.daemon_threads = True
    print(f'一条线索的后来：http://127.0.0.1:{server.server_port}/ （独立对照，不读写个人存档）', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
