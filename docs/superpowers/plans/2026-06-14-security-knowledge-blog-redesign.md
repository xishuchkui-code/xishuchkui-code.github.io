# Security Knowledge Blog Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the Hexo/Fluid blog into a clean security knowledge base with stable category paths, working local search, concise navigation, and organized article metadata.

**Architecture:** Keep the current Hexo 8 + Fluid theme rather than replacing the theme. Use Hexo config for site metadata, routing, search, and category URL mapping; use Fluid config for navigation and page presentation; use a small custom stylesheet for the knowledge-base visual tone; update post front matter to implement the approved information architecture.

**Tech Stack:** Hexo 8, hexo-theme-fluid, hexo-generator-category/tag/archive/index, hexo-generator-search, Markdown front matter, CSS.

---

## File Structure

- Modify `_config.yml`: site description, default category, and `category_map` for stable category URLs.
- Modify `package.json` and `package-lock.json`: add `hexo-generator-search` so Fluid local search has a generated index.
- Modify `_config.fluid.yml`: compact navigation, lighter color tokens, custom CSS registration, shorter home/post/category banner heights, about text.
- Create `source/css/security-knowledge.css`: small focused style layer for the knowledge-base look.
- Modify `source/_posts/*.md`: front matter categories, tags, descriptions, and optional sticky values.
- Create optional category landing pages only if generated category pages cannot be linked cleanly after build. The first pass should try generated category pages with `category_map`.
- Do not modify or delete `source/img/**` except through normal references from existing Markdown.
- Do not discard untracked `source/_posts/PortSwigger-JWT.md` or `source/img/PortSwigger-JWT/`.

## Task 1: Confirm Fluid Local Search And Baseline Build Check

**Files:**
- No source edits expected. Modify `package.json` and `package-lock.json` only if Fluid's built-in search generator is absent or broken.

- [ ] **Step 1: Confirm Fluid's local search generator exists**

Run:

```powershell
Test-Path node_modules\hexo-theme-fluid\scripts\generators\local-search.js
```

Expected: outputs `True`.

- [ ] **Step 2: Run a clean build**

Run:

```powershell
npm run clean
npm run build
```

Expected: Hexo generation succeeds.

- [ ] **Step 3: Confirm the search output is correct**

Run:

```powershell
Test-Path public\local-search.xml
Test-Path public\search.xml
npm ls hexo-generator-search --depth=0
```

Expected:

```text
True
False
```

The `npm ls` command exits non-zero with `(empty)`, confirming the redundant external search generator is not installed.

- [ ] **Step 4: Commit only if a dependency correction was needed**

If `hexo-generator-search` had been installed and removed, run:

```powershell
git add package.json package-lock.json
git commit -m "chore: rely on Fluid local search generator"
```

Expected: commit succeeds and only dependency files are included. If no dependency correction was needed, leave this task with no commit.

## Task 2: Configure Site Metadata, Category Paths, And Fluid Navigation

**Files:**
- Modify: `_config.yml`
- Modify: `_config.fluid.yml`

- [ ] **Step 1: Update core site metadata and category URL mapping**

Edit `_config.yml` so the relevant section reads:

```yaml
title: xidumplings
subtitle: 'Web 安全笔记库'
description: '记录 Web 安全学习、靶场实验、漏洞原理和工具环境配置。'
keywords:
author: xidumplings
language: zh-CN
timezone: 'Asia/Shanghai'
```

Edit the category section to read:

```yaml
# Category & Tag
default_category: Web 安全
category_map:
  Web 安全: web-security
  基础概念: fundamentals
  认证与会话: auth-session
  SQL 注入: sql-injection
  文件上传: file-upload
  SSRF: ssrf
  靶场记录: labs
  PortSwigger: portswigger
  工具与环境: tools-env
  Burp Suite: burp-suite
  VS Code: vscode
  Windows: windows
  生活随笔: life
tag_map:
```

- [ ] **Step 2: Update Fluid color tokens**

In `_config.fluid.yml`, update the `color:` block values to:

