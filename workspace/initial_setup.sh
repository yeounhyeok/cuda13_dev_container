#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace"
SCRIPTS_DIR="$ROOT/scripts"

chmod +x "$SCRIPTS_DIR/bootstrap_conda" "$SCRIPTS_DIR/gpu_check.sh"

echo "[1/2] Installing workspace-local Miniconda..."
bash "$SCRIPTS_DIR/bootstrap_conda"

echo "[2/2] Checking GPU visibility..."
bash "$SCRIPTS_DIR/gpu_check.sh"

echo
echo "[DONE] Initial setup completed."
echo "[NEXT] To use conda later:"
echo "  source /workspace/.miniconda/bin/activate"
