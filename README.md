# CUDA 13 PyTorch 개발 컨테이너 — vi005

vi005의 CUDA 개발 환경을 관리하는 저장소입니다. [Dockerfile](Dockerfile)은 이미지와 기본 도구를, [compose.yml](compose.yml)은 GPU·자원 제한·마운트·네트워크를, [bootstrap.sh](bootstrap.sh)는 사용자 개발 도구와 tmux 설정을 관리합니다.

이 문서는 저장소에 커밋된 설정을 기준으로 합니다. 현재 vi005 안에서의 저장소 위치는 다음과 같습니다.

```text
/home/guest/VI001/vi005/docker_volumes/cuda13_dev_container
```

## 현재 Compose 설정

| 항목 | 설정 |
| --- | --- |
| 기본 이미지 | `pytorch/pytorch:2.9.0-cuda13.0-cudnn9-devel` |
| 빌드 이미지 | `cuda13-pytorch-dev:local` |
| Compose 프로젝트 / 컨테이너 | `vi005` / `vi005` |
| Compose 서비스 | `dev_cuda13` |
| 사용자 | `guest`, 기본 UID/GID `1001:1001`, 비밀번호 없는 `sudo` |
| 추가 그룹 | GID `987` — 호스트 데이터 경로 접근용 |
| 기본 작업 디렉터리 | `/home/guest/VI001` |
| GPU | `0,1,2,3`, NVIDIA 장치 파일 직접 연결 |
| 자원 제한 | 메모리 `192G`, CPU `48.0` |
| 포트 | 호스트 `7071–7072` → 컨테이너 `7071–7072` |
| 네트워크 | Compose 기본 네트워크 + 외부 `vilab`, 고정 IP `172.30.0.15` |
| IPC / PID | 호스트 네임스페이스 공유 |
| 재시작 정책 | `unless-stopped` |

다른 호스트에서 사용할 때는 GPU 번호와 장치 경로, 데이터 경로, GID, 포트, 네트워크 주소를 해당 환경에 맞게 조정합니다.

## 호스트에서 빌드 및 접속

Docker 명령은 Docker 데몬에 접근할 수 있는 **호스트**에서 실행합니다. 호스트에는 NVIDIA 드라이버, NVIDIA Container Toolkit, 현재 `gpus` 설정을 지원하는 Docker Compose가 필요합니다.

저장소 루트에서 다음 조건을 확인합니다.

- `/data/VI001`이 존재하고 컨테이너의 `guest` 사용자가 필요한 읽기·쓰기 권한을 갖습니다.
- `compose.yml`에 나열된 GPU와 `/dev/nvidia*` 장치가 존재합니다.
- 외부 Docker 네트워크 `vilab`이 생성되어 있고, `172.30.0.15`를 할당할 수 있습니다.
- `workspace/.state/claude-home`은 디렉터리이고, `workspace/.state/claude.json`은 파일입니다.

새 환경에서 Claude 상태 경로를 준비할 때는 기존 파일을 유지하도록 다음과 같이 실행합니다. 이 경로도 컨테이너의 `guest` 사용자가 쓸 수 있어야 합니다.

```bash
mkdir -p workspace/.state/claude-home
if [ ! -e workspace/.state/claude.json ]; then
  printf '{}\n' > workspace/.state/claude.json
fi
```

설정을 확인하고 빌드·실행합니다.

```bash
docker network inspect vilab
docker compose config --quiet
docker compose up -d --build
docker compose ps
```

`vilab`이 없는 호스트에서는 사용할 서브넷에 맞춰 외부 네트워크를 먼저 생성해야 합니다. Compose는 `external: true`인 네트워크를 생성하지 않습니다.

실행 중인 vi005에는 다음 명령으로 접속합니다.

```bash
docker exec -it vi005 bash
```

`compose.yml`에는 2026-09-02에 기존 컨테이너를 `vilab`에 연결했다는 기록이 있습니다. 해당 연결만을 위해 `docker compose up`을 다시 실행할 필요는 없습니다. `up -d --build`는 새로 배포하거나 컨테이너 설정 변경을 적용할 때 사용합니다.

