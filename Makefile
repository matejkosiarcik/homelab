# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build

.PHONY: bootstrap
bootstrap:
	npm ci --prefix "$(PROJECT_DIR)/icons"
	npm ci --prefix "$(PROJECT_DIR)/machines/odroid-h3/omada-controller/backuper"
	npm ci --prefix "$(PROJECT_DIR)/machines/odroid-h3/unifi-network-application/backuper"
	npm ci --prefix "$(PROJECT_DIR)/machines/odroid-h3/uptime-kuma/backuper"
	npm ci --prefix "$(PROJECT_DIR)/machines/raspberrypi-3b/pi-hole/backuper"

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
	npm run build --prefix "$(PROJECT_DIR)/machines/odroid-h3/omada-controller/backuper"
	npm run build --prefix "$(PROJECT_DIR)/machines/odroid-h3/unifi-network-application/backuper"
	npm run build --prefix "$(PROJECT_DIR)/machines/odroid-h3/uptime-kuma/backuper"
	npm run build --prefix "$(PROJECT_DIR)/machines/raspberrypi-3b/pi-hole/backuper"

.PHONY: build-docker
build-docker:
	docker build "$(PROJECT_DIR)/machines/odroid-h3/healthchecks/backuper" --tag healthchecks-backup:homelab
	docker build "$(PROJECT_DIR)/odroid-h3/omada-controller/backuper" --tag omada-controller-backup:homelab
	docker build "$(PROJECT_DIR)/machines/odroid-h3/unifi-network-application/backuper" --tag unifi-network-application-backup:homelab
	docker build "$(PROJECT_DIR)/machines/odroid-h3/uptime-kuma/backuper" --tag uptime-kuma-backup:homelab
	docker build "$(PROJECT_DIR)/machines/raspberrypi-3b/pi-hole/backuper" --tag pihole-backup:homelab

.PHONY: build-docker-multiarch
build-docker-multiarch:
	printf '%s\n%s\n' amd64 arm64/v8 | \
		while read -r arch; do \
			printf 'Building for linux/%s:\n' "$$arch" && \
			docker build "$(PROJECT_DIR)/machines/odroid-h3/healthchecks/backuper" --tag "healthchecks-backup:homelab-$$(printf '%s' "$$arch" | tr '/' '-')"  && \
			docker build "$(PROJECT_DIR)/machines/odroid-h3/omada-controller/backuper" --tag "omada-controller-backup:homelab-$$(printf '%s' "$$arch" | tr '/' '-')"  && \
			docker build "$(PROJECT_DIR)/machines/odroid-h3/unifi-network-application/backuper" --tag "unifi-network-application-backup:homelab-$$(printf '%s' "$$arch" | tr '/' '-')"  && \
			docker build "$(PROJECT_DIR)/machines/odroid-h3/uptime-kuma/backuper" --tag "uptime-kuma-backup:homelab-$$(printf '%s' "$$arch" | tr '/' '-')"  && \
			docker build "$(PROJECT_DIR)/machines/raspberrypi-3b/pi-hole/backuper" --tag "pihole-backup:homelab-$$(printf '%s' "$$arch" | tr '/' '-')" " && \
		true; done

.PHONY: run
run:
	# TODO: Run script

.PHONY: clean
clean:
	rm -rf \
		"$(PROJECT_DIR)/.mypy_cache" \
		"$(PROJECT_DIR)/homelab" \
		"$(PROJECT_DIR)/icons/gitman" \
		"$(PROJECT_DIR)/icons/node_modules" \
		"$(PROJECT_DIR)/icons/venv" \
		"$(PROJECT_DIR)/machines/odroid-h3/omada-controller/backuper/dist" \
		"$(PROJECT_DIR)/machines/odroid-h3/omada-controller/backuper/node_modules" \
		"$(PROJECT_DIR)/machines/odroid-h3/unifi-network-application/backuper/dist" \
		"$(PROJECT_DIR)/machines/odroid-h3/unifi-network-application/backuper/node_modules" \
		"$(PROJECT_DIR)/machines/odroid-h3/uptime-kuma/backuper/dist" \
		"$(PROJECT_DIR)/machines/odroid-h3/uptime-kuma/backuper/node_modules" \
		"$(PROJECT_DIR)/machines/raspberrypi-3b/pi-hole/backuper/dist" \
		"$(PROJECT_DIR)/machines/raspberrypi-3b/pi-hole/backuper/node_modules" \
		"$(PROJECT_DIR)/venv" \
