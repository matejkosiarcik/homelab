# CHANGELOG

This is just a public diary, where I keep a list of things I did on my homelab.

## 2024-12-30

Add glances

## 2024-12-01

Deployed new version of unbound (running on host OS directly).
I configured unbound running on host OS directly.
This is in contrast with all of my other services, which are running in docker.
But this was necessary to achieve high-availability and solve (almost) all bootstrapping problems.
