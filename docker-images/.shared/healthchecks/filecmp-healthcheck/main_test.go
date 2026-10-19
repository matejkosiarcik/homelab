package main

import (
	"regexp"
	"testing"
)

func TestFormatLogMessage(t *testing.T) {
	message := formatLogMessage("first line\nsecond line\n")

	const prefixPattern = `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z \[healthcheck\]: `
	expectedPattern := "^" + prefixPattern + "first line\\n" + prefixPattern + "second line\\n$"
	if matched, err := regexp.MatchString(expectedPattern, message); err != nil || !matched {
		t.Errorf("formatLogMessage() = %q, want ISO 8601 timestamps and healthcheck prefixes", message)
	}
}
