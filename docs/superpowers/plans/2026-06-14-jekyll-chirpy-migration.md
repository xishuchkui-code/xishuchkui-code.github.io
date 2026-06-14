# Jekyll Chirpy Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Hexo/Fluid source site with a Jekyll site based on the downloaded Chirpy 7.5.0 theme, migrating all 7 posts and images to Chirpy's native structure and default routes.

**Architecture:** Use the downloaded `E:\Blog\jekyll-theme-chirpy-7.5.0` project as the source of truth for Jekyll/Chirpy files, then overlay the user's identity, posts, and assets. Remove Hexo-specific source files from the repository, convert Markdown front matter and image paths, and verify with Bundler/Jekyll when Ruby is available. If Ruby/Bundler is missing, stop before claiming local Jekyll build success and report the runtime blocker.

**Tech Stack:** Jekyll, jekyll-theme-chirpy 7.5.0, Bundler/Ruby, Liquid, Kramdown Markdown, GitHub Pages or GitHub Actions deployment.

---

## File Structure

- Remove Hexo source/build files:
  - `_config.fluid.yml`
  - `_config.landscape.yml`
  - `scaffolds/`
  - `themes/`
  - `source/` after all posts/images are migrated
  - Hexo `package.json`
  - Hexo `package-lock.json`
- Keep ignored generated/cache directories out of commits:
  - `public/`
  - `.deploy_git/`
  - `node_modules/`
  - `db.json`
- Copy from `E:\Blog\jekyll-theme-chirpy-7.5.0`:
  - `_config.yml`
  - `Gemfile`
  - `index.html`
  - `_data/`
  - `_includes/`
  - `_javascript/`
  - `_layouts/`
  - `_plugins/`
  - `_sass/`
  - `_tabs/`
  - `assets/`
  - `jekyll-theme-chirpy.gemspec`
  - `.editorconfig`
  - `.gitattributes`
  - `.markdownlint.json`
  - `.nojekyll`
  - `.stylelintrc.json`
  - `eslint.config.js`
  - `purgecss.js`
  - `rollup.config.js`
- Create `_posts/` with converted post files:
  - `_posts/2026-03-31-jwt-introduction.md`
  - `_posts/2026-04-03-portswigger-jwt.md`
  - `_posts/2026-02-17-portswigger-ssrf.md`
  - `_posts/2025-12-09-portswigger-file-upload.md`
  - `_posts/2025-11-25-file-upload.md`
  - `_posts/2025-12-06-conditional-error-blind-sql-injection.md`
  - `_posts/2025-11-19-hello-world.md`
- Move images:
  - `source/img/**` to `assets/img/**`
- Configure Chirpy:
  - `_config.yml`
  - `_data/contact.yml`
  - `_data/authors.yml` if needed
  - `_tabs/about.md`

## Task 1: Runtime And Source Inventory

**Files:**
- No source edits expected.

- [ ] **Step 1: Confirm Ruby runtime availability**

Run:

```powershell
ruby -v
bundle -v
gem -v
```

Expected on the current machine as of planning:

```text
ruby: The term 'ruby' is not recognized...
bundle: The term 'bundle' is not recognized...
gem: The term 'gem' is not recognized...
```

If Ruby/Bundler are available instead, record their versions and continue.

- [ ] **Step 2: Confirm Chirpy source directory exists**

Run:

```powershell
Test-Path 'E:\Blog\jekyll-theme-chirpy-7.5.0\_config.yml'
Test-Path 'E:\Blog\jekyll-theme-chirpy-7.5.0\Gemfile'
Test-Path 'E:\Blog\jekyll-theme-chirpy-7.5.0\_layouts\post.html'
```

Expected:

```text
True
True
True
```

- [ ] **Step 3: Inventory current posts**

Run:

```powershell
Get-ChildItem -LiteralPath source\_posts -Filter *.md | Select-Object -ExpandProperty Name
```

Expected list:

```text
带条件错误的盲SQL注入.md
文件上传漏洞.md
自我介绍-开启我的博客之旅.md
JWT介绍与原理.md
PortSwigger-文件上传漏洞.md
PortSwigger-JWT.md
PortSwigger-SSRF.md
```

- [ ] **Step 4: Commit nothing**

Run:

```powershell
git status --short
```

Expected: no changes caused by this task. Existing untracked `source/_posts/PortSwigger-JWT.md` and `source/img/PortSwigger-JWT/` may still appear.

## Task 2: Replace Hexo Skeleton With Chirpy Skeleton

