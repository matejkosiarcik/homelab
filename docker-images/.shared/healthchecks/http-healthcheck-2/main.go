package main

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/spf13/pflag"
)

func main() {
	url := pflag.String("url", "", "URL to check (required)")
	method := pflag.String("method", "GET", "HTTP method")
	pflag.Parse()
	if *url == "" {
		fmt.Fprintln(os.Stderr, "--url is required")
		os.Exit(1)
	}

	client := &http.Client{Timeout: 2 * time.Second}

	// Perform request
	req, err := http.NewRequest(*method, *url, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating request: %v\n", err)
		os.Exit(1)
	}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error performing request: %v\n", err)
		os.Exit(1)
	}

	// Ensure body is closed before exiting, because os.Exit does not run defer
	if resp.Body != nil {
		_ = resp.Body.Close()
	}

	if resp.StatusCode/100 == 2 {
		os.Exit(0)
	}

	fmt.Fprintf(os.Stderr, "Unexpected response status: %s\n", resp.Status)
	os.Exit(1)
}
