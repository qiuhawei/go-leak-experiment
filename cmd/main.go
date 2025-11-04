package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	now := time.Now().Format(time.RFC3339)
	fmt.Fprintf(w, "Hello from go-leak experiment at %s\n", now)
}

func main() {
	http.HandleFunc("/", handler)
	log.Println("🚀 Server running on :6061")
	if err := http.ListenAndServe(":6061", nil); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
