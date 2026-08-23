package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/alexflint/go-arg"
)

// nolint:gocyclo
func main() {
	// Parse arguments
	var args struct {
		URL      string `arg:"--url,required" help:"URL to check"`
		Method   string `arg:"--method" default:"GET" help:"HTTP method"`
		Body     string `arg:"--body" help:"Regex to validate response body against (optional)"`
		Status   string `arg:"--status" help:"Expected HTTP status code(s), delimited with \",\" for multiple values, also allows ranges with \"-\" (optional)"`
		Insecure bool   `arg:"--insecure" help:"Skip TLS certificate validation"`
	}
	arg.MustParse(&args)

	var argsStatus = args.Status
	if argsStatus == "" {
		argsStatus = "200-299"
	}

	// Parse expected status codes
	var expectedStatuses []int
	for status := range strings.SplitSeq(argsStatus, ",") {
		status = strings.TrimSpace(status)

		if strings.Contains(status, "-") {
			parts := strings.Split(status, "-")
			if len(parts) != 2 {
				fmt.Fprintf(os.Stderr, "Invalid HTTP status range for --status: %q\n", status)
				os.Exit(1)
			}

			start, err1 := strconv.Atoi(strings.TrimSpace(parts[0]))
			end, err2 := strconv.Atoi(strings.TrimSpace(parts[1]))

			if err1 != nil || err2 != nil || start < 100 || end > 599 || start > end {
				fmt.Fprintf(os.Stderr, "Invalid HTTP status range for --status: %q\n", status)
				os.Exit(1)
			}

			for code := start; code <= end; code++ {
				expectedStatuses = append(expectedStatuses, code)
			}
		} else {
			code, err := strconv.Atoi(status)
			if err != nil || code < 100 || code > 599 {
				fmt.Fprintf(os.Stderr, "Invalid HTTP status code for --status: %q\n", status)
				os.Exit(1)
			}

			expectedStatuses = append(expectedStatuses, code)
		}
	}

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

	// Preconfigure transport layer to optionally skip TLS verification when requested
	transport := &http.Transport{}
	if args.Insecure {
		transport.TLSClientConfig = &tls.Config{InsecureSkipVerify: true} // #nosec G402 -- health check against internal endpoint with self-signed cert
	}

	// Perform HTTP request
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

	// Validate reponse status
	if !slices.Contains(expectedStatuses, response.StatusCode) {
		fmt.Fprintf(os.Stderr, "Unexpected response status: %s\n", response.Status)
		os.Exit(1)
	}

	// Validate response body
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
