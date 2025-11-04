# ============================================================
# 构建 Go 服务镜像（无 pprof）
# ============================================================

FROM golang:1.24-alpine AS builder
WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY cmd/main.go ./cmd/main.go
RUN go build -o /app/go-leak ./cmd/main.go

# ---- 运行阶段 ----
FROM alpine:3.20
WORKDIR /app
COPY --from=builder /app/go-leak /app/go-leak

EXPOSE 6061
ENTRYPOINT ["/app/go-leak"]
