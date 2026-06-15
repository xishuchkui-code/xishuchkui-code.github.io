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

The build output is generated in `docs/.vuepress/dist`.

GitHub Actions deploys every push to the `source` branch into the `main` branch for GitHub Pages.
