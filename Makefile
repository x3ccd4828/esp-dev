ENGINE ?= podman
CONTAINERFILE ?= Containerfile
CONTEXT ?= .

IMAGE ?= embassy-esp-fedora
TAG ?= latest
IMAGE_REF := $(IMAGE):$(TAG)

USERNAME ?= $(shell id -un)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
ESPUP_TARGETS ?= all
INSTALL_FLASH_TOOLS ?= true
INSTALL_PROJECT_GENERATOR ?= true
INSTALL_PROBE_RS_TOOLS ?= true

BOX_NAME ?= esp-dev
BOX_IMAGE ?= localhost/$(IMAGE_REF)
BOX_ADDITIONAL_FLAGS ?=
BOX_ENGINE_FLAGS ?= $(BOX_ADDITIONAL_FLAGS)
BOX_INIT_HOOKS ?= true
BOX_BUILD_USERNAME ?= $(shell id -un)
BOX_BUILD_UID ?= $(shell id -u)
BOX_BUILD_GID ?= $(shell id -g)
BOX_ENTER_COMMAND ?= /usr/local/bin/with-esp-env bash -i

BUILD_ARGS = \
	--build-arg USERNAME=$(USERNAME) \
	--build-arg UID=$(UID) \
	--build-arg GID=$(GID) \
	--build-arg ESPUP_TARGETS=$(ESPUP_TARGETS) \
	--build-arg INSTALL_FLASH_TOOLS=$(INSTALL_FLASH_TOOLS) \
	--build-arg INSTALL_PROJECT_GENERATOR=$(INSTALL_PROJECT_GENERATOR) \
	--build-arg INSTALL_PROBE_RS_TOOLS=$(INSTALL_PROBE_RS_TOOLS)

.PHONY: help build build-no-cache box-create box-create-local box-enter box-rm box-recreate

help:
	@printf '%s\n' 'Targets:'
	@printf '%s\n' '  make build            Build image with cache'
	@printf '%s\n' '  make build-no-cache   Build image without cache'
	@printf '%s\n' '  make box-create       Create distrobox from BOX_IMAGE'
	@printf '%s\n' '  make box-create-local Build image, then create distrobox'
	@printf '%s\n' '  make box-enter        Enter distrobox shell'
	@printf '%s\n' '  make box-rm           Remove distrobox'
	@printf '%s\n' '  make box-recreate     Recreate distrobox from image'
	@printf '%s\n' ''
	@printf '%s\n' 'Variables (override as needed):'
	@printf '%s\n' '  ENGINE=podman|docker'
	@printf '%s\n' "  IMAGE=embassy-esp-fedora TAG=latest USERNAME=$(USERNAME)"
	@printf '%s\n' '  ESPUP_TARGETS=all'
	@printf '%s\n' '  INSTALL_FLASH_TOOLS=false|true'
	@printf '%s\n' '  INSTALL_PROJECT_GENERATOR=true|false'
	@printf '%s\n' '  INSTALL_PROBE_RS_TOOLS=true|false'
	@printf '%s\n' '  BOX_NAME=esp-dev BOX_IMAGE=localhost/embassy-esp-fedora:latest'
	@printf '%s\n' '  BOX_ENGINE_FLAGS="--group-add keep-groups --device /dev/ttyUSB0 --security-opt=label=disable"'
	@printf '%s\n' '  BOX_INIT_HOOKS=true'
	@printf '%s\n' '  BOX_ENTER_COMMAND="/usr/local/bin/with-esp-env bash -i"'
	@printf '%s\n' "  BOX_BUILD_USERNAME=$(BOX_BUILD_USERNAME) BOX_BUILD_UID=$(BOX_BUILD_UID) BOX_BUILD_GID=$(BOX_BUILD_GID)"

build:
	$(ENGINE) build -f $(CONTAINERFILE) -t $(IMAGE_REF) $(BUILD_ARGS) $(CONTEXT)

build-no-cache:
	$(ENGINE) build --no-cache -f $(CONTAINERFILE) -t $(IMAGE_REF) $(BUILD_ARGS) $(CONTEXT)

box-create:
	distrobox create --name $(BOX_NAME) --image $(BOX_IMAGE) --init-hooks "$(BOX_INIT_HOOKS)" $(if $(strip $(BOX_ENGINE_FLAGS)),--additional-flags "$(BOX_ENGINE_FLAGS)",)

box-create-local:
	$(MAKE) build USERNAME=$(BOX_BUILD_USERNAME) UID=$(BOX_BUILD_UID) GID=$(BOX_BUILD_GID)
	$(MAKE) box-create USERNAME=$(BOX_BUILD_USERNAME)

box-enter:
	distrobox enter $(BOX_NAME) -- $(BOX_ENTER_COMMAND)

box-rm:
	distrobox rm --force $(BOX_NAME)

box-recreate: box-rm box-create
