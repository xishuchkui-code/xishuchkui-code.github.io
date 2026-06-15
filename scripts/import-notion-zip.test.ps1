param(
  [string]$ZipPath = 'E:\Blog\1111.zip'
)

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

$scriptPath = Join-Path $PSScriptRoot 'import-notion-zip.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("notion-import-test-" + [guid]::NewGuid().ToString('N'))
$blogRoot = Join-Path $tempRoot 'docs\blog'
$assetsRoot = Join-Path $tempRoot 'docs\.vuepress\public\assets\img'

try {
  & $scriptPath `
    -ZipPath $ZipPath `
    -BlogRoot $blogRoot `
    -AssetsRoot $assetsRoot `
    -Tags 'JWT','PortSwigger' `
    -Categories 'Web Security','Auth Session'

  $articlePath = Join-Path $blogRoot 'portswigger-jwt\portswigger-jwt.md'
  $assetDir = Join-Path $assetsRoot 'portswigger-jwt'
  $firstImage = Join-Path $assetDir 'portswigger-jwt-001.png'

  Assert-True (Test-Path -LiteralPath $articlePath) 'article should be written to docs/blog/<slug>/<slug>.md'
  Assert-True (Test-Path -LiteralPath $assetDir) 'asset directory should be named after the article slug'
  Assert-True (Test-Path -LiteralPath $firstImage) 'first referenced image should be renamed with a stable sequence number'

  $content = Get-Content -LiteralPath $articlePath -Raw
  $images = @(Get-ChildItem -LiteralPath $assetDir -File)

  Assert-True ($images.Count -eq 48) 'all referenced Notion images should be copied'
  Assert-True ($content -match 'title: PortSwigger-JWT') 'frontmatter should keep the original title'
  Assert-True ($content.Contains('  - JWT')) 'frontmatter should include the first provided tag'
  Assert-True ($content.Contains('  - PortSwigger')) 'frontmatter should include the second provided tag'
  Assert-True ($content.Contains('  - Web Security')) 'frontmatter should include the first provided category'
  Assert-True ($content.Contains('  - Auth Session')) 'frontmatter should include the second provided category'
  Assert-True ($content -match '/assets/img/portswigger-jwt/portswigger-jwt-001\.png') 'markdown should point at the public asset path'
  Assert-True ($content -notmatch '792a2d56-4b06-40e0-ae38-b3f730fd1ab9\.png') 'markdown should not keep Notion random image names'

  Write-Output 'import-notion-zip tests passed'
}
finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
