# Scripts

`scripts/` 放仓库级辅助脚本，主要用于本地检查和一次性维护任务。

当前脚本：

- `check_mojibake.py`：检查文档或源码中的常见乱码。
- `cleanup_residual_dirs.py`：清理重构后遗留的空目录或残留目录。
- `build_backend_image.ps1`：本地构建后端镜像的辅助入口。

业务功能、部署编排和桌面端打包不要放这里：

- 后端业务脚本放 `backend/scripts/`。
- 部署资产放 `infra/deployment/`。
- 桌面端打包放 `packaging/`。



# MinerU Integration Scripts

## 脚本说明

| 脚本              | 用途                                 |
| ----------------- | ------------------------------------ |
| verify-mineru.ps1 | 验证 MinerU 集成完整性               |
| sync-upstream.ps1 | 同步上游更新并保留 MinerU            |
| git-cleanup.ps1   | 清理 Git 仓库（解决 pack file 错误） |

## 使用方法

### 验证集成
``````powershell
cd scripts
.\verify-mineru.ps1
同步上游
cd scripts
.\sync-upstream.ps1
清理仓库
cd scripts
.\git-cleanup.ps1
要求
PowerShell 5.1+
Git 2.+
执行策略：``Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
新机器使用
# Clone 仓库后
cd AITeachMe\scripts
.\verify-mineru.ps1
"@ | Out-File -FilePath scripts\README.md -Encoding UTF8

添加到 Git
git add scripts/
git commit -m "chore: Add MinerU integration maintenance scripts

Add verify-mineru.ps1: Verify integration completeness
Add sync-upstream.ps1: Sync upstream while preserving MinerU
Add git-cleanup.ps1: Clean Git repository and resolve pack file issues
Add README.md: Usage instructions"
推送
git push origin main
``````