**Files:**
- Delete: `_config.fluid.yml`
- Delete: `_config.landscape.yml`
- Delete: `scaffolds/`
- Delete: `themes/`
- Delete: `package.json`
- Delete: `package-lock.json`
- Create/Modify from Chirpy source: files listed in File Structure
- Preserve temporarily until Task 3 and Task 4 complete: `source/`

- [ ] **Step 1: Copy Chirpy project files into the repository**

Use PowerShell copy commands from the repository root:

```powershell
$chirpy = 'E:\Blog\jekyll-theme-chirpy-7.5.0'
$items = @(
  '_data',
  '_includes',
  '_javascript',
  '_layouts',
  '_plugins',
  '_sass',
  '_tabs',
  'assets',
  '_config.yml',
  'Gemfile',
  'index.html',
  'jekyll-theme-chirpy.gemspec',
  '.editorconfig',
  '.gitattributes',
  '.markdownlint.json',
  '.nojekyll',
  '.stylelintrc.json',
  'eslint.config.js',
  'purgecss.js',
  'rollup.config.js'
)
foreach ($item in $items) {
  Copy-Item -LiteralPath (Join-Path $chirpy $item) -Destination . -Recurse -Force
}
```

Expected: Chirpy files and folders exist in the repository.

- [ ] **Step 2: Remove Chirpy demo posts**

Run:

```powershell
Remove-Item -LiteralPath '_posts' -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path '_posts' | Out-Null
```

Expected: `_posts/` exists and is empty.

- [ ] **Step 3: Remove Hexo-only tracked source files**

Run:

```powershell
git rm -r -- _config.fluid.yml _config.landscape.yml scaffolds themes package.json package-lock.json
```

Expected: tracked Hexo-only files are staged for deletion. If a path is not tracked, remove it with `Remove-Item` only when it is safe and generated/unused.

- [ ] **Step 4: Keep `source/` for later migration**

Run:

```powershell
Test-Path source
```

Expected:

```text
True
```

Do not delete `source/` in this task.

- [ ] **Step 5: Inspect staged skeleton diff**

Run:

```powershell
git status --short
```

Expected: Chirpy files appear as added/modified and Hexo-only files appear deleted. `source/` is still present.

- [ ] **Step 6: Commit skeleton replacement**

Run:

```powershell
git add .editorconfig .gitattributes .markdownlint.json .nojekyll .stylelintrc.json Gemfile _config.yml index.html jekyll-theme-chirpy.gemspec eslint.config.js purgecss.js rollup.config.js _data _includes _javascript _layouts _plugins _sass _tabs assets _posts
git commit -m "chore: replace hexo skeleton with chirpy"
```

Expected: commit succeeds. Existing untracked source JWT content must not disappear.

## Task 3: Configure Chirpy Site Identity

**Files:**
- Modify: `_config.yml`
- Modify: `_data/contact.yml`
- Modify: `_data/authors.yml`
- Modify: `_tabs/about.md`
- Copy: `source/img/xiaoye.jpg` to `assets/img/xiaoye.jpg` if not already copied by Task 4

- [ ] **Step 1: Update `_config.yml` core identity**

Set these values in `_config.yml`:

```yaml
theme: jekyll-theme-chirpy
lang: zh-CN
timezone: Asia/Shanghai
title: xidumplings
tagline: Web 安全笔记库
description: >-
  记录 Web 安全学习、靶场实验、漏洞原理和工具环境配置。
url: "https://xishuchkui-code.github.io"
github:
  username: xishuchkui-code
twitter:
  username:
social:
  name: xidumplings
  email:
  fediverse_handle:
  links:
    - https://github.com/xishuchkui-code
theme_mode:
cdn:
avatar: "/assets/img/xiaoye.jpg"
toc: true
comments:
  provider:
pwa:
  enabled: true
```

Keep Chirpy's collections/defaults/permalink configuration, including:

```yaml
permalink: /posts/:title/
```

- [ ] **Step 2: Disable demo social contacts**

Open `_data/contact.yml` and remove or disable demo Twitter/Telegram/etc entries. Keep GitHub only:

```yaml
- type: github
  icon: "fab fa-github"
  url: "https://github.com/xishuchkui-code"
```

If the file uses a different Chirpy 7.5.0 schema, preserve the schema and only remove demo accounts.

- [ ] **Step 3: Configure author data**

Set `_data/authors.yml` to:

```yaml
xidumplings:
  name: xidumplings
  url: https://github.com/xishuchkui-code
```

- [ ] **Step 4: Update About tab**

Set `_tabs/about.md` to:

