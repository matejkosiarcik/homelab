# SOPS Secrets

Commands to work with SOPS:

```sh
cd "$(git rev-parse --show-toplevel)/secrets"
export SOPS_AGE_KEY_FILE="$PWD/age-key.txt" # Note: Only necessary for decryption
sops --decrypt --config './.sops.yml' './secrets.enc.yml' >'./secrets.raw.yml'
sops --encrypt --config './.sops.yml' './secrets.raw.yml' >'./secrets.enc.yml'
```
