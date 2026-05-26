package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	// Parse flags
	urlFlag := flag.String("url", "", "URL to check (required)")
	methodFlag := flag.String("method", "GET", "HTTP method to use (default GET)")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s --url URL [--method METHOD]\n", os.Args[0])
		flag.VisitAll(func(f *flag.Flag) {
			fmt.Fprintf(os.Stderr, "  --%s\t%s\n", f.Name, f.Usage)
		})
	}
	flag.Parse()
	if *urlFlag == "" {
		fmt.Fprintln(os.Stderr, "Error: --url is required")
		flag.Usage()
		os.Exit(2)
	}
	url := *urlFlag
	method := strings.ToUpper(*methodFlag)

	client := &http.Client{Timeout: 2 * time.Second}

	// Perform request
	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating request: %v\n", err)
		os.Exit(1)
	}
	resp, err := client.Do(req)
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
