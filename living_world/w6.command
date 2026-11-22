#!/bin/bash
set -eu

cd -- "$(dirname -- "$0")"
port=4200
if [[ ${1:-} = "--port" && $# = 2 ]]; then
  port=$2
elif [[ $# != 0 ]]; then
  printf '用法：%s [--port 端口]\n' "$0" >&2
  exit 2
fi

exec python3 -u -m http.server "$port" --bind 127.0.0.1 --directory web/w6
