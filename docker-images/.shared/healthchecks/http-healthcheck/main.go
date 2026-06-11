package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"time"

	"github.com/alexflint/go-arg"
)

func main() {
	// Parse arguments
	var args struct {
		URL      string `arg:"--url,required" help:"URL to check"`
		Method   string `arg:"--method" default:"GET" help:"HTTP method"`
		Body     string `arg:"--body" help:"Regex to validate response body against (optional)"`
		Status   int    `arg:"--status" help:"Expected HTTP status code (optional)"`
		Insecure bool   `arg:"--insecure" help:"Skip TLS certificate validation"`
	}
	arg.MustParse(&args)

	bodyRegex := func() *regexp.Regexp {
		if args.Body != "" {
			bodyRegex, err := regexp.Compile(args.Body)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Invalid regex for --body: %v\n", err)
				os.Exit(1)
			}
			return bodyRegex
		}

		return nil
	}()

	// Perform request
	// Configure transport to optionally skip TLS verification when requested
	transport := &http.Transport{}
	if args.Insecure {
		transport.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
	}

	client := &http.Client{Timeout: 2 * time.Second, Transport: transport}
	request, err := http.NewRequest(args.Method, args.URL, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating request: %v\n", err)
		os.Exit(1)
	}
	response, err := client.Do(request)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error performing request: %v\n", err)
		os.Exit(1)
	}

	if args.Status != 0 {
		if response.StatusCode != args.Status {
			fmt.Fprintf(os.Stderr, "Unexpected response status: %s\n", response.Status)
			os.Exit(1)
		}
	} else {
		if response.StatusCode/100 != 2 {
			fmt.Fprintf(os.Stderr, "Unexpected response status: %s\n", response.Status)
			os.Exit(1)
		}
	}

	if bodyRegex != nil {
		// Read and close response body
		bodyBytes, err := io.ReadAll(response.Body)
		_ = response.Body.Close()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading response body: %v\n", err)
			os.Exit(1)
		}

		// Test regex
		if !bodyRegex.Match(bodyBytes) {
			fmt.Fprintf(os.Stderr, "Response body does not match: %s\n", bodyBytes)
			os.Exit(1)
		}
	} else if response.Body != nil {
		// No body check requested; but we must close the body before exiting
		_ = response.Body.Close()
	}

	os.Exit(0)
}
