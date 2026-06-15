<#
.SYNOPSIS
Builds and publishes the blog in one command.

.DESCRIPTION
This script runs the VuePress build, refreshes the generated site files at the
repository root for GitHub Pages branch publishing, stages all changes, commits
them, and pushes to the configured remote branch.

.EXAMPLE
pwsh -File .\scripts\publish-blog.ps1 -Message "post: add jwt note"

.EXAMPLE
pwsh -File .\scripts\publish-blog.ps1 -Message "post: update blog" -PullFirst

.EXAMPLE
pwsh -File .\scripts\publish-blog.ps1 -SkipPush
#>

param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,

  [Alias('CommitMessage')]
  [string]$Message = "post: update blog $((Get-Date).ToString('yyyy-MM-dd HH:mm'))",

  [string]$Remote = 'origin',

  [string]$Branch = 'main',

  [switch]$PullFirst,

  [switch]$SkipPull,

  [switch]$SkipPush
)

$ErrorActionPreference = 'Stop'

function Get-FullPath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

function Invoke-Native {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  Write-Host ">" $FilePath ($Arguments -join ' ')
  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
  }
}

function Assert-InRepo {
  param(
    [string]$Repo,
    [string]$Path
  )

  $full = Get-FullPath $Path
  if (-not $full.StartsWith($Repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to operate outside repository: $full"
  }

  if ($full -eq $Repo) {
    throw "Refusing to remove repository root: $full"
  }

  return $full
}

$repo = Get-FullPath $RepoRoot
$dist = Join-Path $repo 'docs\.vuepress\dist'
$generatedTargets = @(
  'assets',
  'blog',
  'posts',
  '404.html',
  'index.html',
  'robots.txt',
  'sitemap.xml',
  'sitemap.xsl'
)

Push-Location $repo
try {
  if (-not (Test-Path -LiteralPath (Join-Path $repo 'package.json'))) {
    throw "package.json not found. RepoRoot does not look like this blog repository: $repo"
  }

  if ($PullFirst -and -not $SkipPull) {
    Invoke-Native git pull --ff-only $Remote $Branch
  }

  Invoke-Native npm run docs:build

  if (-not (Test-Path -LiteralPath $dist)) {
    throw "Build output not found: $dist"
  }

  foreach ($target in $generatedTargets) {
    $targetPath = Join-Path $repo $target
    if (Test-Path -LiteralPath $targetPath) {
      $safePath = Assert-InRepo -Repo $repo -Path $targetPath
      Remove-Item -LiteralPath $safePath -Recurse -Force
    }
  }

  Copy-Item -Path (Join-Path $dist '*') -Destination $repo -Recurse -Force

  $noJekyll = Join-Path $repo '.nojekyll'
  if (-not (Test-Path -LiteralPath $noJekyll)) {
    New-Item -ItemType File -Path $noJekyll -Force | Out-Null
  }

  $status = (& git status --porcelain)
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read git status.'
  }

  if (-not $status) {
    Write-Host 'No changes to publish.'
    return
  }

  Invoke-Native git add .
  Invoke-Native git commit -m $Message

  if (-not $SkipPush) {
    Invoke-Native git push $Remote $Branch
  }
  else {
    Write-Host 'SkipPush set; changes were committed locally only.'
  }
}
finally {
  Pop-Location
}
