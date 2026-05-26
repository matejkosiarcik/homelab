use clap::Parser;
use std::time::Duration;

#[derive(Parser)]
#[command(author, version, about = "Simple program to run a healthcheck against an URL")]
struct Args {
    /// URL to request
    #[arg(long)]
    url: String,

    /// HTTP method to use (GET, HEAD, POST, ...)
    #[arg(long, default_value_t = String::from("GET"))]
    method: String,
}

fn main() {
    let args = Args::parse();

    let method = match args.method.parse::<reqwest::Method>() {
        Ok(m) => m,
        Err(_) => {
            eprintln!("Invalid HTTP method: {}", args.method);
            std::process::exit(1);
        }
    };

    let client = match reqwest::blocking::Client::builder()
        .timeout(Duration::from_secs(2))
        .build()
    {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Failed to build HTTP client: {}", e);
            std::process::exit(1);
        }
    };

    match client.request(method, &args.url).send() {
        Ok(resp) => {
            if resp.status().is_success() {
                std::process::exit(0);
            } else {
                eprintln!("Request returned non-success status: {}", resp.status());
                std::process::exit(1);
            }
        }
        Err(err) => {
            eprintln!("Request error: {}", err);
            std::process::exit(1);
        }
    }
}
