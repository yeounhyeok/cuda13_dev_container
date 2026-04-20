# CUDA 13 PyTorch 개발 컨테이너

PyTorch CUDA 이미지를 기반으로 공통 시스템 설정을 Dockerfile로 관리하는 개발용 컨테이너입니다.

- 기본 이미지: `pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel`
- 로컬 이미지: `cuda13-pytorch-dev:local`
- 컨테이너 이름: `ssh_cuda13`
- 작업 디렉토리: `/workspace`
- 사용 GPU: 호스트 GPU `0`, `1`, `2`

이미지에 포함되는 것:
- `workspace/scripts/requirements.apt`의 apt 패키지
- Git LFS 시스템 초기화
- `guest` 사용자와 기본 홈 디렉토리

이미지에 포함하지 않는 것:
- 연구별 conda 환경
- 프로젝트별 Python 패키지
- 실험별 추가 bootstrap

## 사용법

### 1. 컨테이너 빌드 및 실행

```bash
docker compose -f compose.yml up -d --build
```

호스트 사용자 ID가 다르면 아래처럼 build arg를 넘겨 bind mount 권한을 맞춥니다.

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose -f compose.yml up -d --build
```

`/workspace`는 bind mount이므로 실제 쓰기 권한은 호스트의 소유자/권한과 build arg로 전달한 UID/GID에 의해 결정됩니다.

### 2. 컨테이너 접속

기본 실행 사용자는 `guest`입니다.

```bash
docker exec -it ssh_cuda13 bash
whoami
```

### 3. conda 환경 사용

이 레포는 conda 자체를 이미지에 굽지 않습니다. 필요하면 컨테이너 내부 `/workspace`에서 직접 설치하거나, 프로젝트별 환경을 별도로 준비해 사용합니다.

예시:

```bash
# 예: Miniconda를 /workspace 아래에 수동 설치 후 사용
source /workspace/.miniconda/bin/activate
conda create -n myenv python=3.10 -y
conda activate myenv
```

## 파일 구조

```text
.
├── .dockerignore
├── Dockerfile
├── compose.yml
└── workspace
    └── scripts
        ├── bootstrap_conda
        ├── gpu_check.sh
        └── requirements.apt
```