```yaml
color:
  body_bg_color: "#f7f9fb"
  body_bg_color_dark: "#141820"
  navbar_bg_color: "#ffffff"
  navbar_bg_color_dark: "#151a22"
  navbar_text_color: "#1f2937"
  navbar_text_color_dark: "#d9e2ec"
  subtitle_color: "#4b5563"
  subtitle_color_dark: "#b6c2cf"
  text_color: "#1f2937"
  text_color_dark: "#d9e2ec"
  sec_text_color: "#667085"
  sec_text_color_dark: "#aab6c5"
  post_text_color: "#26323f"
  post_text_color_dark: "#d5dbe5"
  post_heading_color: "#111827"
  post_heading_color_dark: "#f2f5f8"
  post_link_color: "#0f766e"
  post_link_color_dark: "#2dd4bf"
  link_hover_color: "#0f766e"
  link_hover_color_dark: "#5eead4"
  board_color: "#ffffff"
  board_color_dark: "#1b2230"
```

If the existing block contains additional color keys not listed here, keep them unless they visibly conflict with the knowledge-base palette.

- [ ] **Step 3: Register the custom stylesheet**

Set the custom CSS section in `_config.fluid.yml` to:

```yaml
custom_css:
  - /css/security-knowledge.css
```

- [ ] **Step 4: Replace the navbar menu**

Set `_config.fluid.yml` `navbar.menu` to:

```yaml
  menu:
    - { key: "home", link: "/", icon: "iconfont icon-home-fill", name: "首页" }
    - { key: "web-security", link: "/categories/web-security/", icon: "iconfont icon-category-fill", name: "Web 安全" }
    - { key: "labs", link: "/tags/PortSwigger/", icon: "iconfont icon-bookmark-fill", name: "靶场记录" }
    - { key: "tools", link: "/categories/tools-env/", icon: "iconfont icon-code", name: "工具与环境" }
    - { key: "archive", link: "/archives/", icon: "iconfont icon-archive-fill", name: "归档" }
    - { key: "tag", link: "/tags/", icon: "iconfont icon-tags-fill", name: "标签" }
    - { key: "about", link: "/about/", icon: "iconfont icon-user-fill", name: "关于" }
```

If an icon class does not render after visual verification, keep the nav label and change only the icon class to an existing Fluid icon.

- [ ] **Step 5: Reduce banner heights**

Set these values in `_config.fluid.yml`:

```yaml
index:
  banner_img: /img/default.png
  banner_img_height: 42
  banner_mask_alpha: 0.15

post:
  banner_img: /img/default.png
  banner_img_height: 36
  banner_mask_alpha: 0.18

archive:
  banner_img_height: 30
  banner_mask_alpha: 0.12

category:
  banner_img_height: 30
  banner_mask_alpha: 0.12
  collapse_depth: 1
  post_order_by: "-date"
  post_limit: 20

tag:
  banner_img_height: 30
  banner_mask_alpha: 0.12

about:
  banner_img_height: 30
  banner_mask_alpha: 0.12
```

Preserve other existing keys in each block.

- [ ] **Step 6: Update about identity copy**

Set `_config.fluid.yml` about values to:

```yaml
about:
  avatar: /img/xiaoye.jpg
  name: "xidumplings"
  intro: "Web 安全学习笔记、靶场复盘和工具记录。"
```

- [ ] **Step 7: Build after config edits**

Run:

```powershell
npm run build
```

Expected: build succeeds and generated paths include category URLs under `public/categories/web-security/`.

- [ ] **Step 8: Commit config changes**

Run:

```powershell
git add _config.yml _config.fluid.yml
git commit -m "feat: configure security knowledge blog navigation"
```

Expected: commit succeeds with only config files.

## Task 3: Add Knowledge-Base Custom Styling

**Files:**
- Create: `source/css/security-knowledge.css`
- Modify: `_config.fluid.yml` only if Task 2 did not already register the stylesheet.

- [ ] **Step 1: Create the stylesheet**

Create `source/css/security-knowledge.css` with:

