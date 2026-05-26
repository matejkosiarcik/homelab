package main

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/alexflint/go-arg"
)

func main() {
	// Parse arguments
	var args struct {
		Url    string `arg:"--url,required" help:"URL to check"`
		Method string `arg:"--method" default:"GET" help:"HTTP method"`
	}
	arg.MustParse(&args)

	// Perform request
	client := &http.Client{Timeout: 2 * time.Second}
	request, err := http.NewRequest(args.Method, args.Url, nil)
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
