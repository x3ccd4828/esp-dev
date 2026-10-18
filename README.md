# ESP development environment

A Fedora-based Distrobox with Rust and the ESP development tools, including
`espup`, `espflash`, `probe-rs-tools`, and `esp-generate` when built with the
Makefile defaults.

## Requirements

- Linux with Git, Make, Podman, and Distrobox installed.
- For USB access, a connected device that your host user has permission to access.
  The commands below use `/dev/ttyUSB0`; replace it with your device's path if
  necessary.

## Set up a new machine

```bash
git clone https://github.com/x3ccd4828/esp-dev.git
cd esp-dev

BOX_ENGINE_FLAGS="--device=/dev/ttyUSB0 --group-add keep-groups --userns=keep-id --security-opt=label=disable" \
make box-create-local && \
make box-enter
```

This builds `localhost/embassy-esp-fedora:latest` for your host username, UID,
and GID, creates the `esp-dev` Distrobox with USB access, and enters it with the
ESP environment loaded. `BOX_INIT_HOOKS=true` is already the default.

To enter the existing container later, run this from the repository:

```bash
make box-enter
```

## Update Fedora and the development tools

The Containerfile follows `registry.fedoraproject.org/fedora:latest`. Both build
targets pull the current base image. Use a build without cache to also rerun
the package updates and tool installations, then recreate the container:

```bash
make build-no-cache && \
BOX_ENGINE_FLAGS="--device=/dev/ttyUSB0 --group-add keep-groups --userns=keep-id --security-opt=label=disable" \
make box-recreate && \
make box-enter
```

`box-recreate` removes the existing `esp-dev` container before creating its
replacement. Save anything stored outside your shared home or mounted
directories first. Pass the USB flags again so the replacement retains device
access.

If the image has already built successfully and only recreation failed, skip
`make build-no-cache` and run the remaining commands.

Run `make help` to see the available targets and configuration variables.
