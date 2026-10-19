package main

import (
	"strings"
	"testing"

	"github.com/itchyny/gojq"
)

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
