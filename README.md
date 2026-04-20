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
- Miniconda (`/opt/miniconda`)

## 사용법

### 1. 컨테이너 빌드 및 실행

```bash
docker compose up -d --build
```

`/workspace`는 bind mount이므로 실제 쓰기 권한은 호스트의 소유자/권한과 build arg로 전달한 UID/GID에 의해 결정됩니다.

### 2. 컨테이너 접속

기본 실행 사용자는 `guest`입니다.

```bash
docker exec -it ssh_cuda13 bash
whoami
```

### 3. conda 사용

Miniconda는 이미지에 포함되어 있으므로 바로 사용할 수 있습니다.

```bash
source /opt/miniconda/bin/activate
conda --version
```

프로젝트별 환경은 필요할 때 따로 생성해서 사용합니다.

```bash
conda create -n myenv python=3.10 -y
conda activate myenv
```

### 4. GPU 체크

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
