package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/alexflint/go-arg"
)

const healthcheckLogFile = "/homelab/healthcheck/logs/healthcheck.log"

func touchLogFile() error {
	logFile, err := os.OpenFile(healthcheckLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("opening healthcheck log file %s: %w", healthcheckLogFile, err)
	}
	defer func() { _ = logFile.Close() }()

	return nil
}

func logError(format string, args ...any) {
	message := formatLogMessage(fmt.Sprintf(format, args...))
	fmt.Fprint(os.Stderr, message)

	logFile, err := os.OpenFile(healthcheckLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		fmt.Fprint(os.Stderr, formatLogMessage(fmt.Sprintf("Error opening healthcheck log file %s: %v", healthcheckLogFile, err)))
		return
	}
	defer func() { _ = logFile.Close() }()

	if _, err := fmt.Fprint(logFile, message); err != nil {
		fmt.Fprint(os.Stderr, formatLogMessage(fmt.Sprintf("Error writing healthcheck log file %s: %v", healthcheckLogFile, err)))
	}
}

func formatLogMessage(message string) string {
	prefix := fmt.Sprintf("%s [healthcheck]: ", time.Now().UTC().Format(time.RFC3339Nano))
	lines := strings.Split(strings.TrimSuffix(message, "\n"), "\n")

	return prefix + strings.Join(lines, "\n"+prefix) + "\n"
}

func main() {
	if err := touchLogFile(); err != nil {
		fmt.Fprint(os.Stderr, formatLogMessage(err.Error()))
		os.Exit(1)
	}

	// Parse arguments
	var args struct {
		FilePath        string `arg:"--file,required" help:"File path"`
		ExpectedContent string `arg:"--content,required" help:"Expected file content"`
	}
	if err := arg.Parse(&args); err != nil {
		logError("Error parsing healthcheck arguments: %v\n", err)
		os.Exit(1)
	}

	// Read file
	fileBytes, err := os.ReadFile(args.FilePath)
	if err != nil {
		logError("Error reading file %s: %v\n", args.FilePath, err)
		os.Exit(1)
	}

	// Compare file content
	fileContent := strings.TrimSpace(string(fileBytes))
	if fileContent != args.ExpectedContent {
		logError("File content mismatch: got %q, want %q\n", fileContent, args.ExpectedContent)
		os.Exit(1)
	}

	os.Exit(0)
}
