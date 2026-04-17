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

컨테이너 내부에서 권한 설정 및 사용자를 추가한 뒤 `/workspace`로 이동하여 초기 세팅 스크립트를 실행합니다.

```bash
# 사용자 및 그룹 추가 (권한 설정)
groupadd -g 1001 guest
useradd -m -u 1001 -g 1001 -s /bin/bash guest
mkdir -p /home/guest/.vscode-server
chown -R 1001:1001 /home/guest
chown -R 1001:1001 /workspace

# 초기 세팅 스크립트 실행
cd /workspace
bash initial_setup.sh
```

초기 세팅 스크립트는 아래 작업을 순서대로 수행합니다.

1. apt 패키지 설치
2. `/workspace/.miniconda`에 Miniconda 설치
3. GPU와 PyTorch CUDA 동작 확인


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
