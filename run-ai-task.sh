#!/usr/bin/env bash
set -euo pipefail

TASK_FILE="${1:-}"

if [ -z "$TASK_FILE" ]; then
  echo "[ERROR] Missing task YAML path"
  exit 1
fi

if [ ! -f "$TASK_FILE" ]; then
  echo "[ERROR] Task file not found: $TASK_FILE"
  exit 1
fi

if [ -f /srv/ai-coding/config/secrets.env ]; then
  set -a
  source /srv/ai-coding/config/secrets.env
  set +a
fi

# 自動生成 TASK_ID（基於時間戳，避免重複）
TASK_ID="task-$(date +%Y%m%d-%H%M%S-%N | cut -c1-16)"

REPO_URL="$(yq -r '.repo_url' "$TASK_FILE")"
BASE_BRANCH="$(yq -r '.base_branch' "$TASK_FILE")"
TARGET_BRANCH="$(yq -r '.target_branch' "$TASK_FILE")"
TASK_DESCRIPTION="$(yq -r '.task_description' "$TASK_FILE")"
TEST_COMMANDS="$(yq -r '.test_commands // ""' "$TASK_FILE")"

if [ -z "$REPO_URL" ] || [ "$REPO_URL" = "null" ]; then
  echo "[ERROR] repo_url is required"
  exit 1
fi

mkdir -p "/srv/ai-coding/workspaces/$TASK_ID"
mkdir -p "/srv/ai-coding/logs/$TASK_ID"
mkdir -p "/srv/ai-coding/artifacts/$TASK_ID"

chmod -R 777 "/srv/ai-coding/workspaces/$TASK_ID"
chmod -R 777 "/srv/ai-coding/logs/$TASK_ID"
chmod -R 777 "/srv/ai-coding/artifacts/$TASK_ID"

# === Repo Cache 初始化 ===
REPO_NAME=$(basename "$REPO_URL" .git)
CACHE_DIR="/srv/ai-coding/.repo-cache"
CACHE_PATH="$CACHE_DIR/$REPO_NAME.git"

mkdir -p "$CACHE_DIR"

# 首次建立或更新 cache
if [ ! -d "$CACHE_PATH" ]; then
  echo "[INFO] Creating repo cache: $CACHE_PATH"
  git clone --mirror "$REPO_URL" "$CACHE_PATH" 2>&1 | tee "/srv/ai-coding/logs/$TASK_ID/cache-init.log" || {
    echo "[ERROR] Failed to create repo cache"
    exit 1
  }
else
  echo "[INFO] Updating repo cache"
  git -C "$CACHE_PATH" fetch -q origin 2>&1 | tee "/srv/ai-coding/logs/$TASK_ID/cache-update.log" || true
fi

chmod -R 755 "$CACHE_DIR"

DOCKER_SOCK="${DOCKER_SOCK:-/var/run/docker.sock}"
docker_cmd=(
  docker run --rm
  --name "ai-$TASK_ID"
  --cpus=2
  --memory=4g
  --pids-limit=512
  --security-opt=no-new-privileges:true
  --cap-drop=ALL
  -v "/srv/ai-coding/workspaces/$TASK_ID:/workspace"
  -v "/srv/ai-coding/logs/$TASK_ID:/logs"
  -v "/srv/ai-coding/artifacts/$TASK_ID:/artifacts"
  -v "$CACHE_PATH:/repo-cache:ro"
  -v /srv/ai-coding/config/opencode:/opencode-config:ro
  -e OPENCODE_CONFIG=/opencode-config/opencode.json
  -e GITHUB_TOKEN="${GITHUB_TOKEN:-}"
  -e GH_TOKEN="${GH_TOKEN:-}"
  -e TASK_ID="$TASK_ID"
  -e REPO_URL="$REPO_URL"
  -e BASE_BRANCH="$BASE_BRANCH"
  -e TARGET_BRANCH="$TARGET_BRANCH"
  -e TASK_DESCRIPTION="$TASK_DESCRIPTION"
  -e TEST_COMMANDS="$TEST_COMMANDS"
  -e REPO_CACHE="/repo-cache"
  -e GIT_USER_NAME="AI Coding Bot"
  -e GIT_USER_EMAIL="ai-coding-bot@example.com"
  --network ai-coding-net
  opencode-worker:latest
)

echo "[INFO] Checking Docker daemon access"
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] docker command not found"
  exit 1
fi

run_docker_cmd() {
  "${docker_cmd[@]}"
}

current_user() {
  id -un 2>/dev/null || printf '%s\n' "${USER:-unknown}"
}

user_listed_in_docker_group() {
  if ! command -v getent >/dev/null 2>&1; then
    return 1
  fi

  local docker_group_entry
  docker_group_entry="$(getent group docker 2>/dev/null || true)"
  if [ -z "$docker_group_entry" ]; then
    return 1
  fi

  case ",${docker_group_entry##*:}," in
    *,"$(current_user)",*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

session_has_docker_group() {
  id -nG 2>/dev/null | tr ' ' '\n' | grep -Fx docker >/dev/null 2>&1
}

print_docker_access_diagnostics() {
  echo "[ERROR] Cannot access Docker daemon."
  echo "[ERROR] Current user/session: $(id 2>/dev/null || echo unknown)"
  echo "[ERROR] Active groups: $(id -nG 2>/dev/null || echo unknown)"
  if [ -S "$DOCKER_SOCK" ]; then
    echo "[ERROR] Docker socket: $(stat -c '%A %U:%G %n' "$DOCKER_SOCK" 2>/dev/null || echo "$DOCKER_SOCK")"
  else
    echo "[ERROR] Docker socket not found: $DOCKER_SOCK"
  fi
  if command -v getent >/dev/null 2>&1; then
    echo "[ERROR] docker group entry: $(getent group docker 2>/dev/null || echo missing)"
  fi
  echo "[ERROR] If you recently added the user to the docker group, restart the service/session or relogin before retrying."
}

if docker info >/dev/null 2>&1; then
  run_docker_cmd
elif user_listed_in_docker_group \
  && ! session_has_docker_group \
  && command -v sg >/dev/null 2>&1; then
  echo "[WARN] Current session cannot access Docker yet; retrying via 'sg docker'"
  docker_cmd_str="$(printf '%q ' "${docker_cmd[@]}")"
  if ! sg docker -c "$docker_cmd_str"; then
    print_docker_access_diagnostics
    exit 1
  fi
else
  print_docker_access_diagnostics
  exit 1
fi
