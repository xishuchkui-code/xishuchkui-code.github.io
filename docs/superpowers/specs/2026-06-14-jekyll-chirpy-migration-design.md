# Jekyll Chirpy Migration Design

Date: 2026-06-14

## Goal

Fully migrate the current Hexo/Fluid blog to a Jekyll site based on the downloaded Chirpy theme at:

```text
E:\Blog\jekyll-theme-chirpy-7.5.0
```

The target site should use Chirpy's native structure, layouts, routes, search, tags, categories, archive pages, table of contents, dark mode, and default post permalink pattern.

## Current Context

The current repository is a Hexo site on branch `source`.

Important current state:

- The branch is ahead of `origin/source` with recent local Hexo/Fluid redesign commits.
- The deployed GitHub Pages branch is `main`.
- `source/_posts/PortSwigger-JWT.md` and `source/img/PortSwigger-JWT/` are untracked but should be included in the migration.
- There are 7 posts to migrate:
  - `JWT介绍与原理.md`
  - `PortSwigger-JWT.md`
  - `PortSwigger-SSRF.md`
  - `PortSwigger-文件上传漏洞.md`
  - `文件上传漏洞.md`
  - `带条件错误的盲SQL注入.md`
  - `自我介绍-开启我的博客之旅.md`

## Selected Direction

Use a full Jekyll/Chirpy migration.

Do not keep Hexo as the build system. Do not keep Fluid as a theme. Do not attempt to mimic Chirpy inside Hexo.

The migrated repository should be a standard Jekyll Chirpy project:

- `Gemfile`
- `_config.yml`
- `_posts/`
- `_tabs/`
- `_data/`
- `_layouts/`
- `_includes/`
- `_sass/`
- `assets/`
- Jekyll/Chirpy supporting files

## Routing

Use Chirpy's default permalink style:

```yaml
permalink: /posts/:title/
```

Old Hexo URLs do not need to be preserved. The user explicitly chose a complete migration to Chirpy defaults.

## Site Identity

Configure Chirpy for the existing blog identity:

```yaml
lang: zh-CN
timezone: Asia/Shanghai
title: xidumplings
tagline: Web 安全笔记库
description: 记录 Web 安全学习、靶场实验、漏洞原理和工具环境配置。
url: https://xishuchkui-code.github.io
github.username: xishuchkui-code
social.name: xidumplings
```

Comments and analytics should stay disabled unless the user asks for them later.

Use local assets rather than Chirpy's demo CDN for avatar and preview images. The existing image `source/img/xiaoye.jpg` should become the sidebar avatar if it is available.

## Content Model

Use Chirpy/Jekyll front matter.

Chirpy categories should use one or two values:

```yaml
categories: [Web Security, SSRF]
```

Tags should be lowercase and URL-friendly:

```yaml
tags: [ssrf, portswigger, burp-suite]
```

### Post Mapping

```text
JWT介绍与原理
  categories: [Web Security, Auth]
  tags: [jwt, auth, token]

PortSwigger-JWT
  categories: [Web Security, Auth]
  tags: [jwt, portswigger, burp-suite]

PortSwigger-SSRF
  categories: [Web Security, SSRF]
  tags: [ssrf, portswigger, burp-suite]

文件上传漏洞
  categories: [Web Security, File Upload]
  tags: [file-upload, web-security]

PortSwigger-文件上传漏洞
  categories: [Web Security, File Upload]
  tags: [file-upload, portswigger, burp-suite]

带条件错误的盲SQL注入
  categories: [Web Security, SQL Injection]
  tags: [sql-injection, blind-sql]

自我介绍 - 开启我的博客之旅 - Hello World!
  categories: [Life]
  tags: [intro, notes]
```

## Post File Names

Move posts from Hexo's `source/_posts/` into Jekyll's `_posts/`.

Use Jekyll's required date-prefixed filenames:

```text
_posts/2026-03-31-jwt-introduction.md
_posts/2026-04-03-portswigger-jwt.md
_posts/2026-02-17-portswigger-ssrf.md
_posts/2025-12-09-portswigger-file-upload.md
_posts/2025-11-25-file-upload.md
_posts/2025-12-06-conditional-error-blind-sql-injection.md
_posts/2025-11-19-hello-world.md
```

Set front matter titles to preserve the visible Chinese/current article titles.

Dates should include timezone:

```yaml
date: 2026-02-17 16:38:37 +0800
```

## Images And Assets

Move current image assets from:

```text
source/img/
```

to:

```text
assets/img/
```

Convert post image links from Hexo relative paths such as:

```markdown
![](../img/PortSwigger-SSRF/example.png)
```

to Chirpy/Jekyll site-root asset paths:

```markdown
![](/assets/img/PortSwigger-SSRF/example.png)
```

Keep image filenames unchanged.

## What To Remove Or Ignore

After migration, Hexo-specific files should no longer drive the site:

- `_config.fluid.yml`
- `_config.landscape.yml`
- `themes/`
- `scaffolds/`
- Hexo-specific `package.json` and `package-lock.json`
- `source/`
- `public/`
- `.deploy_git/`
- `db.json`

If safe, remove these from the repository. For large generated directories such as `public/`, `.deploy_git/`, and `node_modules/`, they should remain ignored and not committed.

## Deployment

The source branch should become a Jekyll/Chirpy source branch.

Deployment should use one of these:

1. GitHub Pages building Jekyll from the repository source branch.
2. A GitHub Action generated from Chirpy's recommended workflow.
3. Local `bundle exec jekyll build` followed by a manual publish step.

The first implementation should verify local build before changing deployment. If GitHub Pages settings are unknown, document the required next step rather than guessing.

## Verification

The migration is acceptable only when:

- Dependencies install successfully.
- Jekyll builds locally.
- The local site renders with Chirpy layout.
- Home, post, categories, tags, archives, and about pages load.
- Search assets are generated.
- All 7 posts appear.
- Existing post images render.
- Mobile layout does not overflow.
- The generated site no longer depends on Hexo.
- The old Hexo build commands are replaced or removed.

## Out Of Scope

- Preserving old Hexo URLs.
- Keeping Fluid-specific styling.
- Adding comments or analytics.
- Rewriting article body content beyond image path conversion and front matter migration.
- Redesigning Chirpy beyond basic site identity and content migration.

## Risks

- Ruby/Bundler may not be installed locally. If missing, implementation should report the exact missing dependency.
- Chirpy 7.5.0 may expect theme gem behavior that differs from a copied theme-source project. Implementation should prefer the downloaded project's existing structure and verify with `bundle exec jekyll build`.
- GitHub Pages deployment settings may need adjustment after local migration.
- The source branch currently has local commits not pushed to `origin/source`; migration work should account for this and avoid losing recent changes.
