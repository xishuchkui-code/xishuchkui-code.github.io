---
name: xidumplings
description: Web 安全学习笔记、靶场复盘和漏洞研究日志。
colors:
  brand-teal-deep: "#0f766e"
  brand-teal: "#0d9488"
  brand-teal-bright: "#14b8a6"
  dark-teal-bright: "#2dd4bf"
  dark-bg: "#10141b"
  dark-surface: "#171d27"
  light-bg: "#f8fafc"
  light-surface: "#f1f5f9"
  orbit-violet: "#8b5cf6"
  signal-gold: "#ffd166"
  hero-white: "#ffffff"
typography:
  display:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "clamp(2.625rem, 8vw, 5.75rem)"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "0"
  headline:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
    fontWeight: 700
    lineHeight: 1.18
  body:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.82
  label:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
    fontWeight: 600
    lineHeight: 1.2
rounded:
  xs: "4px"
  sm: "6px"
  md: "8px"
  pill: "999px"
spacing:
  xs: "0.35rem"
  sm: "0.75rem"
  md: "1.5rem"
  lg: "18px"
  xl: "42px"
components:
  button-primary:
    backgroundColor: "{colors.brand-teal-bright}"
    textColor: "{colors.hero-white}"
    rounded: "{rounded.pill}"
    padding: "0.75rem 1.25rem"
  feature-card:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.hero-white}"
    rounded: "{rounded.md}"
    padding: "1.5rem"
  post-card:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.hero-white}"
    rounded: "{rounded.md}"
    padding: "1rem"
---

# Design System: xidumplings

## 1. Overview

**Creative North Star: "Black-Hole Lab Notebook"**

This system is a dark, evidence-first research notebook for Web security learning. The black-hole hero gives the site its atmosphere, but the interface must stay disciplined: navigation, article lists, code blocks, screenshots, tags, and archives are the working surface.

The visual voice is calm, technical, and exploratory. Teal carries trust and security, gold marks signal or discovery, and violet stays ambient, never dominant. Motion should feel spring-driven and physical: cards can lift, images can settle, and calls to action can respond, but long-form reading must remain still and clear.

The system explicitly rejects template SaaS marketing, overdone cyberpunk, generic terminal cosplay, and decorative effects that make security notes harder to read.

**Key Characteristics:**

- Dark-first, with a credible light mode inherited from VuePress Theme Plume.
- Black-hole imagery used as atmosphere, not as a repeated illustration crutch.
- Teal as the primary action/security color; gold as a rare discovery accent.
- Compact radii (4–8px) for technical seriousness; pills only for buttons, tags, and avatar rings.
- Motion as feedback and orientation, not spectacle.

## 2. Colors

The palette is a dark research surface with teal security signals, sparse gold highlights, and violet orbital ambience.

### Primary

- **Signal Teal**: Primary brand and action color. Use for active links, primary buttons, focus rings, subtle security-state emphasis, and selected navigation.
- **Bright Teal**: Dark-mode interaction color. Use when the interface needs more contrast against `dark-bg`.

### Secondary

- **Discovery Gold**: Rare accent for hero underlines, important visual cues, avatar rings in dark mode, and moments that should read as “found evidence.” Keep it below 10% of any screen.

### Tertiary

- **Orbit Violet**: Ambient background glow only. It should support the black-hole metaphor without becoming the brand color.

### Neutral

- **Event Horizon**: The dark body background. Use as the dominant environment for long reading sessions.
- **Research Surface**: Alternate dark surface for cards, post lists, profiles, and panels.
- **Cool Paper**: Light-mode body background.
- **Pale Slate**: Light-mode alternate surface.
- **Hero White**: Hero text and high-contrast foreground text on dark image backgrounds.

### Named Rules

**The Signal Rarity Rule.** Gold is evidence, not decoration. If gold appears everywhere, it stops meaning discovery.

**The Teal Means Action Rule.** Teal should primarily indicate navigation, selection, links, and actions. Do not scatter it as random ornament.

## 3. Typography

**Display Font:** Inter with system sans fallbacks  
**Body Font:** Inter with system sans fallbacks  
**Label/Mono Font:** Use the inherited theme stack; reserve monospace for code and technical literals only.

**Character:** Inter is already committed by the VuePress Theme Plume build, so identity preservation wins. The type should feel precise and readable rather than fashionably editorial.

### Hierarchy

