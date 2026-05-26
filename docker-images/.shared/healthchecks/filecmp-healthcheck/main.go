package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/alexflint/go-arg"
)

func main() {
	// Parse arguments
	var args struct {
		FilePath        string `arg:"--file,required" help:"File path"`
		ExpectedContent string `arg:"--content,required" help:"Expected file content"`
	}
	arg.MustParse(&args)

	// Read file
	fileBytes, err := os.ReadFile(args.FilePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading file %s: %v\n", args.FilePath, err)
		os.Exit(1)
	}

	// Compare file content
	fileContent := strings.TrimSpace(string(fileBytes))
	if fileContent != args.ExpectedContent {
		fmt.Fprintf(os.Stderr, "File content mismatch: got %q, want %q\n", fileContent, args.ExpectedContent)
		os.Exit(1)
	}

	os.Exit(0)
}
