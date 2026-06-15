$ErrorActionPreference = 'Stop'

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )

  if (-not $Condition) {
    throw "ASSERTION FAILED: $Message"
  }
}

$scriptPath = Join-Path $PSScriptRoot 'publish-blog.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("publish-blog-test-" + [guid]::NewGuid().ToString('N'))
$repoRoot = Join-Path $tempRoot 'repo'
$fakeBin = Join-Path $tempRoot 'bin'
$logPath = Join-Path $tempRoot 'commands.log'

try {
  New-Item -ItemType Directory -Path $repoRoot, $fakeBin -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $repoRoot 'docs\.vuepress\dist\assets') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $repoRoot 'assets') -Force | Out-Null

  Set-Content -LiteralPath (Join-Path $repoRoot 'package.json') -Value '{"scripts":{"docs:build":"echo build"}}' -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $repoRoot 'docs\.vuepress\dist\index.html') -Value '<html>built</html>' -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $repoRoot 'docs\.vuepress\dist\assets\app.js') -Value 'console.log("new")' -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $repoRoot 'assets\old.js') -Value 'console.log("old")' -Encoding UTF8

  $fakeNpm = @"
@echo off
echo npm %*>> "$logPath"
exit /b 0
"@
  Set-Content -LiteralPath (Join-Path $fakeBin 'npm.cmd') -Value $fakeNpm -Encoding ASCII

  $fakeGit = @"
@echo off
echo git %*>> "$logPath"
if "%1"=="status" (
  echo  M index.html
)
exit /b 0
"@
  Set-Content -LiteralPath (Join-Path $fakeBin 'git.cmd') -Value $fakeGit -Encoding ASCII

  $oldPath = $env:PATH
  $env:PATH = "$fakeBin;$oldPath"
  try {
    & $scriptPath -RepoRoot $repoRoot -Message 'post: test publish' -SkipPull -SkipPush
  }
  finally {
    $env:PATH = $oldPath
  }

  $commands = Get-Content -LiteralPath $logPath -Raw

  Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot 'index.html')) 'built index.html should be copied to the repository root'
  Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot 'assets\app.js')) 'built assets should be copied to the repository root'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'assets\old.js'))) 'old generated assets should be removed before copying new dist output'
  Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot '.nojekyll')) '.nojekyll should exist for GitHub Pages branch publishing'
  Assert-True ($commands.Contains('npm run docs:build')) 'script should run the VuePress build command'
  Assert-True ($commands.Contains('git add .')) 'script should stage all blog and generated site changes'
  Assert-True ($commands.Contains('git commit -m')) 'script should create a git commit'
  Assert-True ($commands.Contains('post: test publish')) 'script should commit using the provided message'
  Assert-True (-not $commands.Contains('git push')) 'script should not push when -SkipPush is set'

  Write-Output 'publish-blog tests passed'
}
finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
