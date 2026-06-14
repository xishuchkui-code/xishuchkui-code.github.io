# Security Knowledge Blog Redesign

Date: 2026-06-14

## Goal

Turn the current Hexo note blog into a security knowledge blog inspired by the clear, document-style reading experience of `https://cuanmu.com/blog/`.

The redesign should keep the site lightweight and easy to maintain while making the notes easier to browse, search, and expand over time.

## Current Context

The site is a Hexo 8 blog using the Fluid theme.

Relevant files:

- `_config.yml` controls Hexo site metadata, permalink, generators, and theme selection.
- `_config.fluid.yml` controls Fluid theme navigation, search, home page, post pages, category pages, tag pages, and about page.
- `source/_posts/` contains the note articles.
- `source/img/` contains article images.

Existing content is mostly web security learning notes:

- JWT basics and PortSwigger JWT labs
- SSRF PortSwigger labs
- File upload vulnerability notes and PortSwigger labs
- Blind SQL injection note
- Introductory personal post

There are currently untracked JWT content files in the worktree. Implementation must not discard or overwrite those files.

## Selected Direction

Use the "security knowledge base" direction.

The site should feel like a clean technical note library:

- Compact top navigation
- Prominent local search entry
- Clear category and tag browsing
- Article list focused on title, category, tags, date, reading time, and summary
- Minimal decorative imagery
- Strong reading layout for long lab notes with many screenshots

The visual reference is the document-blog structure of cuanmu: top navigation, search, readable article list, category/tag/archive utilities, and concise metadata. The implementation should not copy branding or content from the reference site.

## Information Architecture

Use a two-level structure:

- Categories describe the article's place in the knowledge system.
- Tags describe source, tool, platform, technique, and fine-grained keywords.

### Category Model

Initial category tree:

```text
Web 安全
  - 基础概念
  - 认证与会话
  - SQL 注入
  - 文件上传
  - SSRF

靶场记录
  - PortSwigger

工具与环境
  - Burp Suite
  - VS Code
  - Windows

生活随笔
```

For the first implementation pass, existing security posts should use knowledge-domain categories such as `Web 安全 / SSRF`, with `PortSwigger` as a tag when the article is a lab walkthrough. This keeps knowledge browsing primary and source filtering available through tags.

### Tag Rules

Tags should be used for:

- Source: `PortSwigger`
- Tools: `Burp Suite`
- Vulnerability aliases: `JWT`, `SSRF`, `文件上传`, `SQL 注入`
- Workflow terms when useful: `payload`, `抓包`, `绕过`

Avoid using generic tags such as `学习笔记` when the category already expresses that purpose.

## Existing Article Mapping

Apply this mapping unless the user asks to revise it:

```text
JWT介绍与原理
  categories: Web 安全 / 认证与会话
  tags: JWT, 认证, Token

PortSwigger-JWT
  categories: Web 安全 / 认证与会话
  tags: JWT, PortSwigger, Burp Suite

PortSwigger-SSRF
  categories: Web 安全 / SSRF
  tags: SSRF, PortSwigger, Burp Suite

文件上传漏洞
  categories: Web 安全 / 文件上传
  tags: 文件上传, Web 安全

PortSwigger-文件上传漏洞
  categories: Web 安全 / 文件上传
  tags: 文件上传, PortSwigger, Burp Suite

带条件错误的盲SQL注入
  categories: Web 安全 / SQL 注入
  tags: SQL 注入, 盲注

自我介绍 - 开启我的博客之旅 - Hello World!
  categories: 生活随笔
  tags: 自我介绍, 随笔
```

## Navigation Design

Top navigation should prioritize knowledge browsing:

```text
首页
Web 安全
靶场记录
工具与环境
归档
标签
关于
```

Search should remain enabled and easy to discover. If the current Fluid local search setup is missing its generator dependency, add the required dependency during implementation or disable the search UI until the generator is present. Do not leave a broken search entry.

## Home Page Design

The home page should become a knowledge-library entry point rather than a personal landing page.

It should include:

- A compact header/banner with the blog name and short subtitle.
- A small set of knowledge entry links for `Web 安全`, `靶场记录`, and `工具与环境`.
- A recent articles list with title, summary, category, tags, date, and reading time.
- Pinned or important posts can remain supported through Fluid's sticky feature.

Avoid oversized hero imagery, decorative card-heavy sections, and generic marketing copy.

## Post Page Design

Post pages should optimize for long technical reading:

- Keep article content width comfortable for Chinese text and screenshots.
- Keep table of contents enabled.
- Keep category sidebar available when useful.
- Make code blocks and images readable.
- Keep post metadata visible but compact.
- Use consistent default banner/cover behavior so posts do not look image-heavy unless a specific article needs a cover.

## Theme Implementation Scope

Prefer using Fluid configuration and light custom styling over replacing the entire theme.

Likely implementation areas:

- `_config.yml`: site title, description, default category, and generator behavior if needed.
- `_config.fluid.yml`: navbar menu, colors, index behavior, post/category/tag/about settings, banner imagery, search behavior.
- `source/_posts/*.md`: front matter category/tag cleanup and descriptions.
- Optional custom CSS through Fluid's supported custom injection mechanism if configuration alone cannot achieve the desired list density and knowledge-base feel.
- Optional category landing pages only if Fluid's generated category pages are not enough.

## Visual System

Use a restrained technical-note style:

- Background: true white or very light neutral.
- Text: high-contrast dark neutral.
- Accent: a sober blue, cyan, or green accent suitable for security notes.
- Navigation: compact and readable.
- Cards: use only for repeated article or category items when Fluid requires them; avoid nested cards.
- Radius: small, no oversized rounded panels.
- Typography: system Chinese-friendly sans-serif for UI, readable article typography for content.

The site should feel practical, searchable, and calm rather than decorative.

## Testing And Verification

Implementation should verify:

- `npm run build` or equivalent Hexo generation succeeds.
- Local server renders the home page, post page, category page, tag page, archive page, and about page.
- Search is either working or intentionally disabled with no broken UI.
- Existing images in posts still load.
- Mobile layout does not overflow.
- Desktop layout keeps the article list and post body readable.
- No user-created untracked notes are deleted or overwritten.

## Out Of Scope For First Pass

- Full theme replacement.
- Comment system changes.
- Deploying to GitHub Pages.
- Rewriting article body content beyond front matter cleanup.
- Large SEO or analytics work.
- Creating many new articles.

## Open Decisions

No blocking decisions remain for the first implementation plan. The accepted direction is:

- Security knowledge base style
- Two-level category model
- Knowledge-domain categories with source/tool tags
- Fluid-based implementation unless a concrete theme limitation appears
