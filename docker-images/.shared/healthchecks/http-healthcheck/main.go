package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
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
	"sync"
	"time"

	"github.com/alexflint/go-arg"
	"github.com/itchyny/gojq"
)

var healthcheckLogFile = "/homelab/logs/healthcheck/healthcheck.log"

const checkTimeout = 2 * time.Second

type healthcheckArgs struct {
	URL                  string  `json:"url"`
	Method               string  `json:"method"`
	Body                 *string `json:"body"`
	BodyRegex            string  `json:"bodyRegex"`
	BodyJSON             string  `json:"bodyJSON"`
	Status               string  `json:"status"`
	Insecure             bool    `json:"insecure"`
	TLSServerCACert      string  `json:"tlsServerCACert"`
	TLSClientCert        string  `json:"tlsClientCert"`
	TLSClientKey         string  `json:"tlsClientKey"`
	BasicAuthUsername    string  `json:"basicAuthUsername"`
	BasicAuthPassword    string  `json:"basicAuthPassword"`
	BasicAuthUsernameEnv string  `json:"basicAuthUsernameEnv"`
	BasicAuthPasswordEnv string  `json:"basicAuthPasswordEnv"`
}

type commandArgs struct {
	Endpoints []healthcheckArgs `arg:"--endpoint,separate,required" help:"Endpoint as a JSON object; repeat for multiple checks"`
}

func (commandArgs) Epilogue() string {
	return `Endpoint JSON fields:
  url                    Required file, http, https, or tcp URL
  method                 HTTP method (default: GET)
  body                   Exact response or file body
  bodyRegex              Regular expression for the response or file body
  bodyJSON               jq query that must return a truthy result
  status                 HTTP status codes and ranges, e.g. "200,400-404" (default: "200-299")
  insecure               Skip TLS certificate verification (default: false)
  tlsServerCACert        PEM server CA certificate path
  tlsClientCert          PEM client certificate path
  tlsClientKey           PEM client private key path
  basicAuthUsername      HTTP Basic Auth username
  basicAuthPassword      HTTP Basic Auth password
  basicAuthUsernameEnv   Environment variable containing the username
  basicAuthPasswordEnv   Environment variable containing the password

Use at most one of body, bodyRegex, and bodyJSON per endpoint.`
}

func (args *healthcheckArgs) UnmarshalText(data []byte) error {
	if !bytes.HasPrefix(bytes.TrimSpace(data), []byte("{")) {
		return errors.New("endpoint must be a JSON object")
	}
	// Decode into a separate value so that invalid input cannot leave partial settings.
	type endpointJSON healthcheckArgs
	var endpoint endpointJSON
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&endpoint); err != nil {
		return fmt.Errorf("invalid endpoint JSON: %w", err)
	}
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		return errors.New("endpoint must contain exactly one JSON object")
	}
	if endpoint.URL == "" {
		return errors.New("endpoint url is required")
	}
	if endpoint.Method == "" {
		endpoint.Method = http.MethodGet
	}
	*args = healthcheckArgs(endpoint)
	return nil
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

	tlsConfig, err := tlsClientConfig(args)
	if err != nil {
		return fmt.Errorf("configuring TLS: %w", err)
	}

	var connection net.Conn
	if tlsConfig == nil {
		connection, err = net.DialTimeout("tcp", address, checkTimeout)
	} else {
		contextWithTimeout, cancel := context.WithTimeout(context.Background(), checkTimeout)
		defer cancel()

		connection, err = (&tls.Dialer{
			NetDialer: &net.Dialer{Timeout: checkTimeout},
			Config:    tlsConfig,
		}).DialContext(contextWithTimeout, "tcp", address)
	}
	if err != nil {
		return fmt.Errorf("connecting to TCP address %q: %w", address, err)
	}

	return connection.Close()
}