```markdown
---
icon: fas fa-info-circle
order: 4
---

# 关于

这里记录我的 Web 安全学习笔记、靶场复盘、漏洞原理和工具环境配置。
```

- [ ] **Step 5: Ensure avatar exists**

Run:

```powershell
New-Item -ItemType Directory -Force -Path 'assets\img' | Out-Null
Copy-Item -LiteralPath 'source\img\xiaoye.jpg' -Destination 'assets\img\xiaoye.jpg' -Force
Test-Path 'assets\img\xiaoye.jpg'
```

Expected:

```text
True
```

- [ ] **Step 6: Commit identity configuration**

Run:

```powershell
git add _config.yml _data/contact.yml _data/authors.yml _tabs/about.md assets/img/xiaoye.jpg
git commit -m "feat: configure chirpy site identity"
```

Expected: commit succeeds.

## Task 4: Migrate Images

**Files:**
- Create/Modify: `assets/img/**`
- Delete after migration: `source/img/**` with `source/` deletion in Task 6

- [ ] **Step 1: Copy all current images**

Run:

```powershell
Copy-Item -LiteralPath 'source\img\*' -Destination 'assets\img' -Recurse -Force
```

Expected: image folders such as `assets/img/PortSwigger-SSRF/`, `assets/img/PortSwigger-JWT/`, and `assets/img/PortSwigger-文件上传漏洞/` exist.

- [ ] **Step 2: Verify key image directories**

Run:

```powershell
Test-Path 'assets\img\PortSwigger-SSRF'
Test-Path 'assets\img\PortSwigger-JWT'
Test-Path 'assets\img\PortSwigger-文件上传漏洞'
Test-Path 'assets\img\xiaoye.jpg'
```

Expected:

```text
True
True
True
True
```

- [ ] **Step 3: Commit migrated assets**

Run:

```powershell
git add assets/img
git commit -m "content: migrate images to chirpy assets"
```

Expected: commit succeeds and includes the previously untracked JWT images.

## Task 5: Convert Posts To Chirpy Format

**Files:**
- Create:
  - `_posts/2026-03-31-jwt-introduction.md`
  - `_posts/2026-04-03-portswigger-jwt.md`
  - `_posts/2026-02-17-portswigger-ssrf.md`
  - `_posts/2025-12-09-portswigger-file-upload.md`
  - `_posts/2025-11-25-file-upload.md`
  - `_posts/2025-12-06-conditional-error-blind-sql-injection.md`
  - `_posts/2025-11-19-hello-world.md`

- [ ] **Step 1: Convert `JWT介绍与原理.md`**

Create `_posts/2026-03-31-jwt-introduction.md` with this front matter:

```yaml
---
title: JWT介绍与原理
date: 2026-03-31 11:07:59 +0800
categories: [Web Security, Auth]
tags: [jwt, auth, token]
description: 梳理 JWT 的组成、签名验证、常见风险和安全使用边界。
render_with_liquid: false
---
```

Append the original body from `source/_posts/JWT介绍与原理.md` after its front matter. Convert image links from `../img/` to `/assets/img/`.

- [ ] **Step 2: Convert `PortSwigger-JWT.md`**

Create `_posts/2026-04-03-portswigger-jwt.md` with:

```yaml
---
title: PortSwigger-JWT
date: 2026-04-03 14:57:21 +0800
categories: [Web Security, Auth]
tags: [jwt, portswigger, burp-suite]
description: 记录 PortSwigger JWT 相关实验的解题过程、关键请求和验证思路。
render_with_liquid: false
---
```

Append the original body from `source/_posts/PortSwigger-JWT.md`. Convert image links from `../img/` to `/assets/img/`.

- [ ] **Step 3: Convert `PortSwigger-SSRF.md`**

Create `_posts/2026-02-17-portswigger-ssrf.md` with:

```yaml
---
title: PortSwigger-SSRF
date: 2026-02-17 16:38:37 +0800
categories: [Web Security, SSRF]
tags: [ssrf, portswigger, burp-suite]
description: 记录 PortSwigger SSRF 靶场的抓包分析、payload 构造和实验复盘。
render_with_liquid: false
---
```

Append the original body from `source/_posts/PortSwigger-SSRF.md`. Convert image links from `../img/` to `/assets/img/`.

- [ ] **Step 4: Convert file upload posts**

Create `_posts/2025-12-09-portswigger-file-upload.md` with:

```yaml
---
title: PortSwigger-文件上传漏洞
date: 2025-12-09 17:31:31 +0800
categories: [Web Security, File Upload]
tags: [file-upload, portswigger, burp-suite]
description: 记录 PortSwigger 文件上传漏洞实验的请求分析、绕过方式和复盘要点。
render_with_liquid: false
---
```

