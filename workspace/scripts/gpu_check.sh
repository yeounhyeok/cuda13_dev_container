#!/usr/bin/env bash
set -euo pipefail

echo "===== nvidia-smi ====="
nvidia-smi

echo
echo "===== torch cuda check ====="
python - <<'PY'
import torch
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
print("cuda device count:", torch.cuda.device_count())
for i in range(torch.cuda.device_count()):
    print(f"device {i}: {torch.cuda.get_device_name(i)}")
PY