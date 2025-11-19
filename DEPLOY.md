# GitHub Pages 部署指南

## 📋 前置准备

1. 确保你有一个 GitHub 账号
2. 确保已安装 Git 并配置好用户信息

## 🚀 部署步骤

### 第一步：创建 GitHub 仓库

1. 登录 GitHub，创建一个新仓库
2. 仓库名称必须是：`username.github.io`（将 username 替换为你的 GitHub 用户名）
3. 设置为 Public（公开）
4. 不要勾选 "Initialize this repository with a README"

### 第二步：修改配置文件

打开 `_config.yml` 文件，修改以下内容：

```yaml
# Site 部分 - 修改站点信息
title: 我的博客                    # 修改为你的博客标题
author: Your Name                  # 修改为你的名字

# URL 部分 - 修改为你的 GitHub Pages 地址
url: https://username.github.io    # 将 username 替换为你的 GitHub 用户名

# Deployment 部分 - 修改仓库地址
deploy:
  type: git
  repo: https://github.com/username/username.github.io.git  # 替换 username
  branch: main
```

### 第三步：配置 Git（如果还没配置）

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

### 第四步：初始化本地 Git 仓库

```bash
# 初始化 Git 仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit"

# 添加远程仓库（将 username 替换为你的 GitHub 用户名）
git remote add origin https://github.com/username/username.github.io.git

# 推送到 GitHub（源代码分支，可选）
git branch -M source
git push -u origin source
```

### 第五步：部署到 GitHub Pages

```bash
# 清理缓存
npm run clean

# 生成静态文件
npm run build

# 部署到 GitHub Pages
npm run deploy
```

部署命令会自动将生成的静态文件推送到仓库的 main 分支。

### 第六步：配置 GitHub Pages

1. 进入你的 GitHub 仓库
2. 点击 Settings（设置）
3. 在左侧菜单找到 Pages
4. 在 Source 下选择 main 分支
5. 点击 Save

等待几分钟后，访问 `https://username.github.io` 即可看到你的博客！

## 📝 日常使用

### 写新文章

```bash
# 创建新文章
npx hexo new "文章标题"

# 编辑文章（在 source/_posts/ 目录下）
```

### 本地预览

```bash
# 启动本地服务器
npm run server

# 访问 http://localhost:4000 预览
```

### 发布文章

```bash
# 清理 + 生成 + 部署（三合一）
npm run clean && npm run build && npm run deploy
```

## 🔧 常见问题

### 1. 部署时提示权限错误

如果使用 HTTPS 方式推送遇到权限问题，可以：
- 使用 GitHub Personal Access Token
- 或改用 SSH 方式（需要配置 SSH 密钥）

### 2. 修改为 SSH 方式部署

在 `_config.yml` 中修改：

```yaml
deploy:
  type: git
  repo: git@github.com:username/username.github.io.git
  branch: main
```

### 3. 保存源代码

建议将博客源代码也推送到 GitHub：

```bash
# 创建 source 分支保存源代码
git checkout -b source
git add .
git commit -m "Update source"
git push origin source
```

这样你的仓库会有两个分支：
- `main` 分支：存放生成的静态网站文件（由 hexo deploy 自动管理）
- `source` 分支：存放博客源代码（手动管理）

## 📚 更多资源

- [Hexo 官方文档](https://hexo.io/zh-cn/docs/)
- [Fluid 主题文档](https://hexo.fluid-dev.com/docs/)
- [GitHub Pages 文档](https://docs.github.com/cn/pages)

