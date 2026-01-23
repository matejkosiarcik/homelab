package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	client := &http.Client{Timeout: 2 * time.Second}

	// Get port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	url := fmt.Sprintf("http://localhost:%s/", port)

	// Perform request
	resp, err := client.Get(url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error performing healthcheck: %v\n", err)
		os.Exit(1)
	}

	// Ensure body is closed before exiting, because os.Exit does not run defer
	if resp.Body != nil {
		_ = resp.Body.Close()
	}

	if resp.StatusCode == http.StatusOK {
		os.Exit(0)
	}
	fmt.Fprintf(os.Stderr, "Unexpected healthcheck status: %s\n", resp.Status)
	os.Exit(1)
}
