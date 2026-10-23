package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/alexflint/go-arg"
	"github.com/itchyny/gojq"
)

var healthcheckLogFile = "/homelab/logs/healthcheck/healthcheck.log"

const checkTimeout = 2 * time.Second

type healthcheckArgs struct {
	URL                  string `arg:"--url,required" help:"Endpoint URL to check; supports file, http, https, and tcp"`
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

func checkTCP(args healthcheckArgs) error {
	endpoint, err := url.Parse(args.URL)
	if err != nil {
		return fmt.Errorf("parsing TCP URL: %w", err)
	}

	address, err := tcpAddress(endpoint)
	if err != nil {
		return err
	}

	connection, err := net.DialTimeout("tcp", address, checkTimeout)
	if err != nil {
		return fmt.Errorf("connecting to TCP address %q: %w", address, err)
	}

	return connection.Close()
}

func tcpAddress(endpoint *url.URL) (string, error) {
	if endpoint.Host == "" {
		return "", errors.New("TCP URL must include a host and port")
	}
	if endpoint.User != nil || endpoint.Path != "" || endpoint.RawQuery != "" || endpoint.Fragment != "" {
		return "", errors.New("TCP URL must contain only a host and port")
	}

	host, port, err := net.SplitHostPort(endpoint.Host)
	if err != nil || host == "" || port == "" {
		return "", errors.New("TCP URL must include a host and port")
	}

	return endpoint.Host, nil
}

func checkFile(args healthcheckArgs) error {
	endpoint, err := url.Parse(args.URL)
	if err != nil {
		return fmt.Errorf("parsing file URL: %w", err)
	}
	if endpoint.Host != "" && endpoint.Host != "localhost" {
		return fmt.Errorf("file URL host must be empty or localhost: %q", endpoint.Host)
	}
	if endpoint.User != nil || endpoint.RawQuery != "" || endpoint.Fragment != "" {
		return errors.New("file URL must not contain user info, a query, or a fragment")
	}
	if endpoint.Path == "" || !filepath.IsAbs(endpoint.Path) {
		return errors.New("file URL must include an absolute path")
	}

	fileInfo, err := os.Stat(endpoint.Path)
	if err != nil {
		return fmt.Errorf("stating file %q: %w", endpoint.Path, err)
	}
	if fileInfo.IsDir() {
		return fmt.Errorf("file path is a directory: %q", endpoint.Path)
	}

	return nil
}

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
	_ = printLog(os.Stderr, level, format, args...)

	logFile, err := os.OpenFile(healthcheckLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		_ = printLog(os.Stderr, "ERROR", "Could not open logfile %s: %v", healthcheckLogFile, err)
		return
	}
	defer func() { _ = logFile.Close() }()

	if err := printLog(logFile, level, format, args...); err != nil {
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
func checkHTTP(args healthcheckArgs) error {
	if args.BasicAuthUsername != "" && args.BasicAuthUsernameEnv != "" {
		return errors.New("use only one of --basic-auth-username and --basic-auth-username-env")
	}
	if args.BasicAuthPassword != "" && args.BasicAuthPasswordEnv != "" {
		return errors.New("use only one of --basic-auth-password and --basic-auth-password-env")
	}
	if args.BodyRegex != "" && args.BodyJSON != "" {
		return errors.New("use only one of --body-regex and --body-json")
	}

	basicAuthUsername := args.BasicAuthUsername
	if args.BasicAuthUsernameEnv != "" {
		var exists bool
		basicAuthUsername, exists = os.LookupEnv(args.BasicAuthUsernameEnv)
		if !exists {
			return fmt.Errorf("HTTP Basic Auth username environment variable is unset: %s", args.BasicAuthUsernameEnv)
		}
	}

	basicAuthPassword := args.BasicAuthPassword
	if args.BasicAuthPasswordEnv != "" {
		var exists bool
		basicAuthPassword, exists = os.LookupEnv(args.BasicAuthPasswordEnv)
		if !exists {
			return fmt.Errorf("HTTP Basic Auth password environment variable is unset: %s", args.BasicAuthPasswordEnv)
		}
	}

	if (basicAuthUsername == "") != (basicAuthPassword == "") {
		return errors.New("HTTP Basic Auth requires both a username and password")
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
				return fmt.Errorf("invalid HTTP status range for --status: %q", status)
			}

			start, err1 := strconv.Atoi(strings.TrimSpace(parts[0]))
			end, err2 := strconv.Atoi(strings.TrimSpace(parts[1]))

			if err1 != nil || err2 != nil || start < 100 || end > 599 || start > end {
				return fmt.Errorf("invalid HTTP status range for --status: %q", status)
			}

			for code := start; code <= end; code++ {
				expectedStatuses = append(expectedStatuses, code)
			}
		} else {
			code, err := strconv.Atoi(status)
			if err != nil || code < 100 || code > 599 {
				return fmt.Errorf("invalid HTTP status code for --status: %q", status)
			}

			expectedStatuses = append(expectedStatuses, code)
		}
	}

	var bodyRegex *regexp.Regexp
	if args.BodyRegex != "" {
		var err error
		bodyRegex, err = regexp.Compile(args.BodyRegex)
		if err != nil {
			return fmt.Errorf("invalid regex for --body-regex: %w", err)
		}
	}

	var bodyJSONQuery *gojq.Query
	if args.BodyJSON != "" {
		var err error
		bodyJSONQuery, err = gojq.Parse(args.BodyJSON)
		if err != nil {
			return fmt.Errorf("invalid jq query for --body-json: %w", err)
		}
	}

	// Preconfigure transport layer to optionally skip TLS verification when requested
	transport := &http.Transport{}
	if args.Insecure {
		transport.TLSClientConfig = &tls.Config{InsecureSkipVerify: true} // #nosec G402 -- health check against internal endpoint with self-signed cert
	}

	// Perform HTTP request
	client := &http.Client{Timeout: checkTimeout, Transport: transport}
	request, err := http.NewRequest(args.Method, args.URL, nil)
	if err != nil {
		return fmt.Errorf("creating request: %w", err)
	}
	if basicAuthUsername != "" {
		request.SetBasicAuth(basicAuthUsername, basicAuthPassword)
	}
	response, err := client.Do(request)
	if err != nil {
		return fmt.Errorf("performing request: %w", err)
	}
	defer func() { _ = response.Body.Close() }()

	// Validate response status
	if !slices.Contains(expectedStatuses, response.StatusCode) {
		return fmt.Errorf("unexpected response status: %s", response.Status)
	}

	// Validate response body
	if bodyRegex != nil || bodyJSONQuery != nil {
		// Read response body for validation.
		bodyBytes, err := io.ReadAll(response.Body)
		if err != nil {
			return fmt.Errorf("reading response body: %w", err)
		}

		if bodyRegex != nil && !bodyRegex.Match(bodyBytes) {
			return fmt.Errorf("response body does not match: %s", bodyBytes)
		}
		if bodyJSONQuery != nil {
			if err := validateJSONBody(bodyJSONQuery, bodyBytes); err != nil {
				return fmt.Errorf("response body does not match JSON query: %w", err)
			}
		}
	}

	return nil
}

