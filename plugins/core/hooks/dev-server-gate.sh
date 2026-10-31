#!/bin/sh
exec python3 "$(dirname "$0")/dev-server-gate.py" "$@"
