#!/usr/bin/env bash
set -euo pipefail

workspace="${HOME}/workspace"
state_dir="${workspace}/.state"

mkdir -p "${state_dir}"

link_state_dir() {
    local name="$1"
    local target="${state_dir}/${name}"
    local link="${HOME}/.${name}"

    mkdir -p "${target}"
    if [ -e "${link}" ] && [ ! -L "${link}" ] && [ -z "$(find "${link}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
        rmdir "${link}"
    fi
    if [ ! -e "${link}" ]; then
        ln -s "${target}" "${link}"
    fi
}

link_state_dir "vscode-server"
link_state_dir "codex"
link_state_dir "npm"
link_state_dir "npm-global"
link_state_dir "cache"
link_state_dir "config"
link_state_dir "kaggle"
link_state_dir "ssh"

chmod 700 "${state_dir}/kaggle"
chmod 700 "${state_dir}/ssh"
find "${state_dir}/kaggle" -type f -exec chmod 600 {} + 2>/dev/null || true
find "${state_dir}/ssh" -maxdepth 1 -type f \( -name 'id_*' -o -name 'config' -o -name 'known_hosts' \) -exec chmod 600 {} + 2>/dev/null || true

persistent_jupyter="${workspace}/.jupyter/share/jupyter/kernels"
runtime_jupyter="${HOME}/.local/share/jupyter/kernels"
if [ -d "${persistent_jupyter}" ]; then
    mkdir -p "${runtime_jupyter}"
    for kernel in "${persistent_jupyter}"/*; do
        [ -d "${kernel}" ] || continue
        ln -sfn "${kernel}" "${runtime_jupyter}/$(basename "${kernel}")"
    done
fi

exec "$@"