- **Display** (700, `clamp(2.625rem, 8vw, 5.75rem)`, line-height 1): Hero name and rare landing-page statements only.
- **Headline** (700, theme scale, line-height about 1.18): Section headings, article titles, category names.
- **Title** (600–700, theme scale): Feature-card and post-card titles.
- **Body** (400, 16px, line-height 1.82): Article reading. Keep line length comfortable and never compress security walkthroughs.
- **Label** (600, compact): Nav labels, tags, category chips, metadata, and action labels.

### Named Rules

**The No Terminal Costume Rule.** Monospace belongs in code, filenames, payloads, commands, and short technical labels. Do not make the whole brand look like a terminal.

**The Long-Read Rule.** Article body text and code blocks always outrank hero drama. If a visual treatment reduces scanability, remove it.

## 4. Elevation

Depth is a hybrid of tonal layering, borders, and restrained ambient shadows. Cards can have soft depth, especially on the home page and post list, but the system must avoid heavy “ghost-card” decoration. Shadows should feel like objects resting in a dark lab, not floating marketing tiles.

### Shadow Vocabulary

- **Action Glow** (`0 14px 34px rgba(20, 184, 166, 0.22)`): Primary home CTA only.
- **Feature Ambient** (`0 18px 48px rgba(0, 0, 0, 0.24)`): Dark-mode feature cards and major panels.
- **Image Orbit** (`0 0 0 8px rgba(45, 212, 191, 0.06), 0 20px 54px rgba(15, 23, 42, 0.18)`): Important image-text media blocks.
- **Post Lift** (`0 16px 42px rgba(0, 0, 0, 0.22)`): Post cards with covers in dark mode.

### Named Rules

**The One Depth Reason Rule.** A surface may use a border, tonal contrast, or a soft shadow, but not all three at full strength.

## 5. Components

### Buttons

- **Shape:** Pill shape for CTAs and major actions (`999px` inherited from theme button behavior).
- **Primary:** Teal action color with white text; in the hero, the button may add an action glow.
- **Hover / Focus:** Use transform or glow transitions with spring-like easing. Focus must remain visible without relying on color alone.
- **Secondary / Ghost:** Keep quieter; use theme alternate button treatment with no decorative shadow.

### Chips

- **Style:** Tags and categories should remain compact, high-contrast, and semantic. Use teal for active/interactive states, not decorative tag confetti.
- **State:** Active filters must be visible in both light and dark modes.

### Cards / Containers

- **Corner Style:** Gently technical corners (`8px`) for feature cards and post cards.
- **Background:** Use `dark-surface` or `light-surface` over the page background.
- **Shadow Strategy:** Ambient shadows are allowed for home features and post cards, but should be soft and sparse.
- **Border:** Use `--vp-c-divider` for structure.
- **Internal Padding:** Follow Theme Plume spacing; avoid nested card stacks.

### Inputs / Fields

- **Style:** Search and field surfaces should inherit Theme Plume defaults, with teal focus emphasis.
- **Focus:** Must be visible in dark mode and should not rely on glow alone.
- **Error / Disabled:** Keep contrast high and copy direct.

### Navigation

- **Style:** Simple Chinese labels, direct routing, GitHub as an external anchor.
- **Default / Hover / Active:** Use teal shifts and subtle transitions. Avoid animated nav gimmicks that slow route switching.
- **Mobile:** Preserve access to 首页、博客、分类、标签、归档 and search.

### Signature Component

The home hero is the signature component: full black-hole image, dark mask, high-contrast text, compact action row, and a short gold-to-teal underline. It should feel like entering a research archive near an event horizon.

## 6. Do's and Don'ts

### Do:

- **Do** preserve the dark-first black-hole atmosphere while keeping article pages calm.
- **Do** use teal for active states, links, CTAs, and focus treatments.
- **Do** use spring-like motion for button response, card hover, image settle, and route/page transitions.
- **Do** include `prefers-reduced-motion: reduce` for every new animation.
- **Do** keep cards at `8px` radius and images at `6px` radius unless the Theme Plume component requires otherwise.
- **Do** make code, screenshots, tags, and headings easier to scan before adding decoration.

### Don't:

- **Don't** make the site look like a template SaaS landing page.
- **Don't** overdo cyberpunk: no full-screen neon, glitch spam, flashing scanlines, or motion that fights reading.
- **Don't** use monospace as a lazy shorthand for technical credibility outside code and short labels.
- **Don't** add gradient text, side-stripe card accents, or repeated tiny uppercase section eyebrows.
- **Don't** pair `border: 1px solid ...` with large soft shadows on every card.
- **Don't** block content visibility behind scroll-triggered animation classes.
