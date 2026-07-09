# Frontend Motion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a restrained, spring-physics-inspired CSS motion layer to the VuePress Theme Plume blog without adding runtime dependencies.

**Architecture:** Keep all changes in the existing custom stylesheet so VuePress and Theme Plume remain the source of structure. Use CSS custom properties for motion tokens, transform/opacity-based animations for performance, and `prefers-reduced-motion` as a global safety rail.

**Tech Stack:** VuePress 2, VuePress Theme Plume, static HTML output, CSS-only animation.

## Global Constraints

- Modify only `E:\Blog\xishuchkui-code.github.io\docs\.vuepress\styles\index.css` for runtime behavior.
- Do not add JavaScript or dependencies.
- Preserve the dark-first black-hole brand and long-form reading clarity.
- Every animation must have a reduced-motion fallback.
- Avoid scroll-triggered content gating; content must be visible by default.

---

### Task 1: Add motion tokens and hero entrance

**Files:**
- Modify: `E:\Blog\xishuchkui-code.github.io\docs\.vuepress\styles\index.css`

**Interfaces:**
- Consumes: existing Theme Plume classes `.vp-home-banner`, `.hero-name`, `.hero-tagline`, `.hero-text`, `.actions`.
- Produces: reusable CSS variables `--blog-ease-out`, `--blog-ease-spring`, `--blog-duration-*`.

- [ ] Add motion variables to `:root`.
- [ ] Add hero keyframes that animate transform/opacity only.
- [ ] Apply staggered entrance to hero name, tagline, text, and actions.
- [ ] Keep hero underline animation transform-only.

### Task 2: Add interaction feedback

**Files:**
- Modify: `E:\Blog\xishuchkui-code.github.io\docs\.vuepress\styles\index.css`

**Interfaces:**
- Consumes: existing Theme Plume classes `.VPButton`, `.vp-home-features`, `.vp-post-list`, `.post-cover`, profile images, nav links.
- Produces: hover/focus transitions that feel physical but remain restrained.

- [ ] Upgrade CTA hover/active feedback.
- [ ] Add feature-card and post-card lift using transform and bounded shadow changes.
- [ ] Add image hover settle without layout shift.
- [ ] Add nav/link focus transitions with visible focus states.

### Task 3: Add accessibility and verification

**Files:**
- Modify: `E:\Blog\xishuchkui-code.github.io\docs\.vuepress\styles\index.css`

**Interfaces:**
- Consumes: `prefers-reduced-motion` media query.
- Produces: disabled or near-instant animation path for motion-sensitive users.

- [ ] Add `@media (prefers-reduced-motion: reduce)` overrides.
- [ ] Run `npm run docs:build`.
- [ ] Review `git diff` for accidental generated-file edits.
