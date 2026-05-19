#!/usr/bin/env bash
# Run syntax checks and Docker smoke tests for bootstrap scripts.
# Usage:
#   ./test.sh           — run all tests
#   ./test.sh 15-node   — run only tests matching the filter
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"
PASS=0
FAIL=0
SKIP=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}PASS${NC}  $1"; ((PASS++)); }
fail() { echo -e "${RED}FAIL${NC}  $1"; ((FAIL++)); }
skip() { echo -e "${YELLOW}SKIP${NC}  $1"; ((SKIP++)); }

should_run() { [[ -z "$FILTER" ]] || [[ "$1" == *"$FILTER"* ]]; }

ALL_SCRIPTS=(
  bootstrap.sh
  scripts/00-core.sh
  scripts/10-dev.sh
  scripts/12-shell.sh
  scripts/13-kitty.sh
  scripts/14-python.sh
  scripts/15-node.sh
  scripts/20-ui.sh
  scripts/25-keyd.sh
  scripts/90-cleanup.sh
  system/gsettings.sh
)

# ── Syntax (bash -n) ─────────────────────────────────────────────────────────

echo "==> Syntax (bash -n)"
for rel in "${ALL_SCRIPTS[@]}"; do
  f="$REPO_ROOT/$rel"
  should_run "$rel" || continue
  if bash -n "$f" 2>&1; then
    pass "syntax: $rel"
  else
    fail "syntax: $rel"
  fi
done

# ── Shellcheck ───────────────────────────────────────────────────────────────

echo ""
if command -v shellcheck >/dev/null 2>&1; then
  echo "==> shellcheck"
  for rel in "${ALL_SCRIPTS[@]}"; do
    f="$REPO_ROOT/$rel"
    should_run "$rel" || continue
    if shellcheck --external-sources "$f" 2>&1 | sed 's/^/    /'; then
      pass "shellcheck: $rel"
    else
      fail "shellcheck: $rel"
    fi
  done
else
  echo "==> shellcheck not installed — skipping (apt install shellcheck)"
fi

# ── Docker smoke tests ───────────────────────────────────────────────────────
# Each test runs in a fresh ubuntu:24.04 container.
# SUDO="" lets scripts run apt-get directly as root.
# Idempotency is verified by running each script twice in the same container.

echo ""
echo "==> Docker smoke tests"

if ! command -v docker >/dev/null 2>&1; then
  skip "docker not available — skipping all smoke tests"
else

docker_test() {
  local name="$1"         # display name / filter key
  local apt_pre="$2"      # space-separated packages to pre-install (or "")
  local script="$3"       # script path relative to repo root
  local check="$4"        # shell command to assert success

  should_run "$name" || return 0

  local pre_cmd=""
  [[ -n "$apt_pre" ]] && pre_cmd="apt-get update -qq && apt-get install -y $apt_pre -qq 2>/dev/null &&"

  echo ""
  echo "--- $name"
  local output
  if output=$(docker run --rm \
    -v "$REPO_ROOT:/repo:ro" \
    ubuntu:24.04 bash -c "
      set -euo pipefail
      $pre_cmd
      export HOME=/root SUDO='' NO_SUDO=0 GIT_TERMINAL_PROMPT=0
      cp -r /repo /setup
      # First run
      bash /setup/scripts/$script
      # Second run (idempotency)
      bash /setup/scripts/$script
      # Verify
      $check
    " 2>&1); then
    echo "$output" | tail -5 | sed 's/^/    /'
    pass "$name"
  else
    echo "$output" | tail -20 | sed 's/^/    /'
    fail "$name"
  fi
}

# 00-core: apt packages
docker_test "00-core" "" "00-core.sh" \
  'command -v rg && command -v zsh && command -v fzf && echo "binaries ok"'

# 12-shell: oh-my-zsh + plugins (needs zsh + git)
docker_test "12-shell" "zsh git" "12-shell.sh" \
  'test -d ~/.oh-my-zsh &&
   test -d ~/.oh-my-zsh/custom/themes/powerlevel10k &&
   test -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions &&
   test -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &&
   echo "dirs ok"'

# 13-kitty: terminal emulator
docker_test "13-kitty" "curl" "13-kitty.sh" \
  'test -x ~/.local/kitty.app/bin/kitty && echo "kitty ok"'

# 14-python: uv
docker_test "14-python" "curl" "14-python.sh" \
  'export PATH="$HOME/.local/bin:$PATH"; uv --version'

# 15-node: nvm + node + npm globals (includes claude)
docker_test "15-node" "curl" "15-node.sh" \
  'NVM_DIR="$HOME/.nvm"
   . "$NVM_DIR/nvm.sh"
   node --version
   npm --version
   NODE_BIN="$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node)/bin"
   export PATH="$NODE_BIN:$PATH"
   claude --version && echo "claude ok"'

fi  # docker available

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════"
echo -e "  ${GREEN}PASS${NC} $PASS  ${RED}FAIL${NC} $FAIL  ${YELLOW}SKIP${NC} $SKIP"
echo "══════════════════════════════════"

[[ "$FAIL" -eq 0 ]]
