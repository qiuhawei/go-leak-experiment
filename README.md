# go-leak-experiment (clean base)

一个用于 Kubernetes 测试与调试的 Go 服务，不带 pprof。

## 本地构建与部署

```bash
./deploy-local.sh
kubectl port-forward svc/go-leak -n leak-lab 6061:80
curl http://localhost:6061
