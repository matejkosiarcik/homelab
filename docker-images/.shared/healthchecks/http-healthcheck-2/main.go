package main

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/spf13/pflag"
)

func main() {
	// Parse arguments
	url := pflag.String("url", "", "URL to check (required)")
	method := pflag.String("method", "GET", "HTTP method")
	pflag.Parse()
	if *url == "" {
		fmt.Fprintln(os.Stderr, "--url is required")
		os.Exit(1)
	}

	// Perform request
	client := &http.Client{Timeout: 2 * time.Second}
	request, err := http.NewRequest(*method, *url, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating request: %v\n", err)
		os.Exit(1)
	}
	response, err := client.Do(request)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error performing request: %v\n", err)
		os.Exit(1)
	}

	// Ensure body is closed before exiting, because os.Exit does not run defer
	if response.Body != nil {
		_ = response.Body.Close()
	}

	if response.StatusCode/100 == 2 {
		os.Exit(0)
	}

	fmt.Fprintf(os.Stderr, "Unexpected response status: %s\n", response.Status)
	os.Exit(1)
}
