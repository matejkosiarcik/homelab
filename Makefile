# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

SERVICES := $(shell printf 'odroid-h3/healthchecks odroid-h3/homer odroid-h3/omada-controller odroid-h3/smtp4dev odroid-h3/unifi-controller odroid-h3/uptime-kuma raspberrypi-3b/pi-hole' | sed 's~ ~\n~g' | sed -E 's~^~machines/~')
DOCKER_COMPONENTS := $(shell printf '.shared/socat .shared/proxy .shared/ui-backup machines/odroid-h3/healthchecks/db-backup' | sed 's~ ~\n~g')
NPM_COMPONENTS := $(shell printf '.shared/ui-backup' | sed 's~ ~\n~g')
DOCKER_ARCHS := $(shell printf 'amd64 arm64/v8')

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build

.PHONY: bootstrap
bootstrap:
	npm ci --prefix "$(PROJECT_DIR)/icons"
	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		npm ci --prefix "$(PROJECT_DIR)/$$component" && \
	true; done

	python3 -m venv venv
	PATH="$(PROJECT_DIR)/venv/bin:$$PATH" \
	PYTHONPATH="$(PROJECT_DIR)/icons/python" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		python3 -m pip install --requirement icons/requirements.txt --target icons/python --quiet --upgrade

	python3 -m venv venv
	PATH="$(PROJECT_DIR)/venv/bin:$(PROJECT_DIR)/icons/python/bin:$$PATH" \
	PYTHONPATH="$(PROJECT_DIR)/icons/python" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		gitman install --quiet --force --root icons

.PHONY: build
build:
	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		npm run build --prefix "$(PROJECT_DIR)/$$component" && \
	true; done

.PHONY: docker-build
docker-build:
	printf '%s\n' "$(DOCKER_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		docker build "$(PROJECT_DIR)/$$component" --tag "$$(printf '%s' "$$component" | tr '/' '-'):homelab" && \
	true; done

	printf '%s\n' "$(SERVICES)" | tr ' ' '\n' | while read -r service; do \
		docker compose --project-directory "$(PROJECT_DIR)/$$service" build --with-dependencies --pull && \
	true; done

.PHONY: docker-multibuild
docker-multibuild:
	printf '%s\n' "$(DOCKER_ARCHS)" | tr ' ' '\n' | while read -r arch; do \
		printf 'Building for linux/%s:\n' "$$arch" && \
		printf '%s\n' "$(DOCKER_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
			docker build "$(PROJECT_DIR)/$$component" --platform "linux/$$arch" --tag "$$(printf '%s' "$$component" | tr '/' '-'):homelab-$$(printf '%s' "$$arch" | tr '/' '-')" && \
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
		"$(PROJECT_DIR)/homelab" \
		"$(PROJECT_DIR)/icons/gitman" \
		"$(PROJECT_DIR)/icons/node_modules" \
		"$(PROJECT_DIR)/icons/venv" \
		"$(PROJECT_DIR)/venv"

	printf '%s\n' "$(NPM_COMPONENTS)" | tr ' ' '\n' | while read -r component; do \
		rm -rf "$(PROJECT_DIR)/$$component/dist" "$(PROJECT_DIR)/$$component/node_modules" && \
	true; done
