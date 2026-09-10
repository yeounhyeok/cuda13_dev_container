#!/usr/bin/env bash

set -Eeuo pipefail

trap 'echo "❌ 오류 발생: line $LINENO" >&2' ERR

NODE_MAJOR=24

echo "========================================"
echo "🚀 개발 환경 설치 시작"
echo "========================================"

# ------------------------------------------------------------
# 0. 과거의 잘못된 NodeSource 설정 정리
# ------------------------------------------------------------

echo "🧹 기존 NodeSource 설정 정리..."

sudo rm -f \
  /etc/apt/sources.list.d/nodesource.list \
  /etc/apt/sources.list.d/nodesource.sources \
  /etc/apt/keyrings/nodesource.gpg

# 예전 스크립트가 /etc/apt/sources.list에 직접 넣은 경우도 방어
if sudo grep -q "https://nodesource.com" /etc/apt/sources.list 2>/dev/null; then
  sudo sed -i '\|https://nodesource.com|d' /etc/apt/sources.list
fi

# ------------------------------------------------------------
# 1. 시스템 패키지
# ------------------------------------------------------------

echo "🔄 패키지 목록 업데이트..."

sudo apt-get update

echo "📦 개발 도구 설치..."

sudo apt-get install -y \
  curl \
  ca-certificates \
  gnupg \
  git \
  git-lfs \
  tmux \
  wget \
  build-essential \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  pkg-config \
  tree \
  vim \
  nano \
  htop \
  openssh-client \
  graphviz

# ------------------------------------------------------------
# 사용자 전역 tmux 마우스 / UTF-8 (한국어 입출력)
# C.UTF-8은 Ubuntu/Debian에서 별도 한국어 locale 생성 없이 사용 가능.
# ------------------------------------------------------------

echo "🖱️ tmux 마우스 및 UTF-8 설정..."

mkdir -p "$HOME/.config/bootstrap"
cat > "$HOME/.config/bootstrap/locale.sh" <<'LOCALE_CONFIG'
export LANG=C.UTF-8
export LC_CTYPE=C.UTF-8
export LC_ALL=C.UTF-8
LOCALE_CONFIG

for shell_profile in "$HOME/.profile" "$HOME/.bashrc"; do
  if ! grep -Fqx '. "$HOME/.config/bootstrap/locale.sh"' "$shell_profile" 2>/dev/null; then
    printf '\n%s\n' '. "$HOME/.config/bootstrap/locale.sh"' >> "$shell_profile"
  fi
done
. "$HOME/.config/bootstrap/locale.sh"

cat > "$HOME/.config/bootstrap/tmux.conf" <<'TMUX_CONFIG'
set -g mouse on
set-environment -g LANG C.UTF-8
set-environment -g LC_CTYPE C.UTF-8
set-environment -g LC_ALL C.UTF-8
TMUX_CONFIG

if ! grep -Fqx 'source-file ~/.config/bootstrap/tmux.conf' "$HOME/.tmux.conf" 2>/dev/null; then
  printf '\n%s\n' 'source-file ~/.config/bootstrap/tmux.conf' >> "$HOME/.tmux.conf"
fi
# 실행 중인 세션은 재시작 없이 적용. 서버가 없으면 다음 시작 시 적용.
if tmux list-sessions >/dev/null 2>&1; then
  tmux source-file "$HOME/.config/bootstrap/tmux.conf"
fi

# ------------------------------------------------------------
# 2. Git LFS
# ------------------------------------------------------------

echo "🔧 Git LFS 초기화..."

git lfs install

# ------------------------------------------------------------
# 3. NodeSource 공식 저장소
# ------------------------------------------------------------

echo "🟢 Node.js ${NODE_MAJOR} LTS 저장소 등록..."

sudo mkdir -p /etc/apt/keyrings

curl -fsSL \
  https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --dearmor --yes \
      -o /etc/apt/keyrings/nodesource.gpg

sudo chmod 644 /etc/apt/keyrings/nodesource.gpg

echo \
  "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null

echo "🔄 NodeSource 저장소 반영..."

sudo apt-get update

# ------------------------------------------------------------
# 4. Node.js
# ------------------------------------------------------------

echo "📦 Node.js ${NODE_MAJOR} LTS 설치..."

sudo apt-get install -y nodejs

echo
echo "📌 Node.js:"
node --version

echo "📌 npm:"
npm --version

# ------------------------------------------------------------
# 5. npm global 패키지를 사용자 디렉터리에 설치
#
# sudo npm install -g 사용 안 함
# ------------------------------------------------------------

echo "🔧 npm global 사용자 경로 구성..."

mkdir -p "$HOME/.local"

npm config set prefix "$HOME/.local"

export PATH="$HOME/.local/bin:$PATH"

# 이후 로그인에서도 PATH 유지
if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
fi

# bash shell에서도 바로 사용
if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# ------------------------------------------------------------
# 6. AI CLI
# ------------------------------------------------------------

echo "🤖 OpenAI Codex CLI 설치..."

npm install -g @openai/codex@latest

echo "🤖 Anthropic Claude Code 설치..."

npm install -g @anthropic-ai/claude-code@latest

# ------------------------------------------------------------
# 7. Claude 계정/팀 전환 도구 (사용자 전역 설치)
#
# https://github.com/realiti4/claude-swap
# Python 3.12는 uv가 관리하므로 시스템 Python은 변경하지 않음.
# 로그인/팀 인증은 각 컴퓨터에서 별도로 등록.
# ------------------------------------------------------------

echo "🔀 Claude Swap (cswap) 설치..."

