# CUDA 13 PyTorch 개발 컨테이너

공용 PyTorch CUDA 이미지를 새로 빌드하지 않고 그대로 사용하면서, 개인 개발에 필요한 설정만 `/workspace` 안에서 관리하는 개발용 컨테이너입니다.

- 기본 이미지: `pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel`
- 컨테이너 이름: `ssh_cuda13`
- 작업 디렉토리: `/workspace`
- 사용 GPU: 호스트 GPU `0`, `1`, `2`

## 사용법

### 1. 컨테이너 실행

레포 루트에서 컨테이너를 실행합니다.

```bash
docker compose -f compose.yml up -d
```

컨테이너 상태를 확인합니다.

```bash
docker ps
```

컨테이너에 접속합니다.

```bash
docker exec -it ssh_cuda13 bash
```

### 2. 초기 세팅

컨테이너 내부에서 `/workspace`로 이동한 뒤 초기 세팅 스크립트를 실행합니다.

```bash
cd /workspace
bash initial_setup.sh
```

초기 세팅 스크립트는 아래 작업을 순서대로 수행합니다.

1. apt 패키지 설치
2. `/workspace/.miniconda`에 Miniconda 설치
3. GPU와 PyTorch CUDA 동작 확인

### 3. 이후 사용

초기 세팅이 끝난 뒤에는 컨테이너에 접속해서 `/workspace`에서 작업하면 됩니다.

```bash
docker exec -it ssh_cuda13 bash
cd /workspace
```

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
├── compose.yml
└── workspace
    ├── initial_setup.sh
    └── scripts
        ├── bootstrap_apt.sh
        ├── bootstrap_conda
        ├── gpu_check.sh
        └── requirements.apt
```

## 주요 파일

### `compose.yml`

PyTorch CUDA 13 개발 컨테이너를 실행하는 Docker Compose 설정입니다. 호스트의 `./workspace` 폴더가 컨테이너의 `/workspace`로 마운트됩니다.

### `workspace/initial_setup.sh`

최초 1회 실행하는 통합 초기 세팅 스크립트입니다.

```bash
bash /workspace/initial_setup.sh
```

### `workspace/scripts/requirements.apt`

컨테이너 안에서 설치할 apt 패키지 목록입니다. 필요한 시스템 패키지가 생기면 이 파일에 추가한 뒤 apt 설치 스크립트를 다시 실행합니다.

```bash
bash /workspace/scripts/bootstrap_apt.sh
```

### `workspace/scripts/bootstrap_conda`

Miniconda를 `/workspace/.miniconda`에 설치합니다.

```bash
bash /workspace/scripts/bootstrap_conda
```

### `workspace/scripts/gpu_check.sh`

컨테이너에서 GPU가 정상적으로 보이는지 확인합니다.

```bash
bash /workspace/scripts/gpu_check.sh
```

확인 항목은 `nvidia-smi`, PyTorch CUDA 사용 가능 여부, GPU 개수입니다.

## GPU 사용 정책

이 컨테이너는 호스트의 GPU `0`, `1`, `2`만 사용하도록 설정되어 있습니다. 컨테이너 내부에서는 GPU가 3개만 보여야 합니다.

```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"
```

## 권장 흐름

최초 1회:

```bash
docker compose -f compose.yml up -d
docker exec -it ssh_cuda13 bash
cd /workspace
bash initial_setup.sh
```

반복 사용:

```bash
docker exec -it ssh_cuda13 bash
cd /workspace
source /workspace/.miniconda/bin/activate
```

## 문제 해결

GPU가 보이지 않을 때:

```bash
nvidia-smi
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"
```

conda가 잡히지 않을 때:

```bash
source /workspace/.miniconda/bin/activate
conda --version
```

apt 패키지를 추가해야 할 때:

```bash
vim /workspace/scripts/requirements.apt
bash /workspace/scripts/bootstrap_apt.sh
```
