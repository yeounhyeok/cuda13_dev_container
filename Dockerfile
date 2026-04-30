FROM pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel

ARG USERNAME=guest
ARG USER_UID=1001
ARG USER_GID=1001
ARG NODE_MAJOR=24
ARG CODEX_VERSION=0.125.0
ARG KAGGLE_VERSION=2.1.0

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    CUDA_MODULE_LOADING=LAZY \
    CONDA_DIR=/opt/miniconda \
    PATH=/opt/miniconda/bin:/home/${USERNAME}/.npm-global/bin:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY workspace/scripts/requirements.apt /tmp/requirements.apt

RUN set -eux; \
    apt-get update; \
    xargs -a /tmp/requirements.apt apt-get install -y --no-install-recommends; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    git lfs install --system; \
    wget -O /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; \
    bash /tmp/miniconda.sh -b -p "$CONDA_DIR"; \
    rm -f /tmp/miniconda.sh; \
    npm install -g "npm@latest" "@openai/codex@${CODEX_VERSION}"; \
    npm cache clean --force; \
    python -m pip install --no-cache-dir "kaggle==${KAGGLE_VERSION}"; \
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
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    mkdir -p "/home/${USERNAME}/.vscode-server" "/home/${USERNAME}/.kaggle" "/home/${USERNAME}/.cache" "/home/${USERNAME}/.config" "/home/${USERNAME}/.npm-global" /workspace; \
    chmod 0700 "/home/${USERNAME}/.kaggle"; \
    printf 'prefix=/home/%s/.npm-global\n' "${USERNAME}" > "/home/${USERNAME}/.npmrc"; \
    { \
        echo ''; \
        echo '# User toolchain defaults'; \
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"'; \
        echo 'if [ -f /opt/miniconda/etc/profile.d/conda.sh ]; then'; \
        echo '    . /opt/miniconda/etc/profile.d/conda.sh'; \
        echo 'fi'; \
    } >> "/home/${USERNAME}/.bashrc"; \
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"; \
    chown -R "${USER_UID}:${USER_GID}" "$CONDA_DIR"

WORKDIR /workspace
USER ${USERNAME}

CMD ["/bin/bash"]
