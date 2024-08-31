# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

DOCKER_APPS := $(shell find 'servers' -type f -name 'docker-compose.yml' -exec dirname {} \; | base64)
DOCKER_IMAGES := $(shell find 'docker-images' -type f -name 'Dockerfile' -not -path '*/node_modules/*' -exec dirname {} \; | base64)
NPM_COMPONENTS_FOR_BUILD := $(shell find 'docker-images' -type f -name 'package.json' -not -path '*/node_modules/*' -exec dirname {} \; | base64)
NPM_COMPONENTS_ALL := $(shell find '.' -type f -name 'package.json' -not -path '*/node_modules/*' -exec dirname {} \; | base64)
DOCKER_ARCHS := $(shell printf 'amd64 arm64/v8 ' | tr ' ' '\n' | base64)

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build docker-build docker-build-multiarch

.PHONY: bootstrap
bootstrap:
	echo "Current npm directories:"
	find '.' -type f -name 'package.json' -not -path '*/node_modules/*' -exec dirname {} \;
	echo "Current npm directories2:"
	find '.' -type f -name 'package.json' -not -path '*/node_modules/*' -exec dirname {} \; | base64 | base64 -d
	echo "end."

	printf '%s' "$(NPM_COMPONENTS_ALL)" | base64 -d | while read -r component; do \
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

	printf '\n\n'

.PHONY: build
build:
	printf '%s\n' "$(NPM_COMPONENTS_FOR_BUILD)" | base64 -d | while read -r component; do \
		printf 'Building %s\n' "$$component" && \
		npm run build --prefix "$(PROJECT_DIR)/$$component" && \
		printf '\n\n' && \
	true; done

.PHONY: docker-build
docker-build:
	printf '%s\n' "$(DOCKER_IMAGES)" | base64 -d | while read -r component; do \
		printf 'Building %s\n' "$$component" && \
		docker build "$(PROJECT_DIR)/docker-images" --file "$(PROJECT_DIR)/$$component/Dockerfile" --tag "$$(printf '%s\n' "$$component" | tr '/' '-' | tr -d '.'):homelab" && \
		printf '\n\n' && \
	true; done

	printf '%s\n' "$(DOCKER_APPS)" | base64 -d | while read -r app; do \
		printf 'Building %s\n' "$$app" && \
		docker compose --project-directory "$(PROJECT_DIR)/$$app" build --with-dependencies && \
		printf '\n\n' && \
	true; done

.PHONY: docker-build-multiarch
docker-build-multiarch:
	printf '%s\n' "$(DOCKER_ARCHS)" | base64 -d | while read -r arch; do \
		printf '%s\n' "$(DOCKER_IMAGES)" | base64 -d | while read -r component; do \
			printf 'Building %s for linux/%s:\n' "$$component" "$$arch" && \
			docker build "$(PROJECT_DIR)/docker-images" --file "$(PROJECT_DIR)/$$component/Dockerfile" --platform "linux/$$arch" --tag "$$(printf '%s\n' "$$component" | tr '/' '-' | tr -d '.'):homelab-$$(printf '%s\n' "$$arch" | tr '/' '-')" && \
			printf '\n\n' && \
		true; done && \
	true; done

.PHONY: dryrun
dryrun:
	printf '%s\n' "$(DOCKER_APPS)" | base64 -d | while read -r app; do \
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
