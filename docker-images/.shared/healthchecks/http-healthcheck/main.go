package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
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
	"github.com/itchyny/gojq"
)

const healthcheckLogFile = "/homelab/healthcheck/logs/healthcheck.log"

func touchLogFile() error {
	logFile, err := os.OpenFile(healthcheckLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("could not touch logfile %s: %w", healthcheckLogFile, err)
	}
	defer func() { _ = logFile.Close() }()

	return nil
}

// nolint:errcheck
func log(level string, format string, args ...any) {
	logFile, err := os.OpenFile(healthcheckLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		_ = printLog(os.Stderr, level, format, args...)
		_ = printLog(os.Stderr, "ERROR", "Could not open logfile %s: %v", healthcheckLogFile, err)
		return
	}
	defer func() { _ = logFile.Close() }()

	if err := printLog(logFile, level, format, args...); err != nil {
		_ = printLog(os.Stderr, level, format, args...)
		_ = printLog(os.Stderr, "ERROR", "Could not write to logfile %s: %v", healthcheckLogFile, err)
	}
}

func printLog(writer io.Writer, level string, format string, args ...any) error {
	_, err := fmt.Fprint(writer, formatLogMessage(level, format, args...))

	return err
}

func formatLogMessage(level string, format string, args ...any) string {
	message := fmt.Sprintf(format, args...)
	prefix := time.Now().UTC().Format("2006-01-02T15:04:05.000Z07:00") + " [healthcheck]: [" + level + "] "
	lines := strings.Split(strings.TrimSuffix(message, "\n"), "\n")

	return prefix + strings.Join(lines, "\n"+prefix) + "\n"
}

func validateJSONBody(query *gojq.Query, bodyBytes []byte) error {
	decoder := json.NewDecoder(bytes.NewReader(bodyBytes))
	decoder.UseNumber()

	var body any
	if err := decoder.Decode(&body); err != nil {
		return fmt.Errorf("invalid JSON: %w", err)
	}

	var extraValue any
	if err := decoder.Decode(&extraValue); err != io.EOF {
		if err == nil {
			return fmt.Errorf("multiple JSON values")
		}
		return fmt.Errorf("invalid JSON: %w", err)
	}

	iterator := query.Run(body)
	var result any
	var hasResult bool
	for {
		value, ok := iterator.Next()
		if !ok {
			break
		}
		if err, ok := value.(error); ok {
			return fmt.Errorf("evaluating jq query: %w", err)
		}

		result = value
		hasResult = true
	}

	if !hasResult {
		return fmt.Errorf("jq query produced no results")
	}
	if result == nil {
		return fmt.Errorf("jq query result is null")
	}
	if resultBoolean, ok := result.(bool); ok && !resultBoolean {
		return fmt.Errorf("jq query result is false")
	}

	return nil
}