func main() {
	var args healthcheckArgs
	parser, err := arg.NewParser(arg.Config{}, &args)
	if err != nil {
		// nolint:errcheck
		_, _ = fmt.Fprintf(os.Stderr, "Error configuring healthcheck arguments: %v\n", err)
		os.Exit(1)
	}
	parseErr := parser.Parse(os.Args[1:])
	if errors.Is(parseErr, arg.ErrHelp) {
		parser.WriteHelp(os.Stdout)
		return
	}

	if err := touchLogFile(); err != nil {
		// nolint:errcheck
		_ = printLog(os.Stderr, "ERROR", "%v", err)
		os.Exit(1)
	}
	if parseErr != nil {
		log("ERROR", "Error parsing healthcheck arguments: %v\n", parseErr)
		os.Exit(1)
	}

	endpoint, err := url.Parse(args.URL)
	if err != nil {
		log("ERROR", "Error parsing URL: %v\n", err)
		os.Exit(1)
	}

	switch strings.ToLower(endpoint.Scheme) {
	case "file":
		if err := checkFile(args); err != nil {
			log("ERROR", "File health check failed: %v\n", err)
			os.Exit(1)
		}
	case "tcp":
		if err := checkTCP(args); err != nil {
			log("ERROR", "TCP health check failed: %v\n", err)
			os.Exit(1)
		}
	case "http", "https":
		if err := checkHTTP(args); err != nil {
			log("ERROR", "HTTP health check failed: %v\n", err)
			os.Exit(1)
		}
	default:
		log("ERROR", "Unsupported URL protocol %q; use file, http, https, or tcp\n", endpoint.Scheme)
		os.Exit(1)
	}

	log("INFO", "Success")
}