Create `_posts/2025-11-25-file-upload.md` with:

```yaml
---
title: 文件上传漏洞
date: 2025-11-25 17:31:05 +0800
categories: [Web Security, File Upload]
tags: [file-upload, web-security]
description: 梳理文件上传漏洞的基础原理、常见校验点和绕过思路。
render_with_liquid: false
---
```

Append each original body and convert image links.

- [ ] **Step 5: Convert SQL injection and intro posts**

Create `_posts/2025-12-06-conditional-error-blind-sql-injection.md` with:

```yaml
---
title: 带条件错误的盲SQL注入
date: 2025-12-06 10:59:48 +0800
categories: [Web Security, SQL Injection]
tags: [sql-injection, blind-sql]
description: 记录带条件错误回显的盲 SQL 注入判断方法和实验过程。
render_with_liquid: false
---
```

Create `_posts/2025-11-19-hello-world.md` with:

```yaml
---
title: 自我介绍 - 开启我的博客之旅 - Hello World!
date: 2025-11-19 12:05:44 +0800
categories: [Life]
tags: [intro, notes]
description: 关于 xidumplings 和这个笔记博客的起点。
render_with_liquid: false
---
```

Append each original body and convert image links.

- [ ] **Step 6: Verify no old image references remain in converted posts**

Run:

```powershell
Select-String -Path '_posts\*.md' -Pattern '../img/'
```

Expected: no output.

- [ ] **Step 7: Verify all 7 posts exist**

Run:

```powershell
Get-ChildItem -LiteralPath _posts -Filter *.md | Measure-Object
```

Expected count: `7`.

- [ ] **Step 8: Commit converted posts**

Run:

```powershell
git add _posts
git commit -m "content: convert posts to chirpy format"
```

Expected: commit succeeds and includes the previously untracked `PortSwigger-JWT.md` content in converted form.

## Task 6: Remove Remaining Hexo Source And Update Ignore Rules

**Files:**
- Delete: `source/`
- Modify: `.gitignore`
- Optional Delete: `DEPLOY.md` if it only describes Hexo deploy.

- [ ] **Step 1: Remove old Hexo source directory**

Run:

```powershell
git rm -r -- source
```

Expected: all tracked `source/` content is staged for deletion. If untracked files remain under `source/` after Task 5, stop and inspect before deleting.

- [ ] **Step 2: Update `.gitignore` for Jekyll**

Set `.gitignore` to include:

```gitignore
.DS_Store
Thumbs.db
.jekyll-cache/
.jekyll-metadata
_site/
.sass-cache/
.bundle/
vendor/
node_modules/
*.log
.deploy*/
.superpowers/
.worktrees/
```

Remove Hexo-only ignore entries that no longer apply, such as `public/` and `db.json`, unless a specific local workflow still generates them.

- [ ] **Step 3: Review old deploy docs**

Run:

```powershell
Select-String -LiteralPath DEPLOY.md -Pattern 'Hexo|hexo|deploy'
```

If `DEPLOY.md` is Hexo-only, remove it:

```powershell
git rm DEPLOY.md
```

If it contains useful repository deployment notes, rewrite it for Jekyll with this content:

- Title: `Deployment`
- Body:
  - `This site is now a Jekyll/Chirpy site.`
  - Local build commands: `bundle install`, then `bundle exec jekyll build`
  - Local preview command: `bundle exec jekyll serve`
  - Deployment note: GitHub Pages should build from the Jekyll source branch or a GitHub Actions workflow.

- [ ] **Step 4: Commit cleanup**

Run:

```powershell
git add .gitignore DEPLOY.md
git commit -m "chore: remove hexo source files"
```

Expected: commit succeeds.

## Task 7: Dependency Installation And Jekyll Build Verification

**Files:**
- Modify: `Gemfile` only if needed to make local build work.
- Create: `Gemfile.lock` after successful `bundle install`.

- [ ] **Step 1: Check Ruby again**

Run:

```powershell
ruby -v
bundle -v
```

Expected if runtime is missing:

```text
ruby: The term 'ruby' is not recognized...
bundle: The term 'bundle' is not recognized...
```

If missing, stop this task with `BLOCKED: Ruby/Bundler not installed` and do not claim Jekyll build success.

- [ ] **Step 2: Install dependencies**

If Ruby/Bundler are available, run:

```powershell
bundle install
```

Expected: dependencies install and `Gemfile.lock` is created or updated.

