# CUDA 13 PyTorch 개발 컨테이너

PyTorch CUDA 이미지를 기반으로 공통 시스템 설정만 얇게 빌드하고, 개인 개발 환경은 `/workspace` 안에서 관리하는 개발용 컨테이너입니다.

- 기본 이미지: `pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel`
- 로컬 이미지: `cuda13-pytorch-dev:local`
- 컨테이너 이름: `ssh_cuda13`
- 작업 디렉토리: `/workspace`
- 사용 GPU: 호스트 GPU `0`, `1`, `2`

이미지에는 안정적인 공통 요소만 포함합니다.

- `workspace/scripts/requirements.apt`의 apt 패키지 (Docker build 입력)
- Git LFS 시스템 초기화
- `guest` 사용자와 기본 홈 디렉토리

연구별 Python/conda 환경은 이미지에 굽지 않고 `/workspace` 아래에서 필요할 때 만듭니다.

## 사용법

### 1. 컨테이너 빌드 및 실행

레포 루트에서 컨테이너를 빌드하고 실행합니다.

```bash
docker compose -f compose.yml up -d --build
```

기본 `guest` UID/GID는 `1000:1000`입니다. 호스트 사용자 ID가 다르면 아래처럼 빌드 인자를 넘겨 bind mount 권한을 맞출 수 있습니다.

`/workspace`는 bind mount이므로, 실제 쓰기 권한은 호스트의 소유자/권한과 build arg로 전달한 UID/GID에 의해 결정됩니다.

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose -f compose.yml up -d --build
```

컨테이너 상태를 확인합니다.

```bash
docker ps
```

컨테이너에 접속합니다. 기본 실행 사용자는 `guest`입니다.

```bash
docker exec -it ssh_cuda13 bash
whoami
```

### 2. 초기 세팅

컨테이너 내부에서 `/workspace`로 이동하여 초기 세팅 스크립트를 실행합니다.

```bash
cd /workspace
bash initial_setup.sh
```

초기 세팅 스크립트는 workspace-local 작업만 수행합니다.

1. `/workspace/.miniconda`에 Miniconda 설치
2. GPU와 PyTorch CUDA 동작 확인


conda를 사용할 때는 아래처럼 활성화합니다.

```bash
source /workspace/.miniconda/bin/activate
conda --version
```

프로젝트별 환경은 필요할 때 따로 생성하는 것을 권장합니다.

```bash
conda create -n myenv python=3.10 -y
conda activate myenv
```

## 파일 구조

```text
.
├── Dockerfile
├── compose.yml
└── workspace
    ├── initial_setup.sh
    └── scripts
        ├── bootstrap_conda
        ├── gpu_check.sh
        └── requirements.apt
```
