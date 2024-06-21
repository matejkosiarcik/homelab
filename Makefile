# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

SERVICES := $(shell printf 'odroid-h3-1/healthchecks odroid-h3-1/homer odroid-h3-1/omada-controller odroid-h3-1/smtp4dev odroid-h3-1/unifi-controller odroid-h3-1/uptime-kuma raspberry-pi-3b-1/pihole raspberry-pi-4b-1/pihole' | sed 's~ ~\n~g' | sed -E 's~^~machines/~')
DOCKER_COMPONENTS := $(shell printf 'components/database components/database-backup components/http-proxy components/lamps/hardware-controller components/lamps/network-server components/omada-controller components/pihole components/smtp4dev components/socket-proxy components/unifi-controller components/uptime-kuma components/webui-backup' | sed 's~ ~\n~g')
NPM_COMPONENTS := $(shell printf 'components/lamps/network-server components/webui-backup' | sed 's~ ~\n~g')
DOCKER_ARCHS := $(shell printf 'amd64 arm64/v8')

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build docker-build docker-multibuild

.PHONY: bootstrap
bootstrap:
	npm ci --prefix "$(PROJECT_DIR)/icons"
	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		npm ci --prefix "$(PROJECT_DIR)/$$component" && \
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
		docker build "$(PROJECT_DIR)/$$component" --tag "$$(printf '%s' "$$component" | tr '/' '-' | tr -d '.'):homelab" && \
	true; done

	printf '%s\n' "$(SERVICES)" | tr ' ' '\n' | while read -r service; do \
		docker compose --project-directory "$(PROJECT_DIR)/$$service" build --with-dependencies --pull && \
	true; done

.PHONY: docker-multibuild
docker-multibuild:
	printf '%s\n' "$(DOCKER_ARCHS)" | tr ' ' '\n' | while read -r arch; do \
		printf 'Building for linux/%s:\n' "$$arch" && \
		printf '%s\n' "$(DOCKER_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
			docker build "$(PROJECT_DIR)/$$component" --platform "linux/$$arch" --tag "$$(printf '%s' "$$component" | tr '/' '-' | tr -d '.'):homelab-$$(printf '%s' "$$arch" | tr '/' '-')" && \
		true; done && \
	true; done

.PHONY: dryrun
dryrun:
	printf '%s\n' "$(SERVICES)" | tr ' ' '\n' | while read -r service; do \
		docker compose --project-directory "$(PROJECT_DIR)/$$service" --dry-run up --force-recreate --always-recreate-deps --remove-orphans --build && \
	true; done

.PHONY: clean
clean:
	rm -rf \
		"$(PROJECT_DIR)/.mypy_cache" \
		"$(PROJECT_DIR)/ansible/python-vendor" \
		"$(PROJECT_DIR)/ansible/venv" \
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
