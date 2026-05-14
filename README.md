# AI Coding System

AI 自動編程任務執行系統。外部接收 YAML 配置，系統自動生成唯一 TASK_ID，並執行編程任務。

## 快速開始

### YAML 配置格式

**必需欄位：**
```yaml
repo_url: https://github.com/user/repo
base_branch: main
target_branch: ai/feature-001
task_description: |
  任務描述，支持多行
```

**可選欄位：**
```yaml
test_commands: |
  npm test
  npm run lint
  
pr_title: "[AI] 修復標題"
pr_body: "PR 描述"
create_pr: true  # 是否建立 PR（預設 true）
```

**注意：** 無需提供 `task_id`，系統將自動生成唯一 ID（基於時間戳）

### 執行任務

```bash
# 方式 1：直接運行（僅執行編程任務）
./run-ai-task.sh task.yaml

# 方式 2：完整流程（包括 Git 推送和 PR 建立）
./openclaw-run-task.sh task.yaml
```

## 功能特性

### ✅ 自動生成 TASK_ID
- 格式：`task-YYYYMMDD-HHMMSS-NNNNNNN`
- 完全避免重複問題
- 無需外部系統維護 ID 唯一性

### ✅ Repo 快取機制
- 首次複製完整倉庫到 `/srv/ai-coding/.repo-cache/`
- 後續任務從本機快取複製（<1秒）
- **效能提升：96-98%**

### ✅ Worktree 隔離
- 每個任務獨立的 Git worktree
- 防止任務之間互相污染
- 支持安全的並發執行

### ✅ 完整的 Git 流程
- 自動建立 PR
- 記錄詳細日誌
- 支持自訂分支和提交訊息

## 日誌和輸出

執行完畢後，日誌儲存在：
```
/srv/ai-coding/logs/{task-id}/
├── cache-init.log      # Repo 快取初始化日誌
├── cache-update.log    # 快取更新日誌
├── status.txt          # Git 狀態
├── diff.patch          # 程式碼變更
├── git-log.txt         # 提交歷史
└── pr-url.txt          # PR 連結（如果建立）
```

工作目錄：
```
/srv/ai-coding/workspaces/{task-id}/
└── repo/               # 複製的倉庫
    ├── work-{task-id}/ # 獨立 worktree
    └── .git/           # Git 配置
```

## 範例

參考 `task.example.yaml` 瞭解完整的配置範例。

## 系統要求

- Bash 4.0+
- Git
- Docker
- yq（YAML 解析）
- GitHub CLI（選用，用於 PR 建立）
