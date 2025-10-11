# Ansible

> This directory contains Ansible playbooks for automating setup and maintenance of my servers in my homelab.

Before launching Ansible, make sure you have dependencies installed:

```sh
make clean bootstrap # In repository root
. ./venv/bin/activate # In this directory
```

Then you can launch a playbook with:

```sh
ansible-playbook playbooks/<playbook>.yml
```