VS Code의 Dev Containers에서는 [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json)을 사용합니다. 서비스는 `dev_cuda13`, 열리는 작업 폴더는 `/home/guest/VI001`입니다.

## 컨테이너 안에서 개발 도구 설치

`guest` 사용자로 저장소 루트에서 실행합니다. 스크립트 내부에서 필요한 시스템 작업에 `sudo`를 사용합니다.

```bash
cd /home/guest/VI001/vi005/docker_volumes/cuda13_dev_container
./bootstrap.sh
```

다른 컴퓨터나 서버에서도 Bash, `apt-get`, `sudo`를 사용할 수 있는 Debian/Ubuntu 계열 환경에서 현재 사용자 기준으로 실행할 수 있습니다.

| 설치 단계 | 설치·설정 내용 |
| --- | --- |
| Dockerfile의 이미지 빌드 | Node.js 24, npm, Miniconda, Codex CLI `0.125.0`, Kaggle CLI `2.1.0`, Git LFS 및 `requirements.apt`의 도구 |
| `bootstrap.sh` 실행 | Node.js 24, Python 3 개발 도구, Git LFS, tmux, Graphviz 등 설치·업데이트 |
| 사용자 CLI | npm의 `@latest`로 Codex CLI와 Claude Code 설치, uv 및 Claude Swap 설치·업데이트 |
| Python 도구 환경 | Claude Swap용 Python 3.12를 uv로 관리 |
| 셸과 tmux | `C.UTF-8`, tmux 마우스 사용, 사용자 실행 경로 설정 |
| Claude Swap 세션 | 팀 등록 메뉴가 있는 `cswap-auto` tmux 세션 준비 |

부트스트랩은 npm 전역 설치 경로를 `~/.local`로 설정하고, `~/.local/bin`을 `~/.profile`과 `~/.bashrc`의 `PATH`에 추가합니다. uv 도구 실행 파일과 `cswap-session`도 `~/.local/bin`에 설치합니다.

이미 열려 있던 Bash 셸에는 다음 명령으로 설정을 반영할 수 있습니다.

```bash
source ~/.bashrc
```

설정 파일은 `~/.config/bootstrap/locale.sh`, `~/.config/bootstrap/tmux.conf`에 저장됩니다. 부트스트랩을 다시 실행하면 CLI를 업데이트하며, 기존 `cswap-auto` 세션은 유지합니다.

## Claude Swap 팀 등록과 자동 전환

부트스트랩 완료 후 컨테이너 안에서 설정 세션에 접속합니다.

```bash
tmux -u attach -t cswap-auto
```

이미 tmux 안이라면 다음 명령을 사용합니다.

```bash
tmux switch-client -t cswap-auto
```

| 메뉴 | 동작 |
| --- | --- |
| `1` | 팀 별칭 입력 → `claude auth login --claudeai` → `cswap add --alias`로 등록. 팀마다 반복 |
| `2` | `cswap list`로 등록된 팀과 사용량 확인 |
| `3` | `cswap auto --threshold 90`으로 사용량 90% 기준 자동 전환 시작 |
| `4` | 대화형 Bash 셸에서 직접 설정. `exit`으로 메뉴 복귀 |

팀 별칭은 영문자로 시작하고 영문·숫자·`_`·`-`를 사용할 수 있습니다. 메뉴의 안내에 따라 `/logout`은 저장된 인증을 무효화할 수 있으므로 사용하지 않습니다. 로그인과 팀 등록은 각 컴퓨터·서버의 사용자별로 진행합니다.

자동 전환 중 `Ctrl+C`를 누르면 메뉴로 돌아옵니다. `Ctrl+B`를 누른 뒤 `D`를 누르면 세션을 유지한 채 tmux에서 나갈 수 있으며, SSH 연결이 끊겨도 컨테이너가 실행 중이면 세션은 계속됩니다. 자동 전환 시작은 메뉴 `3`에서 직접 선택합니다.