if ! command -v uv >/dev/null 2>&1; then
  curl -fsSL https://astral.sh/uv/install.sh \
    | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
fi

# 이미 설치된 경우에도 재실행 가능. 최신 안정 버전으로 설치/업데이트.
UV_TOOL_BIN_DIR="$HOME/.local/bin" uv tool install --python 3.12 --upgrade claude-swap

# ------------------------------------------------------------
# 8. tmux 안에서 팀 등록 후 자동 전환으로 이어지는 세션
# ------------------------------------------------------------

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/cswap-session" <<'CSWAP_SESSION'
#!/usr/bin/env bash
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/.config/bootstrap/locale.sh"

while true; do
  cat <<'MENU'

=== Claude Swap 설정 / 자동 전환 ===
1) 팀 로그인 및 등록 (팀마다 반복)
2) 등록된 팀 / 사용량 확인
3) 설정 완료 → 자동 전환 시작 (90%)
4) 셸에서 직접 설정 (exit 입력 시 이 메뉴로 복귀)

/logout 은 저장한 인증을 무효화할 수 있으니 사용하지 마세요.
자동 전환 중 Ctrl+C: 이 메뉴로 복귀
Ctrl+B 를 누른 뒤 D: 세션을 유지한 채 tmux에서 나가기
MENU
  read -r -p '선택 [1-4]: ' choice || exit 0
  case "$choice" in
    1)
      read -r -p '등록할 팀 별칭 (예: team1): ' team_alias || exit 0
      if [[ ! "$team_alias" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        echo '별칭은 영문자로 시작하고 영문, 숫자, _, - 만 사용하세요.'
        continue
      fi
      if claude auth login --claudeai; then
        cswap add --alias "$team_alias" || echo '팀 등록 실패. 로그인 상태를 확인하고 다시 시도하세요.'
      else
        echo '로그인 실패. 다시 시도하세요.'
      fi
      ;;
    2) cswap list ;;
    3)
      # Ctrl+C는 자동 전환만 중지하고 설정 메뉴로 돌아오게 함.
      echo '자동 전환 실행 중: 약 60초마다 사용량을 확인합니다. 출력이 잠시 없어도 정상입니다.'
      echo '이 화면에서는 메뉴 번호 대신 Ctrl+C로 메뉴에 돌아가세요. Ctrl+B → D로 나가도 계속 실행됩니다.'
      trap ':' INT
      cswap auto --threshold 90
      auto_status=$?
      trap - INT
      echo "자동 전환이 종료되었습니다 (종료 코드: $auto_status)."
      ;;
    4) bash -i ;;
    *) echo '1~4 중 선택하세요.' ;;
  esac
done
CSWAP_SESSION
chmod 755 "$HOME/.local/bin/cswap-session"

# 재실행해도 기존 설정 작업/자동 전환 프로세스는 유지.
if tmux has-session -t '=cswap' 2>/dev/null; then
  echo "🔀 기존 cswap tmux 세션을 유지합니다."
elif tmux has-session -t '=cswap-auto' 2>/dev/null; then
  tmux rename-session -t '=cswap-auto' cswap
  echo "🔀 기존 tmux 세션 이름을 cswap으로 변경했습니다."
else
  tmux -u new-session -d -s cswap -n setup 'exec bash "$HOME/.local/bin/cswap-session"'
  echo "🔀 cswap tmux 세션을 시작했습니다."
fi

# ------------------------------------------------------------
# 9. 설치 결과
# ------------------------------------------------------------

echo
echo "========================================"
echo "✅ 개발 환경 설치 완료"
echo "========================================"
echo

printf "%-14s %s\n" "Node.js:" "$(node --version)"
printf "%-14s %s\n" "npm:" "$(npm --version)"
printf "%-14s %s\n" "Git:" "$(git --version)"
printf "%-14s %s\n" "Git LFS:" "$(git lfs version)"
printf "%-14s %s\n" "Python:" "$(python3 --version)"
printf "%-14s %s\n" "Codex:" "$(codex --version)"
printf "%-14s %s\n" "Claude Code:" "$(claude --version)"
printf "%-14s %s\n" "uv:" "$(uv --version)"
printf "%-14s %s\n" "Claude Swap:" "$(cswap --version)"

echo
cat <<'CSWAP_HELP'
🔀 cswap tmux 세션이 준비되어 있습니다:
  tmux -u attach -t cswap
  (이미 tmux 안이라면: tmux switch-client -t cswap)

세션 안에서:
  1번 → 팀 로그인 및 등록 (팀마다 반복, 같은 이메일의 여러 팀도 가능)
  2번 → 등록 결과 확인
  3번 → 설정을 마치고 사용량 90%부터 자동 전환 시작
  4번 → 셸에서 직접 설정, exit으로 메뉴 복귀

Ctrl+B 를 누른 뒤 D로 나가면 SSH를 끊어도 세션은 유지됩니다.
자동 전환은 약 60초마다 확인하며, Ctrl+C를 누르면 설정 메뉴로 돌아옵니다.
마우스로 스크롤/창 선택이 가능하며, 새 로그인과 tmux에는 UTF-8이 적용됩니다.
부트스트랩을 다시 실행해도 기존 cswap 세션을 유지합니다.
재부팅 후에는 다음 명령으로 설정 세션을 다시 시작하세요:
  tmux -u new-session -d -s cswap 'exec bash "$HOME/.local/bin/cswap-session"'

설치와 팀 로그인은 각 컴퓨터/서버의 현재 사용자 기준입니다.
CSWAP_HELP

echo "🎉 완료!"