func tlsClientConfig(args healthcheckArgs) (*tls.Config, error) {
	if (args.TLSClientCert == "") != (args.TLSClientKey == "") {
		return nil, errors.New("mutual TLS requires both tlsClientCert and tlsClientKey")
	}

	if args.TLSServerCACert == "" && args.TLSClientCert == "" && !args.Insecure {
		return nil, nil
	}

	config := &tls.Config{}
	if args.Insecure {
		config.InsecureSkipVerify = true // #nosec G402 -- explicit health-check opt-in for an internal endpoint
	}

	if args.TLSServerCACert != "" {
		certificateAuthorityPEM, err := os.ReadFile(args.TLSServerCACert)
		if err != nil {
			return nil, fmt.Errorf("reading TLS server CA certificate %q: %w", args.TLSServerCACert, err)
		}

		certificateAuthorities, err := x509.SystemCertPool()
		if err != nil || certificateAuthorities == nil {
			certificateAuthorities = x509.NewCertPool()
		}
		if !certificateAuthorities.AppendCertsFromPEM(certificateAuthorityPEM) {
			return nil, fmt.Errorf("parsing TLS server CA certificate %q: no PEM certificates found", args.TLSServerCACert)
		}
		config.RootCAs = certificateAuthorities
	}

	if args.TLSClientCert != "" {
		certificate, err := tls.LoadX509KeyPair(args.TLSClientCert, args.TLSClientKey)
		if err != nil {
			return nil, fmt.Errorf("loading TLS client certificate and key: %w", err)
		}
		config.Certificates = []tls.Certificate{certificate}
	}

	return config, nil
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

	bodyValidator, err := newBodyValidator(args)
	if err != nil {
		return err
	}
	if !bodyValidator.enabled() {
		return nil
	}

	body, err := os.ReadFile(endpoint.Path)
	if err != nil {
		return fmt.Errorf("reading file %q: %w", endpoint.Path, err)
	}
	if err := bodyValidator.validate(body); err != nil {
		return fmt.Errorf("file body validation failed: %w", err)
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

type bodyValidator struct {
	literal *string
	regex   *regexp.Regexp
	json    *gojq.Query
}

func newBodyValidator(args healthcheckArgs) (bodyValidator, error) {
	validator := bodyValidator{literal: args.Body}
	bodyValidationCount := 0
	if validator.literal != nil {
		bodyValidationCount++
	}
	if args.BodyRegex != "" {
		bodyValidationCount++
	}
	if args.BodyJSON != "" {
		bodyValidationCount++
	}
	if bodyValidationCount > 1 {
		return bodyValidator{}, errors.New("use only one of body, bodyRegex, and bodyJSON")
	}

	if args.BodyRegex != "" {
		regex, err := regexp.Compile(args.BodyRegex)
		if err != nil {
			return bodyValidator{}, fmt.Errorf("invalid regex for bodyRegex: %w", err)
		}
		validator.regex = regex
	}
	if args.BodyJSON != "" {
		query, err := gojq.Parse(args.BodyJSON)
		if err != nil {
			return bodyValidator{}, fmt.Errorf("invalid jq query for bodyJSON: %w", err)
		}
		validator.json = query
	}

	return validator, nil
}

func (validator bodyValidator) enabled() bool {
	return validator.literal != nil || validator.regex != nil || validator.json != nil
}

func (validator bodyValidator) validate(body []byte) error {
	if validator.literal != nil && !bytes.Equal(body, []byte(*validator.literal)) {
		return fmt.Errorf("does not match literal: %s", body)
	}
	if validator.regex != nil && !validator.regex.Match(body) {
		return fmt.Errorf("does not match regex: %s", body)
	}
	if validator.json != nil {
		if err := validateJSONBody(validator.json, body); err != nil {
			return fmt.Errorf("does not match JSON query: %w", err)
		}
	}

	return nil
}

// nolint:gocyclo
func checkHTTP(args healthcheckArgs) error {
	if args.BasicAuthUsername != "" && args.BasicAuthUsernameEnv != "" {
		return errors.New("use only one of basicAuthUsername and basicAuthUsernameEnv")
	}
	if args.BasicAuthPassword != "" && args.BasicAuthPasswordEnv != "" {
		return errors.New("use only one of basicAuthPassword and basicAuthPasswordEnv")
	}
	bodyValidator, err := newBodyValidator(args)
	if err != nil {
		return err
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
				return fmt.Errorf("invalid HTTP status range for status: %q", status)
			}

			start, err1 := strconv.Atoi(strings.TrimSpace(parts[0]))
			end, err2 := strconv.Atoi(strings.TrimSpace(parts[1]))

			if err1 != nil || err2 != nil || start < 100 || end > 599 || start > end {
				return fmt.Errorf("invalid HTTP status range for status: %q", status)
			}

			for code := start; code <= end; code++ {
				expectedStatuses = append(expectedStatuses, code)
			}
		} else {
			code, parseErr := strconv.Atoi(status)
			if parseErr != nil || code < 100 || code > 599 {
				return fmt.Errorf("invalid HTTP status code for status: %q", status)
			}

			expectedStatuses = append(expectedStatuses, code)
		}
	}

	tlsConfig, err := tlsClientConfig(args)
	if err != nil {
		return fmt.Errorf("configuring TLS: %w", err)
	}

	// Perform HTTP request
	transport := &http.Transport{TLSClientConfig: tlsConfig}
	defer transport.CloseIdleConnections()
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
	if bodyValidator.enabled() {
		// Read response body for validation.
		bodyBytes, err := io.ReadAll(response.Body)
		if err != nil {
			return fmt.Errorf("reading response body: %w", err)
		}

		if err := bodyValidator.validate(bodyBytes); err != nil {
			return fmt.Errorf("response body validation failed: %w", err)
		}
	}

	return nil
}

func checkEndpoint(args healthcheckArgs) error {
	endpoint, err := url.Parse(args.URL)
	if err != nil {
		return fmt.Errorf("parsing URL: %w", err)
	}

	switch strings.ToLower(endpoint.Scheme) {
	case "file":
		return checkFile(args)
	case "tcp":
		return checkTCP(args)
	case "http", "https":
		return checkHTTP(args)
	default:
		return fmt.Errorf("unsupported URL protocol %q; use file, http, https, or tcp", endpoint.Scheme)
	}
}

func checkEndpoints(endpoints []healthcheckArgs) []error {
	results := make([]error, len(endpoints))
	var checks sync.WaitGroup
	for i, endpoint := range endpoints {
		checks.Add(1)
		go func() {
			defer checks.Done()
			results[i] = checkEndpoint(endpoint)
		}()
	}
	checks.Wait()
	return results
}

func main() {
	var args commandArgs
	parser, parserErr := arg.NewParser(arg.Config{}, &args)
	if parserErr != nil {
		// nolint:errcheck
		_, _ = fmt.Fprintf(os.Stderr, "Error configuring healthcheck arguments: %v\n", parserErr)
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

	failed := false
	for i, err := range checkEndpoints(args.Endpoints) {
		if err != nil {
			log("ERROR", "Endpoint %d health check failed: %v\n", i+1, err)
			failed = true
		}
	}
	if failed {
		os.Exit(1)
	}

	log("INFO", "Success")
}
