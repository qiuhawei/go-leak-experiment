package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "local"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from go-leak (version=%s)\n", version)
	})

	http.HandleFunc("/work", func(w http.ResponseWriter, r *http.Request) {
		// 模拟业务逻辑
		time.Sleep(100 * time.Millisecond)
		fmt.Fprintf(w, "Work done at %s\n", time.Now().Format(time.RFC3339))
	})

	log.Println("✅ Server running on :6061")
	if err := http.ListenAndServe(":6061", nil); err != nil {
		log.Fatalf("server exited: %v", err)
	}
}
