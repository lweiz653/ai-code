#!/usr/bin/env bash
set -euo pipefail

echo "[AI TASK] Starting task"
echo "[AI TASK] TASK_ID=${TASK_ID:-unknown}"

required_envs=(
  TASK_ID
  REPO_URL
  BASE_BRANCH
  TARGET_BRANCH
  TASK_DESCRIPTION
)

for env_name in "${required_envs[@]}"; do
  if [ -z "${!env_name:-}" ]; then
    echo "[AI TASK][ERROR] Missing env: $env_name"
    exit 1
  fi
done

mkdir -p /workspace /logs /artifacts

cd /workspace

echo "[AI TASK] Cloning repo"
git clone "$REPO_URL" repo

cd repo

git config user.name "${GIT_USER_NAME:-AI Coding Bot}"
git config user.email "${GIT_USER_EMAIL:-ai-coding-bot@example.com}"

echo "[AI TASK] Checking out base branch: $BASE_BRANCH"
git checkout "$BASE_BRANCH"

echo "[AI TASK] Creating target branch: $TARGET_BRANCH"
git checkout -b "$TARGET_BRANCH"

echo "[AI TASK] Writing task prompt"
cat > /tmp/task_prompt.txt <<PROMPT
You are an AI coding agent working inside a controlled container.

Task ID:
$TASK_ID

Repository:
$REPO_URL

Base branch:
$BASE_BRANCH

Target branch:
$TARGET_BRANCH

Task description:
$TASK_DESCRIPTION

Rules:
- Make the smallest safe change.
- Only modify files related to the task.
- Do not modify secrets.
- Do not modify production configuration.
- Do not modify CI/CD configuration unless explicitly requested.
- Do not add new dependencies unless clearly necessary.
- Add or update tests when appropriate.
- Do not perform broad refactors.
- After changes, briefly summarize what you changed.
PROMPT

echo "[AI TASK] Running OpenCode"
opencode run "$(cat /tmp/task_prompt.txt)" || {
  echo "[AI TASK][ERROR] OpenCode failed"
  git status --short > /logs/status.txt || true
  git diff > /logs/diff.patch || true
  exit 1
}

echo "[AI TASK] Running test commands"

if [ -n "${TEST_COMMANDS:-}" ]; then
  echo "$TEST_COMMANDS" > /tmp/test_commands.txt

  while IFS= read -r cmd; do
    if [ -n "$cmd" ]; then
      echo "[AI TASK][TEST] $cmd"
      bash -lc "$cmd"
    fi
  done < /tmp/test_commands.txt
else
  echo "[AI TASK] No TEST_COMMANDS provided"
fi

echo "[AI TASK] Collecting result"

git status --short > /logs/status.txt
git diff "$BASE_BRANCH"...HEAD > /logs/diff.patch || git diff > /logs/diff.patch
git log --oneline -5 > /logs/git-log.txt

echo "[AI TASK] Creating commit if there are changes"

if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "[AI][$TASK_ID] Apply requested coding changes"
else
  echo "[AI TASK] No changes detected"
fi

echo "[AI TASK] Done"
