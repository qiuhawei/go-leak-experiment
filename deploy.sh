#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="leak-lab"
kubectl apply -f deploy-go-leak.yaml -n "${NAMESPACE}"
kubectl rollout status deploy/go-leak -n "${NAMESPACE}" --timeout=90s
