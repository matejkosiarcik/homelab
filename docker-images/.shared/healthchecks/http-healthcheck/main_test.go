package main

import (
	"bytes"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/itchyny/gojq"
)

func TestCheckHTTP(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		username, password, ok := request.BasicAuth()
		if !ok || username != "healthcheck" || password != "password" {
			writer.WriteHeader(http.StatusUnauthorized)
			return
		}

		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"healthy":true}`))
	}))
	t.Cleanup(server.Close)

	err := checkHTTP(healthcheckArgs{
		URL:               server.URL,
		BasicAuthUsername: "healthcheck",
		BasicAuthPassword: "password",
		BodyJSON:          ".healthy == true",
	})
	if err != nil {
		t.Errorf("checkHTTP() error = %v", err)
	}
}

func TestCheckFile(t *testing.T) {
	filePath := filepath.Join(t.TempDir(), "status.txt")
	if err := os.WriteFile(filePath, []byte("ready"), 0o600); err != nil {
		t.Fatalf("os.WriteFile() error = %v", err)
	}

	fileURL := (&url.URL{Scheme: "file", Path: filePath}).String()
	if err := checkFile(healthcheckArgs{URL: fileURL}); err != nil {
		t.Errorf("checkFile() error = %v", err)
	}
}

func TestCheckTCP(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("net.Listen() error = %v", err)
	}
	t.Cleanup(func() { _ = listener.Close() })

	accepted := make(chan struct{})
	go func() {
		connection, err := listener.Accept()
		if err == nil {
			_ = connection.Close()
			close(accepted)
		}
	}()

	err = checkTCP(healthcheckArgs{URL: "tcp://" + listener.Addr().String()})
	if err != nil {
		t.Errorf("checkTCP() error = %v", err)
	}

	select {
	case <-accepted:
	case <-time.After(time.Second):
		t.Error("TCP listener did not accept the health check connection")
	}
}

func TestTCPAddress(t *testing.T) {
	tests := []struct {
		name     string
		endpoint string
		want     string
		wantErr  string
	}{
		{
			name:     "hostname",
			endpoint: "tcp://localhost:139",
			want:     "localhost:139",
		},
		{
			name:     "IPv6",
			endpoint: "tcp://[::1]:2375",
			want:     "[::1]:2375",
		},
		{
			name:     "missing port",
			endpoint: "tcp://localhost",
			wantErr:  "host and port",
		},
		{
			name:     "path is not supported",
			endpoint: "tcp://localhost:139/health",
			wantErr:  "only a host and port",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			endpoint, err := url.Parse(test.endpoint)
			if err != nil {
				t.Fatalf("url.Parse() error = %v", err)
			}

			address, err := tcpAddress(endpoint)
			if test.wantErr == "" {
				if err != nil {
					t.Fatalf("tcpAddress() error = %v", err)
				}
				if address != test.want {
					t.Errorf("tcpAddress() = %q, want %q", address, test.want)
				}
				return
			}

			if err == nil || !strings.Contains(err.Error(), test.wantErr) {
				t.Errorf("tcpAddress() error = %v, want error containing %q", err, test.wantErr)
			}
		})
	}
}

func TestFormatLogMessage(t *testing.T) {
	message := formatLogMessage("ERROR", "first %s\nsecond line %d\n", "line", 2)

	const prefixPattern = `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z \[healthcheck\]: `
	expectedPattern := "^" + prefixPattern + "\\[ERROR\\] first line\\n" + prefixPattern + "\\[ERROR\\] second line 2\\n$"
	if matched, err := regexp.MatchString(expectedPattern, message); err != nil || !matched {
		t.Errorf("formatLogMessage() = %q, want ISO 8601 timestamps and healthcheck prefixes", message)
	}
}

func TestPrintLogFormatsMessage(t *testing.T) {
	var output bytes.Buffer
	if err := printLog(&output, "WARNING", "healthcheck failed with status %d", 503); err != nil {
		t.Fatalf("printLog() error = %v", err)
	}

	const expectedPattern = `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z \[healthcheck\]: \[WARNING\] healthcheck failed with status 503\n$`
	if matched, err := regexp.MatchString(expectedPattern, output.String()); err != nil || !matched {
		t.Errorf("printLog() = %q, want a formatted healthcheck log entry", output.String())
	}
}

func TestLogWritesToStderrAndLogFile(t *testing.T) {
	logFilePath := filepath.Join(t.TempDir(), "healthcheck.log")
	stderrFile, err := os.CreateTemp(t.TempDir(), "stderr")
	if err != nil {
		t.Fatalf("os.CreateTemp() error = %v", err)
	}

	originalLogFile := healthcheckLogFile
	originalStderr := os.Stderr
	healthcheckLogFile = logFilePath
	os.Stderr = stderrFile
	t.Cleanup(func() {
		healthcheckLogFile = originalLogFile
		os.Stderr = originalStderr
		_ = stderrFile.Close()
	})

	log("INFO", "Success")
	if err := stderrFile.Close(); err != nil {
		t.Fatalf("stderrFile.Close() error = %v", err)
	}
	os.Stderr = originalStderr

	stderrOutput, err := os.ReadFile(stderrFile.Name())
	if err != nil {
		t.Fatalf("os.ReadFile(stderr) error = %v", err)
	}
	logOutput, err := os.ReadFile(logFilePath)
	if err != nil {
		t.Fatalf("os.ReadFile(log) error = %v", err)
	}

	for destination, output := range map[string]string{"stderr": string(stderrOutput), "log file": string(logOutput)} {
		if !strings.Contains(output, "[INFO] Success\n") {
			t.Errorf("%s = %q, want an INFO log entry", destination, output)
		}
	}
}

func TestValidateJSONBody(t *testing.T) {
	tests := []struct {
		name    string
		query   string
		body    string
		wantErr string
	}{
		{
			name:  "truthy result",
			query: ".status == \"ok\"",
			body:  `{"status":"ok"}`,
		},
		{
			name:    "false result",
			query:   ".status == \"ok\"",
			body:    `{"status":"unhealthy"}`,
			wantErr: "jq query result is false",
		},
		{
			name:    "null result",
			query:   ".missing",
			body:    `{"status":"ok"}`,
			wantErr: "jq query result is null",
		},
		{
			name:    "no result",
			query:   "empty",
			body:    `{"status":"ok"}`,
			wantErr: "jq query produced no results",
		},
		{
			name:    "invalid JSON",
			query:   ".status == \"ok\"",
			body:    `{"status":}`,
			wantErr: "invalid JSON",
		},
		{
			name:    "multiple JSON values",
			query:   ".status == \"ok\"",
			body:    `{"status":"ok"} {"status":"ok"}`,
			wantErr: "multiple JSON values",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			query, err := gojq.Parse(test.query)
			if err != nil {
				t.Fatalf("gojq.Parse() error = %v", err)
			}

			err = validateJSONBody(query, []byte(test.body))
			if test.wantErr == "" {
				if err != nil {
					t.Fatalf("validateJSONBody() error = %v", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), test.wantErr) {
				t.Errorf("validateJSONBody() error = %v, want error containing %q", err, test.wantErr)
			}
		})
	}
}
