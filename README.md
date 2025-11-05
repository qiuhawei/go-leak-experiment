# 1) 构建镜像
docker build -t wyhoyau/go-leak:latest .

# 2) 如果需要登录 Docker Hub（第一次或凭证过期）
docker login -u YOUR_DOCKER_HUB_USER

# 3) 推送镜像到 Docker Hub
docker push wyhoyau/go-leak:latest



# 更新 Deployment 的镜像（两种方式任选其一）
kubectl set image deployment/go-leak go-leak=wyhoyau/go-leak:latest -n leak-lab

# 或：直接重启让 Deployment 拉取新的 image (如果 imagePullPolicy=IfNotPresent，先 tag 保证版本)
kubectl rollout restart deployment/go-leak -n leak-lab

# 查看 Pod 状态
kubectl get pods -n leak-lab -l app=go-leak -o wide

# 获取 Pod 列表并复制 Pod 名
kubectl get pods -n leak-lab -l app=go-leak
# 假设得到的 Pod 名为：go-leak-69d555767d-jgwhv


kubectl exec -n leak-lab go-leak-64446b4b5d-r5ngj -c pprof-agent -- \
curl -s http://localhost:6061/debug/pprof/


kubectl port-forward -n leak-lab svc/go-leak 6061:80
# 然后在本地访问：http://localhost:6061/debug/pprof/


# 列出 sidecar 写入目录，找到最新文件
kubectl exec -n leak-lab go-leak-69d555767d-jgwhv -c pprof-agent -- ls -lh /tmp/pprof
NS=leak-lab
POD=$(kubectl get pod -n $NS -l app=go-leak -o jsonpath='{.items[0].metadata.name}')

# 在容器里执行 heap dump（强制 GC 一次）
kubectl exec -n $NS $POD -c pprof-agent -- \
curl -s "http://localhost:6061/debug/pprof/heap?gc=1" -o /tmp/pprof/heap-leak.out

# 拷贝回本地
kubectl cp -n $NS $POD:/tmp/pprof/heap-leak.out ./heap-leak.out

# 在本地用 pprof 打开可视化（浏览器访问 http://localhost:8087）
go tool pprof -http=:8087 ./go-leak ./heap-leak.out