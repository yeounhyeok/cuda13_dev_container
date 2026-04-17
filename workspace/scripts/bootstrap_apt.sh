#!/usr/bin/env bash
set -euo pipefail

REQ_FILE="/workspace/requirements.apt"

if [[ ! -f "$REQ_FILE" ]]; then
  echo "[ERROR] requirements.apt not found: $REQ_FILE"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
xargs -a "$REQ_FILE" apt-get install -y --no-install-recommends

git lfs install

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[OK] apt packages installed."