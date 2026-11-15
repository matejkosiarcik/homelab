package main

import (
	"bytes"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"math/big"
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
		if _, writeErr := writer.Write([]byte(`{"healthy":true}`)); writeErr != nil {
			t.Errorf("writer.Write() error = %v", writeErr)
		}
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

func TestCheckHTTPLiteralBody(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		if _, err := writer.Write([]byte("healthy")); err != nil {
			t.Errorf("writer.Write() error = %v", err)
		}
	}))
	t.Cleanup(server.Close)

	body := "healthy"
	if err := checkHTTP(healthcheckArgs{URL: server.URL, Body: &body}); err != nil {
		t.Errorf("checkHTTP() error = %v", err)
	}
}

func TestCheckHTTPOnlyAllowsOneBodyValidation(t *testing.T) {
	body := "healthy"
	err := checkHTTP(healthcheckArgs{URL: "http://localhost", Body: &body, BodyRegex: "healthy"})
	if err == nil || !strings.Contains(err.Error(), "use only one of --body, --body-regex, and --body-json") {
		t.Errorf("checkHTTP() error = %v, want mutually-exclusive body-validation error", err)
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
		connection, acceptErr := listener.Accept()
		if acceptErr == nil {
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

func TestCheckHTTPMutualTLS(t *testing.T) {
	credentials := newMutualTLSCredentials(t)
	server := httptest.NewUnstartedServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))
	server.TLS = &tls.Config{
		Certificates: []tls.Certificate{credentials.serverCertificate},
		ClientAuth:   tls.RequireAndVerifyClientCert,
		ClientCAs:    credentials.clientCAs,
	}
	server.StartTLS()
	t.Cleanup(server.Close)

	err := checkHTTP(healthcheckArgs{
		URL:             server.URL,
		TLSServerCACert: credentials.caCertificatePath,
		TLSClientCert:   credentials.clientCertificatePath,
		TLSClientKey:    credentials.clientKeyPath,
		Status:          "204",
	})
	if err != nil {
		t.Errorf("checkHTTP() error = %v", err)
	}
}

func TestCheckTCPMutualTLS(t *testing.T) {
	credentials := newMutualTLSCredentials(t)
	listener, err := tls.Listen("tcp", "127.0.0.1:0", &tls.Config{
		Certificates: []tls.Certificate{credentials.serverCertificate},
		ClientAuth:   tls.RequireAndVerifyClientCert,
		ClientCAs:    credentials.clientCAs,
	})
	if err != nil {
		t.Fatalf("tls.Listen() error = %v", err)
	}
	t.Cleanup(func() { _ = listener.Close() })

	accepted := make(chan error, 1)
	go func() {
		connection, acceptErr := listener.Accept()
		if acceptErr != nil {
			accepted <- acceptErr
			return
		}
		defer func() { _ = connection.Close() }()

		accepted <- connection.(*tls.Conn).Handshake()
	}()

	err = checkTCP(healthcheckArgs{
		URL:             "tcp://" + listener.Addr().String(),
		TLSServerCACert: credentials.caCertificatePath,
		TLSClientCert:   credentials.clientCertificatePath,
		TLSClientKey:    credentials.clientKeyPath,
	})
	if err != nil {
		t.Errorf("checkTCP() error = %v", err)
	}

	select {
	case acceptErr := <-accepted:
		if acceptErr != nil {
			t.Errorf("mutual TLS handshake error = %v", acceptErr)
		}
	case <-time.After(time.Second):
		t.Error("TCP listener did not accept the mutual TLS health check connection")
	}
}

func TestTLSClientConfigRequiresCertificateAndKey(t *testing.T) {
	for _, args := range []healthcheckArgs{
		{TLSClientCert: "cert.pem"},
		{TLSClientKey: "key.pem"},
	} {
		if _, err := tlsClientConfig(args); err == nil || !strings.Contains(err.Error(), "both --tls-client-cert and --tls-client-key") {
			t.Errorf("tlsClientConfig(%+v) error = %v, want incomplete client-certificate error", args, err)
		}
	}
}

type mutualTLSCredentials struct {
	caCertificatePath     string
	clientCertificatePath string
	clientKeyPath         string
	clientCAs             *x509.CertPool
	serverCertificate     tls.Certificate
}

func newMutualTLSCredentials(t *testing.T) mutualTLSCredentials {
	t.Helper()

	certificateAuthorityKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("ecdsa.GenerateKey() error = %v", err)
	}
	now := time.Now()
	certificateAuthorityTemplate := &x509.Certificate{
		SerialNumber:          big.NewInt(1),
		Subject:               pkix.Name{CommonName: "healthcheck test CA"},
		NotBefore:             now.Add(-time.Hour),
		NotAfter:              now.Add(time.Hour),
		IsCA:                  true,
		BasicConstraintsValid: true,
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
	}
	certificateAuthorityDER, err := x509.CreateCertificate(rand.Reader, certificateAuthorityTemplate, certificateAuthorityTemplate, &certificateAuthorityKey.PublicKey, certificateAuthorityKey)
	if err != nil {
		t.Fatalf("x509.CreateCertificate() for CA error = %v", err)
	}
	certificateAuthority, err := x509.ParseCertificate(certificateAuthorityDER)
	if err != nil {
		t.Fatalf("x509.ParseCertificate() for CA error = %v", err)
	}
	certificateAuthorityPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certificateAuthorityDER})

	directory := t.TempDir()
	caCertificatePath := filepath.Join(directory, "ca.pem")
	if err := os.WriteFile(caCertificatePath, certificateAuthorityPEM, 0o600); err != nil {
		t.Fatalf("os.WriteFile() for CA error = %v", err)
	}

	serverCertificatePEM, serverKeyPEM := newSignedCertificate(t, certificateAuthority, certificateAuthorityKey, 2, []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth}, []string{"localhost"}, []net.IP{net.ParseIP("127.0.0.1")})
	serverCertificate, err := tls.X509KeyPair(serverCertificatePEM, serverKeyPEM)
	if err != nil {
		t.Fatalf("tls.X509KeyPair() for server error = %v", err)
	}

	clientCertificatePEM, clientKeyPEM := newSignedCertificate(t, certificateAuthority, certificateAuthorityKey, 3, []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth}, nil, nil)
	clientCertificatePath := filepath.Join(directory, "cert.pem")
	clientKeyPath := filepath.Join(directory, "key.pem")
	if err := os.WriteFile(clientCertificatePath, clientCertificatePEM, 0o600); err != nil {
		t.Fatalf("os.WriteFile() for client certificate error = %v", err)
	}
	if err := os.WriteFile(clientKeyPath, clientKeyPEM, 0o600); err != nil {
		t.Fatalf("os.WriteFile() for client key error = %v", err)
	}

	clientCAs := x509.NewCertPool()
	if !clientCAs.AppendCertsFromPEM(certificateAuthorityPEM) {
		t.Fatal("client CA pool did not accept the test CA certificate")
	}

	return mutualTLSCredentials{
		caCertificatePath:     caCertificatePath,
		clientCertificatePath: clientCertificatePath,
		clientKeyPath:         clientKeyPath,
		clientCAs:             clientCAs,
		serverCertificate:     serverCertificate,
	}
}

