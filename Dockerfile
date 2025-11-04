# ---------- Build Stage ----------
FROM golang:1.24-alpine AS builder
WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY cmd ./cmd
RUN go build -o /app/go-leak ./cmd/main.go

# ---------- Runtime Stage ----------
FROM alpine:3.20
WORKDIR /app
COPY --from=builder /app/go-leak /app/go-leak
EXPOSE 6061
ENTRYPOINT ["/app/go-leak"]
