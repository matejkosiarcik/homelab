package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/alexflint/go-arg"
)

var healthcheckLogFile = "/homelab/logs/healthcheck/healthcheck.log"

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

func main() {
	// Parse arguments
	var args struct {
		FilePath        string `arg:"--file,required" help:"File path"`
		ExpectedContent string `arg:"--content,required" help:"Expected file content"`
	}
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

	// Read file
	fileBytes, err := os.ReadFile(args.FilePath)
	if err != nil {
		log("ERROR", "Error reading file %s: %v\n", args.FilePath, err)
		os.Exit(1)
	}

	// Compare file content
	fileContent := strings.TrimSpace(string(fileBytes))
	if fileContent != args.ExpectedContent {
		log("ERROR", "File content mismatch: got %q, want %q\n", fileContent, args.ExpectedContent)
		os.Exit(1)
	}

	log("INFO", "Success")
	os.Exit(0)
}
