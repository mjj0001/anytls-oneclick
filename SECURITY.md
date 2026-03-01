# 安全说明

## 请勿在公开场合泄露以下内容

- **GitHub Personal Access Token (PAT)**：拥有仓库和账号的访问权限，一旦泄露请立即撤销并重新生成。
- **服务器密码、AnyTLS 密码**：仅保存在服务器本地 `/etc/anytls/config`，请勿提交到 Git 或发给他人。

## 若您曾在聊天、截图或代码中暴露过 GitHub Token

1. 登录 GitHub → **Settings** → **Developer settings** → **Personal access tokens**。
2. 找到对应 Token，点击 **Revoke** 撤销。
3. 需要推送代码时，重新生成一个新 Token（勾选 `repo` 等所需权限），并仅通过环境变量或 Git 凭据管理器使用，不要写进脚本或文档。

## 推送代码时建议

- 使用 `git push` 时通过环境变量传入 Token，例如：
  ```bash
  git remote set-url origin https://YOUR_USERNAME:YOUR_NEW_TOKEN@github.com/YOUR_USERNAME/anytls-oneclick.git
  ```
  或使用 GitHub CLI：`gh auth login` 后直接 `git push`。
- 不要将 Token 写入任何会被提交到仓库的文件中。
