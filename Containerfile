FROM registry.fedoraproject.org/fedora:44

ARG USERNAME=esp
ARG UID=1000
ARG GID=1000
ARG ESPUP_TARGETS=all
ARG INSTALL_FLASH_TOOLS=false
ARG INSTALL_PROJECT_GENERATOR=true
ARG INSTALL_PROBE_RS_TOOLS=true

ENV TOOLCHAIN_ROOT=/opt/esp
ENV CARGO_HOME=/opt/cargo
ENV RUSTUP_HOME=/opt/rustup
ENV ESPUP_EXPORT_FILE=${TOOLCHAIN_ROOT}/export-esp.sh
ENV PATH=${CARGO_HOME}/bin:${PATH}
ENV HOME=/home/${USERNAME}
ENV LANG=C.UTF-8

RUN dnf -y upgrade --refresh && \
    dnf -y install \
    bash \
    ca-certificates \
    curl \
    file \
    findutils \
    gcc \
    gcc-c++ \
    git \
    cmake \
    libudev-devel \
    libusbx-devel \
    make \
    neovim \
    openssl-devel \
    perl \
    pkgconf-pkg-config \
    python3 \
    tar \
    unzip \
    which \
    xz && \
    dnf clean all && \
    rm -rf /var/cache/dnf

RUN groupadd --gid ${GID} ${USERNAME} && \
    useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USERNAME}

RUN mkdir -p ${CARGO_HOME} ${RUSTUP_HOME} ${TOOLCHAIN_ROOT} && \
    chown -R ${UID}:${GID} ${CARGO_HOME} ${RUSTUP_HOME} ${TOOLCHAIN_ROOT}

RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'export_file="${ESPUP_EXPORT_FILE:-/opt/esp/export-esp.sh}"' \
    'if [[ -f "$export_file" ]]; then' \
    '  source "$export_file"' \
    'fi' \
    'if [[ "$#" -eq 0 ]]; then' \
    '  exec bash -i' \
    'fi' \
    'exec "$@"' > /usr/local/bin/with-esp-env && \
    chmod 0755 /usr/local/bin/with-esp-env

RUN printf '%s\n' \
    'if [ -f "${ESPUP_EXPORT_FILE:-/opt/esp/export-esp.sh}" ]; then' \
    '  . "${ESPUP_EXPORT_FILE:-/opt/esp/export-esp.sh}"' \
    'fi' > /etc/profile.d/esp-env.sh && \
    chmod 0644 /etc/profile.d/esp-env.sh

USER ${USERNAME}
WORKDIR /workspace
SHELL ["/bin/bash", "-lc"]

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --profile minimal && \
    rustup toolchain install stable --component rust-src && \
    rustup default stable && \
    rustup target add riscv32imc-unknown-none-elf riscv32imac-unknown-none-elf && \
    cargo install espup --locked && \
    HOME=${TOOLCHAIN_ROOT} espup install --targets ${ESPUP_TARGETS} --export-file ${ESPUP_EXPORT_FILE} && \
    if [[ "${INSTALL_PROBE_RS_TOOLS}" == "true" ]]; then cargo install probe-rs-tools --locked; fi && \
    if [[ "${INSTALL_FLASH_TOOLS}" == "true" ]]; then cargo install espflash cargo-espflash --locked; fi && \
    if [[ "${INSTALL_PROJECT_GENERATOR}" == "true" ]]; then cargo install esp-generate --locked; fi

ENTRYPOINT ["/usr/local/bin/with-esp-env"]
CMD ["bash"]
