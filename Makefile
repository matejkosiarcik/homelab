# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

# Define portable datetime format
define_log_function = log_timestamp() { date_supports_milliseconds="$$(date '+%3N')"; case "$${date_supports_milliseconds}" in [0-9][0-9][0-9]) milliseconds_format='%3N' ;; *) milliseconds_format='000' ;; esac; date "+%Y-%m-%dT%H:%M:%S.$${milliseconds_format}Z"; }; log() { log_level="$$1"; shift; log_timestamp="$$(log_timestamp)"; printf '%s\n' "$${*}" | while IFS= read -r log_message || [ -n "$${log_message}" ]; do printf '%s [%s]: %s\n' "$${log_timestamp}" "$$log_level" "$${log_message}"; done >&2; }

DOCKER_APPS := $(shell find 'servers' -type f -name 'Taskfile.yml' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)
DOCKER_IMAGES := $(shell find 'docker-images' -type f -name 'Dockerfile' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)
NPM_COMPONENTS_ALL := $(shell find '.' -type f -name 'package.json' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)
NPM_COMPONENTS_BUILD := $(shell find 'docker-images' -type f -name 'package.json' -not -path '*/app-data/*' -not -path '*/gitman-repositories/*' -not -path '*/node_modules/*' -not -path '*/venv/*' -exec dirname {} \; | base64)
NPM_COMPONENTS_POSTINSTALL := $(shell printf '%s\n' '/docs/diagrams/node_modules/puppeteer' '/docs/diagrams/node_modules/zopflipng-bin' '/icons/node_modules/zopflipng-bin' '/tests' | base64)
DOCKER_ARCHS := $(shell printf '%s\n' 'amd64' 'arm64/v8' | base64)
PYTHON_COMPONENTS := $(shell find '.' -type f -name 'requirements.txt' -not \( -path '*/app-data/*' -or -path '*/gitman-repositories/*' -or -path '*/node_modules/*' -or -path '*/venv/*' \) -exec dirname {} \; | base64)

# TODO: Remove explicit python version for ansible after ansible is compatible with python 3.15
ANSIBLE_PYTHON ?= $(shell command -v python3.14 2>/dev/null || command -v python3)

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build docker-build docker-build-multiarch
	$(define_log_function); log INFO 'All development tasks completed successfully'
	printf '\n'

.PHONY: bootstrap
bootstrap:
	# Check if there is an active virtualenv and abort
	$(define_log_function); \
	if [ -n "$${VIRTUAL_ENV+x}" ]; then \
		log ERROR 'There is an active python virtualenv. Run "deactivate" and try again.'; \
		exit 1; \
	fi

	$(define_log_function); log INFO 'Installing dependencies'

	#
	## NodeJS ##
	#

	printf '%s' "$(NPM_COMPONENTS_ALL)" | tr -d ' ' | base64 -d | while read -r component; do \
		npm ci --prefix "$(PROJECT_DIR)/$${component}" --no-audit --no-fund --no-progress --no-save --loglevel=error --prefer-offline <'/dev/null' && \
	true; done

	printf '%s' "$(NPM_COMPONENTS_POSTINSTALL)" | tr -d ' ' | base64 -d | while read -r component; do \
		npm run postinstall --prefix "$(PROJECT_DIR)/$${component}" --loglevel=error <'/dev/null' && \
	true; done

	#
	## Python ##
	#

	printf '%s' "$(PYTHON_COMPONENTS)" | tr -d ' ' | base64 -d | while read -r component; do \
		if [ "$${component}" = './ansible' ]; then python="$(ANSIBLE_PYTHON)"; else python='python3'; fi && \
		cd "$(PROJECT_DIR)/$${component}" && \
		if [ -e './venv' ]; then true; else "$${python}" -m venv './venv'; fi && \
		PATH="$(PROJECT_DIR)/$${component}/venv/bin:$${PATH}" \
		PIP_DISABLE_PIP_VERSION_CHECK='1' \
		PYTHONDONTWRITEBYTECODE='1' \
			python -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' <'/dev/null' && \
	true; done

	PATH="$(PROJECT_DIR)/icons/venv/bin:$${PATH}" \
	PIP_DISABLE_PIP_VERSION_CHECK='1' \
	PYTHONDONTWRITEBYTECODE='1' \
		gitman install --root icons <'/dev/null'
	# --quiet --force

	$(define_log_function); log INFO 'Dependencies installed successfully'
	printf '\n'

