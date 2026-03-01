# 创建 GitHub 仓库并推送

**仓库已在 GitHub 创建完成**：https://github.com/mjj0001/anytls-oneclick  

你只需在本地用 Git 推送代码即可（Token 记得自行删除或轮换）。

## 1. 本地推送（在已安装 Git 的电脑上执行）

在项目目录（包含 `install.sh`、`README.md` 等的文件夹）中打开终端，执行：

```bash
cd C:\Users\mjjmj\anytls-oneclick

git init
git add .
git commit -m "feat: AnyTLS 一键安装脚本与多客户端配置"

git remote add origin https://github.com/mjj0001/anytls-oneclick.git
git branch -M main
git push -u origin main
```

推送时若提示输入密码，请使用你的 **GitHub Token**（不是登录密码）。  
若本机未安装 Git，可先安装 [Git for Windows](https://git-scm.com/download/win) 再执行上述命令。

若已配置 SSH：

```bash
git remote add origin git@github.com:mjj0001/anytls-oneclick.git
git push -u origin main
```

## 2. 一键安装链接（推送成功后可用）

```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/install.sh) install
```
