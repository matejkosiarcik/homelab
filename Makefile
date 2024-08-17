# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

DOCKER_APPS := $(shell printf 'odroid-h3-1/docker-apps/healthchecks odroid-h3-1/docker-apps/homer odroid-h3-1/docker-apps/omada-controller odroid-h3-1/docker-apps/smtp4dev odroid-h3-1/docker-apps/unifi-controller odroid-h3-1/docker-apps/uptime-kuma raspberry-pi-3b-1/docker-apps/pihole-main raspberry-pi-4b-1/docker-apps/pihole-main raspberry-pi-zero-2w-1/docker-apps/lamp-controller raspberry-pi-zero-2w-2/docker-apps/lamp-controller' | sed 's~ ~\n~g' | sed -E 's~^~machines/~')
DOCKER_COMPONENTS := $(shell printf 'docker-images/custom/certificate-manager docker-images/custom/http-proxy docker-images/custom/lamp-hardware-controller docker-images/custom/lamp-network-server docker-images/custom/postgres-backup docker-images/custom/socket-proxy docker-images/custom/web-backup docker-images/database/postgres docker-images/external/healthchecks docker-images/external/homer docker-images/external/omada-controller docker-images/external/pihole docker-images/external/smtp4dev docker-images/external/unifi-controller docker-images/external/uptime-kuma')
NPM_COMPONENTS := $(shell printf 'docker-images/custom/lamp-network-server docker-images/custom/web-backup')
DOCKER_ARCHS := $(shell printf 'amd64 arm64/v8')
# DOCKER_ARCHS := $(shell printf '386 amd64 arm/v5 arm/v7 arm64/v8 ppc64le')

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build docker-build docker-build-multiarch

.PHONY: bootstrap
bootstrap:
	npm ci --prefix "$(PROJECT_DIR)/icons" --no-progress --no-audit --no-fund --loglevel=error
	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		npm ci --prefix "$(PROJECT_DIR)/$$component" --no-progress --no-audit --no-fund --loglevel=error && \
	true; done

	python3 -m venv icons/venv
	PATH="$(PROJECT_DIR)/icons/venv/bin:$$PATH" \
	PYTHONPATH="$(PROJECT_DIR)/icons/python-vendor" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		python3 -m pip install --requirement icons/requirements.txt --target icons/python-vendor --quiet --upgrade

	PATH="$(PROJECT_DIR)/venv/bin:$(PROJECT_DIR)/icons/python-vendor/bin:$$PATH" \
	PYTHONPATH="$(PROJECT_DIR)/icons/python-vendor" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		gitman install --quiet --force --root icons

	python3 -m venv ansible/venv
	PATH="$(PROJECT_DIR)/ansible/venv/bin:$$PATH" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		python3 -m pip install --requirement ansible/requirements.txt --quiet --upgrade

.PHONY: build
build:
	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		npm run build --prefix "$(PROJECT_DIR)/$$component" && \
	true; done

.PHONY: docker-build
docker-build:
	printf '%s\n' "$(DOCKER_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		docker build docker-images/ --file "$(PROJECT_DIR)/$$component/Dockerfile" --tag "$$(printf '%s' "$$component" | tr '/' '-' | tr -d '.'):homelab" && \
	true; done

	printf '%s\n' "$(DOCKER_APPS)" | tr ' ' '\n' | while read -r app; do \
		docker compose --project-directory "$(PROJECT_DIR)/$$app" build --with-dependencies --pull && \
	true; done

.PHONY: docker-build-multiarch
docker-build-multiarch:
	set -e && \
	printf '%s\n' "$(DOCKER_ARCHS)" | tr ' ' '\n' | while read -r arch; do \
		printf '%s\n' "$(DOCKER_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
			printf 'Building linux/%s %s:\n' "$$arch" "$$component" && \
			docker build docker-images/ --file "$(PROJECT_DIR)/$$component/Dockerfile" --platform "linux/$$arch" --tag "$$(printf '%s' "$$component" | tr '/' '-' | tr -d '.'):homelab-$$(printf '%s' "$$arch" | tr '/' '-')" && \
		true; done && \
	true; done

.PHONY: dryrun
dryrun:
	printf '%s\n' "$(DOCKER_APPS)" | tr ' ' '\n' | while read -r app; do \
		docker compose --project-directory "$(PROJECT_DIR)/$$app" --dry-run up --force-recreate --always-recreate-deps --remove-orphans --build && \
	true; done

.PHONY: clean
clean:
	rm -rf \
		"$(PROJECT_DIR)/.mypy_cache" \
		"$(PROJECT_DIR)/ansible/python-vendor" \
		"$(PROJECT_DIR)/ansible/venv" \
		"$(PROJECT_DIR)/homelab" \
		"$(PROJECT_DIR)/homelab-deployment" \
		"$(PROJECT_DIR)/icons/gitman" \
		"$(PROJECT_DIR)/icons/node_modules" \
		"$(PROJECT_DIR)/icons/python-vendor" \
		"$(PROJECT_DIR)/icons/venv" \
		"$(PROJECT_DIR)/python-vendor" \
		"$(PROJECT_DIR)/venv"

	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		rm -rf "$(PROJECT_DIR)/$$component/dist" "$(PROJECT_DIR)/$$component/node_modules" && \
	true; done
