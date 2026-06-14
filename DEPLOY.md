# Deployment

This site is now a Jekyll/Chirpy site.

Local build:

```powershell
bundle install
bundle exec jekyll build
```

Local preview:

```powershell
bundle exec jekyll serve
```

GitHub Pages deployment should build from the Jekyll source branch or a GitHub Actions workflow.

Note: this machine currently needs Ruby and Bundler installed before local Jekyll build and preview commands can run.
