FROM pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel

ARG USERNAME=guest
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    CUDA_MODULE_LOADING=LAZY

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY workspace/scripts/requirements.apt /tmp/requirements.apt

RUN set -eux; \
    apt-get update; \
    xargs -a /tmp/requirements.apt apt-get install -y --no-install-recommends; \
    git lfs install --system; \
    rm -rf /var/lib/apt/lists/* /tmp/requirements.apt

RUN set -eux; \
    if ! getent group "${USER_GID}" >/dev/null; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    if ! id --user "${USERNAME}" >/dev/null 2>&1; then \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"; \
    fi; \
    mkdir -p "/home/${USERNAME}/.vscode-server" /workspace; \
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}" /workspace

WORKDIR /workspace
USER ${USERNAME}

CMD ["/bin/bash"]