```css
:root {
  --sk-accent: #0f766e;
  --sk-accent-soft: rgba(15, 118, 110, 0.09);
  --sk-border: rgba(31, 41, 55, 0.1);
  --sk-text: #1f2937;
  --sk-muted: #667085;
}

body {
  letter-spacing: 0;
}

.navbar {
  box-shadow: 0 1px 0 rgba(31, 41, 55, 0.08);
}

.navbar-brand,
.navbar-nav .nav-link {
  font-weight: 600;
}

.banner {
  background-position: center;
}

.banner .h2,
.banner h1 {
  letter-spacing: 0;
}

.index-card {
  border: 1px solid var(--sk-border);
  border-radius: 8px;
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.index-card .post-meta,
.post-metas,
.category-list-count,
.tagcloud a {
  color: var(--sk-muted);
}

.index-card .index-header .index-title a:hover,
.markdown-body a {
  color: var(--sk-accent);
}

.markdown-body {
  color: var(--sk-text);
  line-height: 1.82;
}

.markdown-body h2 {
  border-bottom: 1px solid var(--sk-border);
  padding-bottom: 0.35rem;
}

.markdown-body h3 {
  margin-top: 1.8rem;
}

.markdown-body img {
  border: 1px solid var(--sk-border);
  border-radius: 6px;
}

.markdown-body code {
  border-radius: 4px;
}

.tocbot-list a:hover,
.tocbot-active-link {
  color: var(--sk-accent);
}

.category-list a,
.tagcloud a {
  border-radius: 6px;
}

.category-list a:hover,
.tagcloud a:hover {
  background: var(--sk-accent-soft);
  color: var(--sk-accent);
  text-decoration: none;
}

@media (max-width: 767px) {
  .index-card {
    border-radius: 6px;
  }

  .markdown-body {
    line-height: 1.75;
  }
}
```

- [ ] **Step 2: Verify stylesheet is emitted**

Run:

```powershell
npm run build
Test-Path public/css/security-knowledge.css
```

Expected: first command succeeds; second command outputs `True`.

- [ ] **Step 3: Commit stylesheet**

Run:

```powershell
git add source/css/security-knowledge.css _config.fluid.yml
git commit -m "style: add security knowledge base polish"
```

Expected: commit succeeds.

## Task 4: Normalize Existing Post Front Matter

**Files:**
- Modify: `source/_posts/JWT介绍与原理.md`
- Modify: `source/_posts/PortSwigger-JWT.md`
- Modify: `source/_posts/PortSwigger-SSRF.md`
- Modify: `source/_posts/文件上传漏洞.md`
- Modify: `source/_posts/PortSwigger-文件上传漏洞.md`
- Modify: `source/_posts/带条件错误的盲SQL注入.md`
- Modify: `source/_posts/自我介绍-开启我的博客之旅.md`

- [ ] **Step 1: Update `JWT介绍与原理.md` front matter**

Use:

```yaml
---
title: JWT介绍与原理
date: 2026-03-31 11:07:59
categories:
  - Web 安全
  - 认证与会话
tags:
  - JWT
  - 认证
  - Token
description: 梳理 JWT 的组成、签名验证、常见风险和安全使用边界。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 2: Update `PortSwigger-JWT.md` front matter**

Use:

```yaml
---
title: PortSwigger-JWT
date: 2026-04-03 14:57:21
categories:
  - Web 安全
  - 认证与会话
tags:
  - JWT
  - PortSwigger
  - Burp Suite
description: 记录 PortSwigger JWT 相关实验的解题过程、关键请求和验证思路。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 3: Update `PortSwigger-SSRF.md` front matter**

Use:

```yaml
---
title: PortSwigger-SSRF
date: 2026-02-17 16:38:37
categories:
  - Web 安全
  - SSRF
tags:
  - SSRF
  - PortSwigger
  - Burp Suite
description: 记录 PortSwigger SSRF 靶场的抓包分析、payload 构造和实验复盘。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 4: Update `文件上传漏洞.md` front matter**

Use:

```yaml
---
title: 文件上传漏洞
date: 2025-11-25 17:31:05
categories:
  - Web 安全
  - 文件上传
tags:
  - 文件上传
  - Web 安全
description: 梳理文件上传漏洞的基础原理、常见校验点和绕过思路。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 5: Update `PortSwigger-文件上传漏洞.md` front matter**

Use:

