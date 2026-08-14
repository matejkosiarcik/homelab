# SOPS Secrets

Commands to work with SOPS:

```sh
cd "$(git rev-parse --show-toplevel)/secrets"

# Generate key (only once)
age-keygen -o './key.txt'

# Set encryption key
export SOPS_AGE_KEY_FILE="$(git rev-parse --show-toplevel)/secrets/key.txt"

# Decrypt file
sops --decrypt --config './.sops.yml' './secrets.enc.yml' >'./secrets.raw.yml'

# Encrypt file
sops --encrypt --config './.sops.yml' './secrets.raw.yml' >'./secrets.enc.yml'
```