// nolint:gocyclo
func main() {
	if err := touchLogFile(); err != nil {
		// nolint:errcheck
		_ = printLog(os.Stderr, "ERROR", "%v", err)
		os.Exit(1)
	}

	// Parse arguments
	var args struct {
		URL                  string `arg:"--url,required" help:"URL to check"`
		Method               string `arg:"--method" default:"GET" help:"HTTP method"`
		BodyRegex            string `arg:"--body-regex" help:"Regex to validate response body against (optional)"`
		BodyJSON             string `arg:"--body-json" help:"jq query that must return a truthy result for JSON response body (optional)"`
		Status               string `arg:"--status" help:"Expected HTTP status code(s), delimited with \",\" for multiple values, also allows ranges with \"-\" (optional)"`
		Insecure             bool   `arg:"--insecure" help:"Skip TLS certificate validation"`
		BasicAuthUsername    string `arg:"--basic-auth-username" help:"HTTP Basic Auth username (optional)"`
		BasicAuthPassword    string `arg:"--basic-auth-password" help:"HTTP Basic Auth password (optional)"`
		BasicAuthUsernameEnv string `arg:"--basic-auth-username-env" help:"Environment variable containing the HTTP Basic Auth username (optional)"`
		BasicAuthPasswordEnv string `arg:"--basic-auth-password-env" help:"Environment variable containing the HTTP Basic Auth password (optional)"`
	}
	if err := arg.Parse(&args); err != nil {
		log("ERROR", "Error parsing healthcheck arguments: %v\n", err)
		os.Exit(1)
	}

	if args.BasicAuthUsername != "" && args.BasicAuthUsernameEnv != "" {
		log("ERROR", "Use only one of --basic-auth-username and --basic-auth-username-env\n")
		os.Exit(1)
	}
	if args.BasicAuthPassword != "" && args.BasicAuthPasswordEnv != "" {
		log("ERROR", "Use only one of --basic-auth-password and --basic-auth-password-env\n")
		os.Exit(1)
	}
	if args.BodyRegex != "" && args.BodyJSON != "" {
		log("ERROR", "Use only one of --body-regex and --body-json\n")
		os.Exit(1)
	}

	basicAuthUsername := args.BasicAuthUsername
	if args.BasicAuthUsernameEnv != "" {
		var exists bool
		basicAuthUsername, exists = os.LookupEnv(args.BasicAuthUsernameEnv)
		if !exists {
			log("ERROR", "HTTP Basic Auth username environment variable is unset: %s\n", args.BasicAuthUsernameEnv)
			os.Exit(1)
		}
	}

	basicAuthPassword := args.BasicAuthPassword
	if args.BasicAuthPasswordEnv != "" {
		var exists bool
		basicAuthPassword, exists = os.LookupEnv(args.BasicAuthPasswordEnv)
		if !exists {
			log("ERROR", "HTTP Basic Auth password environment variable is unset: %s\n", args.BasicAuthPasswordEnv)
			os.Exit(1)
		}
	}

	if (basicAuthUsername == "") != (basicAuthPassword == "") {
		log("ERROR", "HTTP Basic Auth requires both a username and password\n")
		os.Exit(1)
	}

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
				log("ERROR", "Invalid HTTP status range for --status: %q\n", status)
				os.Exit(1)
			}

			start, err1 := strconv.Atoi(strings.TrimSpace(parts[0]))
			end, err2 := strconv.Atoi(strings.TrimSpace(parts[1]))

			if err1 != nil || err2 != nil || start < 100 || end > 599 || start > end {
				log("ERROR", "Invalid HTTP status range for --status: %q\n", status)
				os.Exit(1)
			}

			for code := start; code <= end; code++ {
				expectedStatuses = append(expectedStatuses, code)
			}
		} else {
			code, err := strconv.Atoi(status)
			if err != nil || code < 100 || code > 599 {
				log("ERROR", "Invalid HTTP status code for --status: %q\n", status)
				os.Exit(1)
			}

			expectedStatuses = append(expectedStatuses, code)
		}
	}

	bodyRegex := func() *regexp.Regexp {
		if args.BodyRegex != "" {
			bodyRegex, err := regexp.Compile(args.BodyRegex)
			if err != nil {
				log("ERROR", "Invalid regex for --body-regex: %v\n", err)
				os.Exit(1)
			}
			return bodyRegex
		}

		return nil
	}()
	bodyJSONQuery := func() *gojq.Query {
		if args.BodyJSON != "" {
			bodyJSONQuery, err := gojq.Parse(args.BodyJSON)
			if err != nil {
				log("ERROR", "Invalid jq query for --body-json: %v\n", err)
				os.Exit(1)
			}
			return bodyJSONQuery
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
		log("ERROR", "Error creating request: %v\n", err)
		os.Exit(1)
	}
	if basicAuthUsername != "" {
		request.SetBasicAuth(basicAuthUsername, basicAuthPassword)
	}
	response, err := client.Do(request)
	if err != nil {
		log("ERROR", "Error performing request: %v\n", err)
		os.Exit(1)
	}

	// Validate response status
	if !slices.Contains(expectedStatuses, response.StatusCode) {
		log("ERROR", "Unexpected response status: %s\n", response.Status)
		os.Exit(1)
	}

	// Validate response body
	if bodyRegex != nil || bodyJSONQuery != nil {
		// Read and close response body
		bodyBytes, err := io.ReadAll(response.Body)
		_ = response.Body.Close()
		if err != nil {
			log("ERROR", "Error reading response body: %v\n", err)
			os.Exit(1)
		}

		if bodyRegex != nil && !bodyRegex.Match(bodyBytes) {
			log("ERROR", "Response body does not match: %s\n", bodyBytes)
			os.Exit(1)
		}
		if bodyJSONQuery != nil {
			if err := validateJSONBody(bodyJSONQuery, bodyBytes); err != nil {
				log("ERROR", "Response body does not match JSON query: %v\n", err)
				os.Exit(1)
			}
		}
	} else if response.Body != nil {
		// No body check requested; but we must close the body before exiting
		_ = response.Body.Close()
	}

	log("INFO", "Success")
	os.Exit(0)
}