재부팅이나 컨테이너 재시작으로 tmux 세션이 사라졌다면, 설치 파일이 있는 상태에서 다음 명령으로 메뉴 세션을 다시 만듭니다.

```bash
tmux -u new-session -d -s cswap-auto 'exec bash "$HOME/.local/bin/cswap-session"'
tmux -u attach -t cswap-auto
```

## 데이터와 사용자 설정 보관

Compose의 상대 경로는 저장소 루트를 기준으로 합니다.

| 호스트 경로 | 컨테이너 경로 | 용도 |
| --- | --- | --- |
| `./workspace` | `/home/guest/workspace` | 작업 파일과 사용자 상태 |
| `/data/VI001` | `/home/guest/VI001` | 공용 데이터·프로젝트 경로 |
| `./workspace/.state/claude-home` | `/home/guest/.claude` | Claude 사용자 디렉터리 |
| `./workspace/.state/claude.json` | `/home/guest/.claude.json` | Claude 설정 파일 |

[컨테이너 시작 스크립트](workspace/scripts/container-entrypoint.sh)는 아래 홈 디렉터리를 `~/workspace/.state`에 심볼릭 링크로 연결합니다. 기존 홈 디렉터리에 파일이 있으면 자동으로 옮기거나 덮어쓰지 않으므로, 해당 경로는 실제 링크 여부를 확인해야 합니다.

```text
~/.vscode-server -> ~/workspace/.state/vscode-server
~/.codex         -> ~/workspace/.state/codex
~/.npm           -> ~/workspace/.state/npm
~/.npm-global    -> ~/workspace/.state/npm-global
~/.cache         -> ~/workspace/.state/cache
~/.config        -> ~/workspace/.state/config
~/.kaggle        -> ~/workspace/.state/kaggle
~/.ssh           -> ~/workspace/.state/ssh
```

Kaggle 인증 파일 위치는 `~/.kaggle/kaggle.json`입니다. `~/workspace/.jupyter/share/jupyter/kernels`에 커널 디렉터리가 있으면 시작 스크립트가 `~/.local/share/jupyter/kernels` 아래에 링크를 만듭니다. `/workspace`는 `/home/guest/workspace`를 가리키는 호환 링크입니다.

현재 설정에서 `~/.local` 전체와 `~/.tmux.conf`, `~/.profile`, `~/.bashrc`, `~/.npmrc`는 별도로 영속 저장하지 않습니다. **컨테이너를 재생성하면 `bootstrap.sh`를 다시 실행**하여 사용자 CLI, PATH, tmux 설정과 세션을 준비합니다. tmux 프로세스 자체는 컨테이너 재시작·재생성 후에 유지되지 않습니다.

## 환경 확인

Miniconda는 `/opt/miniconda`에 설치됩니다. 프로젝트별 환경은 별도로 생성해서 사용합니다.

```bash
source /opt/miniconda/bin/activate
conda --version
```

GPU와 PyTorch를 확인합니다. `gpu_check.sh`는 현재 `python` 환경에서 `torch`를 가져오므로, PyTorch가 설치된 환경을 활성화한 뒤 실행합니다.

```bash
bash ~/workspace/scripts/gpu_check.sh
```

부트스트랩 설치 결과는 다음 명령으로 확인합니다.

```bash
node --version
npm --version
git lfs version
python3 --version
codex --version
claude --version
uv --version
cswap --version
tmux list-sessions
```

## 파일 구조

```text
.
├── .devcontainer/
│   └── devcontainer.json
├── .dockerignore
├── .gitignore
├── Dockerfile
├── README.md
├── bootstrap.sh
├── compose.yml
└── workspace/
    ├── .state/                  # 사용자 상태, Git 제외
    └── scripts/
        ├── container-entrypoint.sh
        ├── gpu_check.sh
        └── requirements.apt
```

`workspace/`의 프로젝트·데이터·사용자 상태는 Git에서 제외하며, 컨테이너 관리용 `workspace/scripts/`는 추적합니다. 로컬 Compose 백업 파일 `compose.yml.bak.*`도 Git에서 제외합니다.
