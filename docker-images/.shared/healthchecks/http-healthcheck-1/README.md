# check_url

Simple Rust CLI that requests a URL and exits with 0 on success, 1 on error.

Requirements
- Rust and Cargo (recommend Rust 1.60+)

Build

```
cd check_url
cargo build --release
```

Run

```
cargo run -- --url https://example.com
# or run the binary
./target/release/check_url --url https://example.com
```

Behavior
- If the HTTP request completes and returns a success HTTP status (2xx), the process exits 0.
- Otherwise the error or non-success status is printed to stderr and the process exits 1.
