# Deployment

This blog now uses VuePress Theme Plume.

Install dependencies:

```powershell
npm install
```

Run a local preview:

```powershell
npm run docs:dev
```

Build the static site:

```powershell
npm run docs:build
```

Import a Notion export into a custom notes directory:

```powershell
pwsh -File .\scripts\import-notion-zip.ps1 -ZipPath .\1111.zip -NotesRoot "docs/blog/Web 安全/认证与会话"
```

The build output is generated in `docs/.vuepress/dist`.

GitHub Actions deploys every push to the `main` branch with the official GitHub Pages artifact workflow.
The generated site is also committed at the repository root so GitHub Pages can serve the site directly from `main` when the repository is configured for branch publishing.
