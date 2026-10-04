package main

import (
	"fmt"
	"os"

	"github.com/a8m/envsubst"
)

func main() {
	// Placeholder while the executable is being implemented.
	_, _ = envsubst.String("")
	fmt.Fprintln(os.Stderr, "This script is just a placeholder.")
	os.Exit(1)
}
