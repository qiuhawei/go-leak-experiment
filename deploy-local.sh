#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="go-leak:local-$(date +%Y%m%d%H%M%S)"
NAMESPACE="leak-lab"
MANIFEST="deploy-go-leak.yaml"

echo "🚀 Building ${IMAGE_TAG}"
docker build -t "${IMAGE_TAG}" .

# 如果是 kind 或 minikube 环境，加载镜像
if command -v kind >/dev/null 2>&1; then
  kind load docker-image "${IMAGE_TAG}"
elif command -v minikube >/dev/null 2>&1; then
  minikube image load "${IMAGE_TAG}"
fi

echo "📦 Deploying to namespace ${NAMESPACE}"
kubectl create ns "${NAMESPACE}" >/dev/null 2>&1 || true
sed "s|go-leak:latest|${IMAGE_TAG}|g" "${MANIFEST}" > /tmp/deploy.yaml
kubectl apply -f /tmp/deploy.yaml -n "${NAMESPACE}"
kubectl rollout status deploy/go-leak -n "${NAMESPACE}" --timeout=90s
kubectl get pods -n "${NAMESPACE}" -o wide
