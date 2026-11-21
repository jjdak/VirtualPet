"""Serve the standalone W5 scene on the local loopback interface."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path

from departure_scene import frame


WEB = Path(__file__).resolve().parents[1] / 'web/w5'
FILES = {'/': ('index.html', 'text/html'), '/app.js': ('app.js', 'text/javascript'),
         '/style.css': ('style.css', 'text/css')}


class Handler(BaseHTTPRequestHandler):
    def setup(self):
        super().setup()
        self.connection.settimeout(10)

    def log_message(self, *_):
        pass

    def send(self, status, content, mime='application/json'):
        if not isinstance(content, bytes):
            content = json.dumps(content, ensure_ascii=False, allow_nan=False).encode()
        self.send_response(status)
        self.send_header('Content-Type', mime + '; charset=utf-8')
        self.send_header('Content-Length', str(len(content)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Content-Security-Policy', "default-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        self.end_headers()
        try:
            self.wfile.write(content)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def trusted(self):
        host = self.headers.get('Host')
        return (host in (f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}')
                and self.headers.get('Origin') in (None, f'http://{host}')
                and self.headers.get('Sec-Fetch-Site') != 'cross-site')

    def do_GET(self):
        if not self.trusted():
            return self.send(403, {'error': '仅允许本机访问。'})
        if self.path not in FILES:
            return self.send(404, {'error': '没有这个页面。'})
        filename, mime = FILES[self.path]
        return self.send(200, (WEB / filename).read_bytes(), mime)

    def do_POST(self):
        if not self.trusted():
            return self.send(403, {'error': '仅允许本机访问。'})
        if self.path != '/api/frame':
            return self.send(404, {'error': '没有这个操作。'})
        if self.headers.get('Content-Type', '').split(';')[0].strip() != 'application/json':
            return self.send(415, {'error': '需要 JSON 请求。'})
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 512 or self.headers.get('Transfer-Encoding'):
                raise ValueError('请求大小无效。')
            data = json.loads(self.rfile.read(length))
            if not isinstance(data, dict) or set(data) != {'opening', 'elapsed', 'hint'}:
                raise ValueError('场景请求格式无效。')
            return self.send(200, frame(**data))
        except TimeoutError:
            return self.send(408, {'error': '连接超时，请重试。'})
        except (ValueError, UnicodeError) as exc:
            return self.send(400, {'error': str(exc)})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=4199)
    args = parser.parse_args()
    with ThreadingHTTPServer(('127.0.0.1', args.port), Handler) as server:
        print(f'趁小岚还没出发：http://127.0.0.1:{server.server_port}/', flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main()
