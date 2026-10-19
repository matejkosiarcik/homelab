package main

import (
	"bytes"
	"regexp"
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
