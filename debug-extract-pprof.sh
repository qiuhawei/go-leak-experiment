#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${1:-leak-lab}
POD=$(kubectl get pod -n "${NAMESPACE}" -l app=go-leak -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD" ]; then
  echo "No pod found in namespace ${NAMESPACE} with label app=go-leak"
  exit 1
fi

TMPFILE="/tmp/heap-${POD}.pprof"
DBGIMAGE="alpine/curl:latest"   # small image with curl; you can change to golang:alpine

echo "→ Pod: $POD"
echo "→ Creating debug container and fetching heap profile inside pod..."

# Run a one-shot debug container that shares network/IPC with target container (--target),
# fetch the pprof heap via 127.0.0.1:6062 (in-pod only) and write to /tmp inside the pod.
kubectl debug -n "${NAMESPACE}" -it "pod/${POD}" --image="${DBGIMAGE}" --target=go-leak -- \
  /bin/sh -c "apk add --no-cache curl >/dev/null 2>&1 || true; \
  echo '→ curl pprof...'; \
  curl -sS 'http://127.0.0.1:6062/debug/pprof/heap?gc=1' -o ${TMPFILE} && echo '→ saved ${TMPFILE}' || (echo '→ fetch failed' && exit 2)"

# copy file from pod's filesystem in the debug container namespace
LOCAL_OUT="./${POD}-heap.pprof"
echo "→ Copying ${TMPFILE} to ${LOCAL_OUT}"
kubectl cp "${NAMESPACE}/${POD}:${TMPFILE}" "${LOCAL_OUT}"

echo "→ Done. local file: ${LOCAL_OUT}"
echo "You can inspect with: go tool pprof -http=:8081 ./go-leak ${LOCAL_OUT}"
