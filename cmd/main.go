// cmd/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
	_ "net/http/pprof"
	"os"
	"strconv"
	"time"
)

var leaks [][]byte // 永久持有，制造内存泄漏

// default config
const (
	defaultSizeMB   = 10 // 每次分配多少 MB
	defaultInterval = 1  // 每隔多少秒分配一次
	defaultMaxCount = 0  // 0 表示无限制
)

func leakWorker(sizeMB int, interval time.Duration, maxCount int) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	count := 0
	for {
		<-ticker.C
		data := make([]byte, sizeMB<<20) // 分配 sizeMB MB
		// 写入一点内容，避免编译器或逃逸优化（可选）
		if len(data) > 0 {
			data[0] = byte(count % 256)
			data[len(data)-1] = byte((count + 1) % 256)
		}
		leaks = append(leaks, data)
		count++
		log.Printf("leakWorker: allocated %d MB, total allocations=%d\n", sizeMB, count)

		if maxCount > 0 && count >= maxCount {
			log.Printf("leakWorker: reached maxCount=%d, stopping worker\n", maxCount)
			return
		}
	}
}

func parseEnvInt(name string, def int) int {
	v := os.Getenv(name)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil || n < 0 {
		return def
	}
	return n
}

func main() {
	// 从环境变量读取配置，方便在 k8s 中通过 env 配置
	sizeMB := parseEnvInt("LEAK_SIZE_MB", defaultSizeMB)
	intervalSec := parseEnvInt("LEAK_INTERVAL_SEC", defaultInterval)
	maxCount := parseEnvInt("LEAK_MAX_COUNT", defaultMaxCount)

	interval := time.Duration(intervalSec) * time.Second

	// 启动后台泄漏 worker（无需外部访问）
	go leakWorker(sizeMB, interval, maxCount)

	// 保留原来的 HTTP + pprof
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		now := time.Now().Format(time.RFC3339)
		fmt.Fprintf(w, "Leaking %dMB every %v — allocations=%d\n", sizeMB, interval, len(leaks))
		fmt.Fprintf(w, "LEAK_SIZE_MB=%d, LEAK_INTERVAL_SEC=%d, LEAK_MAX_COUNT=%d\n", sizeMB, intervalSec, maxCount)
		fmt.Fprintf(w, "Time: %s\n", now)
	})
	log.Printf("🚀 Leak experiment running on :6061 (auto leak %dMB every %ds, max=%d)\n",
		sizeMB, intervalSec, maxCount)
	if err := http.ListenAndServe(":6061", nil); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
