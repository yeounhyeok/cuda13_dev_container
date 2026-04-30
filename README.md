# CUDA 13 PyTorch 개발 컨테이너

PyTorch CUDA 기반 개발 컨테이너입니다.
공통 시스템 설정은 Dockerfile로 관리하고, 작업 공간은 `/workspace`를 사용합니다.

- base: `pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel`
- image: `cuda13-pytorch-dev:local`
- container: `ssh_cuda13`
- GPUs: `0,1,2`
- user: `guest` with passwordless `sudo`
- tools: Node.js/npm, Codex CLI, Kaggle CLI

## 사용법

세부 실행 설정(컨테이너 이름, 포트, GPU, 환경변수 등)은 `compose.yml`에서 조정합니다.

### 1. 빌드 및 실행
```bash
docker compose up -d --build
```

### 2. 컨테이너 접속
```bash
docker exec -it ssh_cuda13 bash
```

### 3. conda 사용
```bash
source /opt/miniconda/bin/activate
conda --version
```

필요한 env는 직접 생성해서 사용합니다.

### 4. 기본 도구 확인
```bash
sudo -V
node --version
npm --version
codex --version
kaggle --version
```

Kaggle 인증 파일은 `/home/guest/.kaggle/kaggle.json`에 둡니다.

### 5. GPU 확인
```bash
bash /workspace/scripts/gpu_check.sh
```

## 파일 구조

```text
.
├── .dockerignore
├── Dockerfile
├── compose.yml
└── workspace
    └── scripts
        ├── gpu_check.sh
        └── requirements.apt
```
