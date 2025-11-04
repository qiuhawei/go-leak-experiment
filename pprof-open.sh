#!/usr/bin/env bash
# pprof-open.sh - build and open interactive pprof GUI for http://localhost:6061/debug/pprof/heap?gc=1
set -euo pipefail

PORT=6061
URL="http://localhost:${PORT}/debug/pprof/heap?gc=1"
BIN="./leak-demo"

echo "[*] Building binary..."
go build -o "${BIN}" .

echo "[*] Opening pprof GUI for ${URL} ..."
go tool pprof -http=:8081 "${BIN}" "${URL"