func newSignedCertificate(t *testing.T, certificateAuthority *x509.Certificate, certificateAuthorityKey *ecdsa.PrivateKey, serialNumber int64, usages []x509.ExtKeyUsage, dnsNames []string, ipAddresses []net.IP) ([]byte, []byte) {
	t.Helper()

	privateKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("ecdsa.GenerateKey() error = %v", err)
	}
	certificateTemplate := &x509.Certificate{
		SerialNumber: big.NewInt(serialNumber),
		Subject:      pkix.Name{CommonName: "healthcheck test certificate"},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature | x509.KeyUsageKeyEncipherment,
		ExtKeyUsage:  usages,
		DNSNames:     dnsNames,
		IPAddresses:  ipAddresses,
	}
	certificateDER, err := x509.CreateCertificate(rand.Reader, certificateTemplate, certificateAuthority, &privateKey.PublicKey, certificateAuthorityKey)
	if err != nil {
		t.Fatalf("x509.CreateCertificate() error = %v", err)
	}
	privateKeyDER, err := x509.MarshalPKCS8PrivateKey(privateKey)
	if err != nil {
		t.Fatalf("x509.MarshalPKCS8PrivateKey() error = %v", err)
	}

	return pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certificateDER}), pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: privateKeyDER})
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
	if closeErr := stderrFile.Close(); closeErr != nil {
		t.Fatalf("stderrFile.Close() error = %v", closeErr)
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
