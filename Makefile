# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

DOCKER_APPS := $(shell find 'servers' -type f -name 'docker-compose.yml' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)
DOCKER_IMAGES := $(shell find 'docker-images' -type f -name 'Dockerfile' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)
NPM_COMPONENTS_FOR_BUILD := $(shell find 'docker-images' -type f -name 'package.json' -not -path '*/app-data/*' -not -path '*/gitman-repositories/*' -not -path '*/node_modules/*' -not -path '*/venv/*' -exec dirname {} \; | base64)
NPM_COMPONENTS_ALL := $(shell find '.' -type f -name 'package.json' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)
DOCKER_ARCHS := $(shell printf 'amd64 arm64/v8 ' | tr ' ' '\n' | base64)
PYTHON_COMPONENTS := $(shell find '.' -type f -name 'requirements.txt' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build docker-build docker-build-multiarch

.PHONY: bootstrap
bootstrap:
	printf '%s' "$(NPM_COMPONENTS_ALL)" | tr -d ' ' | base64 -d | while read -r component; do \
		npm ci --prefix "$(PROJECT_DIR)/$$component" --no-progress --no-audit --no-fund --loglevel=error && \
	true; done

	printf '%s' "$(PYTHON_COMPONENTS)" | tr -d ' ' | base64 -d | while read -r component; do \
		cd "$(PROJECT_DIR)/$$component" && \
		python3 -m venv venv && \
		PATH="$(PROJECT_DIR)/$$component/venv/bin:$$PATH" \
		PIP_DISABLE_PIP_VERSION_CHECK=1 \
			python3 -m pip install --requirement requirements.txt --quiet --upgrade && \
	true; done

	PATH="$(PROJECT_DIR)/icons/venv/bin:$$PATH" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		gitman install --root icons
	# --quiet --force

	printf '\n\n'

.PHONY: build
build:
	printf '%s' "$(NPM_COMPONENTS_FOR_BUILD)" | tr -d ' ' | base64 -d | while read -r component; do \
		printf 'Building %s\n' "$$component" && \
		npm run build --prefix "$(PROJECT_DIR)/$$component" && \
		printf '\n\n' && \
	true; done

.PHONY: docker-build
docker-build:
	printf '%s' "$(DOCKER_IMAGES)" | tr -d ' ' | base64 -d | while read -r component; do \
		printf 'Building %s\n' "$$component" && \
		docker build "$(PROJECT_DIR)/docker-images" --file "$(PROJECT_DIR)/$$component/Dockerfile" --tag "$$(printf '%s\n' "$$component" | tr '/' '-' | tr -d '.'):homelab" && \
		printf '\n\n' && \
	true; done

	# Disabled (it's complicated)
	# printf '%s' "$(DOCKER_APPS)" | tr -d ' ' | base64 -d | while read -r app; do \
	# 	printf 'Building %s\n' "$$app" && \
	# 	docker compose --project-directory "$(PROJECT_DIR)/$$app" build --with-dependencies && \
	# 	printf '\n\n' && \
	# true; done

.PHONY: docker-build-multiarch
docker-build-multiarch:
	printf '%s' "$(DOCKER_ARCHS)" | tr -d ' ' | base64 -d | while read -r arch; do \
		printf '%s' "$(DOCKER_IMAGES)" | tr -d ' ' | base64 -d | while read -r component; do \
			printf 'Building %s for linux/%s:\n' "$$component" "$$arch" && \
			docker build "$(PROJECT_DIR)/docker-images" --file "$(PROJECT_DIR)/$$component/Dockerfile" --platform "linux/$$arch" --tag "$$(printf '%s\n' "$$component" | tr '/' '-' | tr -d '.'):homelab-$$(printf '%s\n' "$$arch" | tr '/' '-')" && \
			printf '\n\n' && \
		true; done && \
	true; done

.PHONY: dryrun
dryrun:
	printf '%s' "$(DOCKER_APPS)" | tr -d ' ' | base64 -d | while read -r app; do \
		docker compose --project-directory "$(PROJECT_DIR)/$$app" --dry-run up --force-recreate --always-recreate-deps --remove-orphans --build && \
		printf '\n\n' && \
	true; done

.PHONY: clean
clean:
	find "$(PROJECT_DIR)" -type d \( \
		-name ".mypy_cache" -or \
		-name "dist" -or \
		-name "gitman-repositories" -or \
		-name "node_modules" -or \
		-name "python-vendor" -or \
		-name "venv" \
	\) -prune -exec rm -rf {} \;