- [ ] **Step 3: Build Jekyll site**

Run:

```powershell
bundle exec jekyll build
```

Expected: command exits 0 and generates `_site/`.

- [ ] **Step 4: Verify key generated pages**

Run:

```powershell
Test-Path '_site\index.html'
Test-Path '_site\posts\portswigger-ssrf\index.html'
Test-Path '_site\categories\index.html'
Test-Path '_site\tags\index.html'
Test-Path '_site\archives\index.html'
Test-Path '_site\about\index.html'
```

Expected:

```text
True
True
True
True
True
True
```

- [ ] **Step 5: Commit lockfile if generated**

Run:

```powershell
git add Gemfile Gemfile.lock
git commit -m "chore: lock jekyll dependencies"
```

Expected: commit succeeds if `Gemfile.lock` changed. If no lockfile changed, do not create an empty commit.

## Task 8: Browser Verification

**Files:**
- No planned edits. Fix only the smallest source file needed if verification finds an issue.

- [ ] **Step 1: Serve the Jekyll site**

If Ruby/Bundler are available, run:

```powershell
bundle exec jekyll serve --host 127.0.0.1 --port 4020
```

If Ruby/Bundler are missing but `_site/` exists from another verified build, serve `_site/` with:

```powershell
python -m http.server 4020 --bind 127.0.0.1
```

Expected: `http://127.0.0.1:4020/` returns HTTP 200.

- [ ] **Step 2: Verify desktop pages in browser**

Open `http://127.0.0.1:4020/` and verify:

```text
- Chirpy sidebar layout is visible.
- Site title is xidumplings.
- Search control is visible.
- Home page lists all 7 posts.
- Tabs include Categories, Tags, Archives, About.
- /posts/portswigger-ssrf/ loads.
- PortSwigger-SSRF post shows TOC and images.
```

- [ ] **Step 3: Verify categories and tags**

Open:

```text
http://127.0.0.1:4020/categories/
http://127.0.0.1:4020/tags/
```

Expected:

```text
- Web Security category exists.
- SSRF, Auth, File Upload, SQL Injection subcategories are accessible.
- Tags include jwt, portswigger, burp-suite, ssrf, file-upload, sql-injection.
```

- [ ] **Step 4: Verify mobile layout**

Use a viewport around `390x844` and verify:

```text
- No horizontal overflow.
- Sidebar/topbar behavior is usable.
- Post images scale within viewport.
- Search overlay opens and closes.
```

- [ ] **Step 5: Commit verification fixes if needed**

If source changes were required:

Stage only the files changed to fix the verification issue, then run:

```powershell
git commit -m "fix: resolve chirpy migration verification issues"
```

Expected: commit includes only verification fixes.

## Task 9: Deployment Plan Update

**Files:**
- Create or modify: `.github/workflows/pages-deploy.yml` if local Jekyll build succeeds and the user wants GitHub Actions deployment.
- Or document manual deployment blocker if Ruby/Bundler are unavailable.

- [ ] **Step 1: Inspect existing GitHub workflows**

Run:

```powershell
Get-ChildItem -Recurse -LiteralPath .github -File | Select-Object FullName
```

Expected: list existing workflows.

- [ ] **Step 2: Decide deployment mode from available runtime**

If local Jekyll build passed, add a GitHub Pages workflow based on Ruby/Bundler. If local Jekyll build is blocked by missing Ruby, do not add an unverified workflow unless the user explicitly accepts it.

- [ ] **Step 3: If adding workflow, create `.github/workflows/pages-deploy.yml`**

Use:

```yaml
name: Deploy Jekyll site to Pages

on:
  push:
    branches: ["source"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Build with Jekyll
        run: bundle exec jekyll build
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./_site
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 4: Commit deployment configuration**

Run:

```powershell
git add .github/workflows/pages-deploy.yml DEPLOY.md
git commit -m "ci: configure jekyll pages deployment"
```

Expected: commit succeeds if workflow/docs changed.

## Self-Review

- Spec coverage: the plan covers full Chirpy skeleton migration, site identity, default Chirpy routing, all 7 posts, all images, Hexo removal, Jekyll build verification, browser verification, and deployment planning.
- Runtime blocker captured: Ruby/Bundler are currently missing on this machine, so the plan forbids claiming local Jekyll build success until that is resolved.
- Placeholder scan: no `TBD`, `TODO`, `fill in`, or unspecified implementation steps remain.
- Scope check: this is a single migration project. It intentionally excludes old URL preservation, comments, analytics, and visual redesign beyond Chirpy identity configuration.