.PHONY: build
build:
	$(define_log_function); log INFO 'Building repository components'

	$(define_log_function); \
	printf '%s' "$(NPM_COMPONENTS_BUILD)" | tr -d ' ' | base64 -d | while read -r component; do \
		log INFO "Building $${component}" && \
		npm run build --prefix "$(PROJECT_DIR)/$${component}" <'/dev/null' && \
		printf '\n\n' && \
	true; done

	$(define_log_function); log INFO 'Build was successful'
	printf '\n'

.PHONY: docker-build
docker-build:
	$(define_log_function); log INFO 'Building Docker images'

	$(define_log_function); \
	printf '%s' "$(DOCKER_IMAGES)" | tr -d ' ' | base64 -d | while read -r component; do \
		log INFO "Building $${component}" && \
		docker build "$(PROJECT_DIR)" --file "$(PROJECT_DIR)/$${component}/Dockerfile" --tag "$$(printf '%s\n' "$${component}" | tr '/' '-' | tr -d '.'):homelab" <'/dev/null' && \
		printf '\n\n' && \
	true; done

	# Disabled - It's complicated
	# printf '%s' "$(DOCKER_APPS)" | tr -d ' ' | base64 -d | while read -r app; do \
	# 	printf 'Building %s\n' "$${app}" && \
	# 	docker compose --project-directory "$(PROJECT_DIR)/$${app}" build --with-dependencies <'/dev/null' && \
	# 	printf '\n\n' && \
	# true; done

	$(define_log_function); log INFO 'Docker images built successfully'
	printf '\n'

.PHONY: docker-build-multiarch
docker-build-multiarch:
	$(define_log_function); log INFO 'Building multi-architecture Docker images'

	$(define_log_function); \
	printf '%s' "$(DOCKER_ARCHS)" | tr -d ' ' | base64 -d | while read -r arch; do \
		printf '%s' "$(DOCKER_IMAGES)" | tr -d ' ' | base64 -d | while read -r component; do \
			log INFO "Building $${component} for linux/$${arch}" && \
			docker build "$(PROJECT_DIR)" --file "$(PROJECT_DIR)/$${component}/Dockerfile" --platform "linux/$${arch}" --tag "$$(printf '%s\n' "$${component}" | tr '/' '-' | tr -d '.'):homelab-$$(printf '%s\n' "$${arch}" | tr '/' '-')" <'/dev/null' && \
			printf '\n\n' && \
		true; done && \
	true; done

	$(define_log_function); log INFO 'Multi-architecture Docker images built successfully'
	printf '\n'

.PHONY: dryrun
dryrun:
	$(define_log_function); log INFO 'Running Docker Compose dry runs'

	$(define_log_function); \
	printf '%s' "$(DOCKER_APPS)" | tr -d ' ' | base64 -d | while read -r app; do \
		log INFO "Running Docker Compose dry run for $${app}" && \
		docker compose --project-directory "$(PROJECT_DIR)/$${app}" --dry-run up --force-recreate --always-recreate-deps --remove-orphans --build <'/dev/null' && \
		printf '\n\n' && \
	true; done

	$(define_log_function); log INFO 'Docker Compose dry runs completed successfully'
	printf '\n'

.PHONY: clean
clean:
	# Check if there is an active virtualenv and abort
	$(define_log_function); \
	if [ -n "$${VIRTUAL_ENV+x}" ]; then \
		log ERROR 'There is an active python virtualenv. Run "deactivate" and try again.'; \
		exit 1; \
	fi

	$(define_log_function); log INFO 'Cleaning repository'

	find "$(PROJECT_DIR)" -type d \( \
		-name '.bundle' -or \
		-name '.mypy_cache' -or \
		-name 'build' -or \
		-name 'dist' -or \
		-name 'gitman-repositories' -or \
		-name 'node_modules' -or \
		-name 'python-vendor' -or \
		-name 'target' -or \
		-name 'test-report' -or \
		-name 'vendor' -or \
		-name 'venv' \
	\) -prune -exec rm -rf {} \;

	$(define_log_function); log INFO 'Repository cleaned'
	printf '\n'
