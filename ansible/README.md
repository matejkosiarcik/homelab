# Ansible

> This directory contains Ansible playbooks for automating setup and maintenance of my servers in my homelab.

Before launching Ansible, make sure you have dependencies installed:

```sh
cd "$(git rev-parse --show-toplevel)" # Go to repository root
make clean bootstrap                  # Install dependencies
cd ./ansible                          # Go here
. ./venv/bin/activate                 # Activate Python virtualenv
```

Then you can launch a playbook with:

```sh
# Run playbook on all servers:
ansible-playbook ./playbooks/<playbook>.yml

# Or run playbook only on specified servers
ansible-playbook --limit <server> ./playbooks/setup-server.yml
```
