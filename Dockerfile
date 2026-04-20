FROM pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel

ARG USERNAME=guest
ARG USER_UID=1001
ARG USER_GID=1001

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    CUDA_MODULE_LOADING=LAZY \
    CONDA_DIR=/opt/miniconda \
    PATH=/opt/miniconda/bin:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY workspace/scripts/requirements.apt /tmp/requirements.apt

RUN set -eux; \
    apt-get update; \
    xargs -a /tmp/requirements.apt apt-get install -y --no-install-recommends; \
    git lfs install --system; \
    wget -O /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; \
    bash /tmp/miniconda.sh -b -p "$CONDA_DIR"; \
    rm -f /tmp/miniconda.sh; \
    conda clean -afy; \
    rm -rf /var/lib/apt/lists/* /tmp/requirements.apt

RUN set -eux; \
    if getent passwd "${USERNAME}" >/dev/null; then \
        userdel -r "${USERNAME}" || true; \
    fi; \
    existing_group="$(getent group "${USER_GID}" | cut -d: -f1 || true)"; \
    if [ -z "$existing_group" ]; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"; \
    mkdir -p "/home/${USERNAME}/.vscode-server" /workspace; \
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"; \
    chown -R "${USER_UID}:${USER_GID}" "$CONDA_DIR"

WORKDIR /workspace
USER ${USERNAME}

CMD ["/bin/bash"]
