#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace"
SCRIPTS_DIR="$ROOT/scripts"

chmod +x "$SCRIPTS_DIR"/*.sh

echo "[1/3] Installing apt packages..."
bash "$SCRIPTS_DIR/bootstrap_apt.sh"

echo "[2/3] Installing Miniconda..."
bash "$SCRIPTS_DIR/bootstrap_conda"

echo "[3/3] Checking GPU visibility..."
bash "$SCRIPTS_DIR/gpu_check.sh"

echo
echo "[DONE] Initial setup completed."
echo "[NEXT] To use conda later:"
echo "  source /workspace/.miniconda/bin/activate"