```yaml
---
title: PortSwigger-文件上传漏洞
date: 2025-12-09 17:31:31
categories:
  - Web 安全
  - 文件上传
tags:
  - 文件上传
  - PortSwigger
  - Burp Suite
description: 记录 PortSwigger 文件上传漏洞实验的请求分析、绕过方式和复盘要点。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 6: Update `带条件错误的盲SQL注入.md` front matter**

Use:

```yaml
---
title: 带条件错误的盲SQL注入
date: 2025-12-06 10:59:48
categories:
  - Web 安全
  - SQL 注入
tags:
  - SQL 注入
  - 盲注
description: 记录带条件错误回显的盲 SQL 注入判断方法和实验过程。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 7: Update `自我介绍-开启我的博客之旅.md` front matter**

Use:

```yaml
---
title: 自我介绍 - 开启我的博客之旅 - Hello World!
date: 2025-11-19 12:05:44
tags:
  - 随笔
  - 自我介绍
categories:
  - 生活随笔
description: 关于 xidumplings 和这个笔记博客的起点。
index_img:
banner_img: /img/default.png
---
```

Preserve the article body exactly.

- [ ] **Step 8: Build after front matter changes**

Run:

```powershell
npm run build
```

Expected: build succeeds with no YAML parsing errors.

- [ ] **Step 9: Commit post metadata changes**

Run:

```powershell
git add source/_posts/JWT介绍与原理.md source/_posts/PortSwigger-JWT.md source/_posts/PortSwigger-SSRF.md source/_posts/文件上传漏洞.md source/_posts/PortSwigger-文件上传漏洞.md source/_posts/带条件错误的盲SQL注入.md source/_posts/自我介绍-开启我的博客之旅.md
git commit -m "content: organize posts into security knowledge categories"
```

Expected: commit succeeds and image files are not staged.

## Task 5: Verify Local Site Rendering And Search

**Files:**
- No planned source edits. Fix only the smallest source file needed if verification finds a real issue.

- [ ] **Step 1: Run a clean production build**

Run:

```powershell
npm run clean
npm run build
```

Expected: build succeeds.

- [ ] **Step 2: Confirm key generated artifacts**

Run:

```powershell
Test-Path public/local-search.xml
Test-Path public/categories/web-security/index.html
Test-Path public/tags/PortSwigger/index.html
Test-Path public/archives/index.html
```

Expected: each command outputs `True`.

- [ ] **Step 3: Start the Hexo local server**

Run:

```powershell
npm run server
```

Expected: Hexo serves the site on a localhost URL, usually `http://localhost:4000/`. Keep the server running for browser verification.

- [ ] **Step 4: Browser desktop verification**

Open the site in the Browser plugin at `http://localhost:4000/` and verify:

```text
Home page:
- Navigation labels show 首页, Web 安全, 靶场记录, 工具与环境, 归档, 标签, 关于.
- Article list is readable and concise.
- Search entry is visible.
- No broken default-looking oversized hero dominates the first viewport.

Category/tag pages:
- /categories/web-security/ loads.
- /tags/PortSwigger/ loads.
- Posts appear under the expected category/tag.

Post page:
- Open /PortSwigger-SSRF/ or the generated equivalent.
- TOC renders.
- Screenshots load.
- Code blocks and paragraphs are readable.
```

- [ ] **Step 5: Browser mobile verification**

Use a mobile viewport around `390x844` and verify:

```text
- Navbar collapses or wraps without overlap.
- Article cards do not overflow horizontally.
- Post screenshots scale within the viewport.
- Search UI opens without blocking the page permanently.
```

- [ ] **Step 6: Commit verification fixes if needed**

If a small fix was required, commit it:

```powershell
git add <changed-files>
git commit -m "fix: resolve blog rendering verification issues"
```

Expected: commit includes only files needed for the verified fix.

## Self-Review

- Spec coverage: the plan covers Fluid-based implementation, Fluid local search verification, navigation, category/tag architecture, existing article mapping, custom visual polish, and build/browser verification.
- Placeholder scan: no `TBD`, `TODO`, `implement later`, or unspecified test steps remain.
- Scope check: the plan avoids full theme replacement, body-content rewrites, deployment, comments, and large SEO work.
- Worktree safety: the plan explicitly preserves untracked JWT files and avoids image deletion.
