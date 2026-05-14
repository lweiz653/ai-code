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

TASK_ID="$(yq -r '.task_id' "$TASK_FILE")"
REPO_URL="$(yq -r '.repo_url' "$TASK_FILE")"
BASE_BRANCH="$(yq -r '.base_branch' "$TASK_FILE")"
TARGET_BRANCH="$(yq -r '.target_branch' "$TASK_FILE")"
TASK_DESCRIPTION="$(yq -r '.task_description' "$TASK_FILE")"
TEST_COMMANDS="$(yq -r '.test_commands // ""' "$TASK_FILE")"

if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "null" ]; then
  echo "[ERROR] task_id is required"
  exit 1
fi

mkdir -p "/srv/ai-coding/workspaces/$TASK_ID"
mkdir -p "/srv/ai-coding/logs/$TASK_ID"
mkdir -p "/srv/ai-coding/artifacts/$TASK_ID"

chmod -R 777 "/srv/ai-coding/workspaces/$TASK_ID"
chmod -R 777 "/srv/ai-coding/logs/$TASK_ID"
chmod -R 777 "/srv/ai-coding/artifacts/$TASK_ID"

rm -rf "/srv/ai-coding/workspaces/$TASK_ID/repo"

docker run --rm \
  --name "ai-$TASK_ID" \
  --cpus=2 \
  --memory=4g \
  --pids-limit=512 \
  --security-opt=no-new-privileges:true \
  --cap-drop=ALL \
  -v "/srv/ai-coding/workspaces/$TASK_ID:/workspace" \
  -v "/srv/ai-coding/logs/$TASK_ID:/logs" \
  -v "/srv/ai-coding/artifacts/$TASK_ID:/artifacts" \
  -v /srv/ai-coding/config/opencode:/opencode-config:ro \
  -e OPENCODE_CONFIG=/opencode-config/opencode.json \
  -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
  -e GH_TOKEN="${GH_TOKEN:-}" \
  -e TASK_ID="$TASK_ID" \
  -e REPO_URL="$REPO_URL" \
  -e BASE_BRANCH="$BASE_BRANCH" \
  -e TARGET_BRANCH="$TARGET_BRANCH" \
  -e TASK_DESCRIPTION="$TASK_DESCRIPTION" \
  -e TEST_COMMANDS="$TEST_COMMANDS" \
  -e GIT_USER_NAME="AI Coding Bot" \
  -e GIT_USER_EMAIL="ai-coding-bot@example.com" \
  --network ai-coding-net \
  opencode-worker:latest
