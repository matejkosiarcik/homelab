package main

import (
	"bytes"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

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
