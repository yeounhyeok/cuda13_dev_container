# CUDA 13 PyTorch 개발 컨테이너

PyTorch CUDA 기반 개발 컨테이너입니다.
공통 시스템 설정은 Dockerfile로 관리하고, 작업 공간은 `/home/guest/workspace`를 사용합니다.

- base: `pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel`
- image: `cuda13-pytorch-dev:local`
- container: `ssh_cuda13`
- GPUs: `0,1,2`
- user: `guest` with passwordless `sudo`
- tools: Node.js/npm, Codex CLI, Kaggle CLI
- persistent workspace: `./workspace:/home/guest/workspace`
- persistent state: `/home/guest/workspace/.state`

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
`/home/guest/.kaggle`은 `/home/guest/workspace/.state/kaggle`로 연결되어 컨테이너 재생성 후에도 유지됩니다.

### 5. GPU 확인
```bash
bash ~/workspace/scripts/gpu_check.sh
```

## 영속 상태

컨테이너 시작 시 다음 홈 디렉터리는 `~/workspace/.state` 아래로 연결됩니다.

```text
~/.vscode-server -> ~/workspace/.state/vscode-server
~/.codex         -> ~/workspace/.state/codex
~/.npm           -> ~/workspace/.state/npm
~/.npm-global    -> ~/workspace/.state/npm-global
~/.cache         -> ~/workspace/.state/cache
~/.config        -> ~/workspace/.state/config
~/.kaggle        -> ~/workspace/.state/kaggle
```

기존 `/workspace` 경로는 `/home/guest/workspace`를 가리키는 호환 symlink입니다.

기존 컨테이너의 Kaggle 인증을 새 구조로 옮길 때는 재생성 전에 실행합니다.

```bash
install -d -m 700 ~/workspace/.state/kaggle && cp -a ~/.kaggle/. ~/workspace/.state/kaggle/ && find ~/workspace/.state/kaggle -type f -exec chmod 600 {} +
```

## 파일 구조

```text
.
├── .dockerignore
├── Dockerfile
├── compose.yml
└── workspace
    └── scripts
        ├── container-entrypoint.sh
        ├── gpu_check.sh
        └── requirements.apt
```
