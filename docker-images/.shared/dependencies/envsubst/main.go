package main

import (
	"fmt"
	"os"

	"github.com/a8m/envsubst"
)

func main() {
	// Placeholder while the executable is being implemented.
	if _, err := envsubst.String(""); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to expand environment variables: %v\n", err)
		os.Exit(1)
	}
	fmt.Fprintln(os.Stderr, "This script is just a placeholder.")
	os.Exit(1)
}
