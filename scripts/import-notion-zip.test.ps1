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
$notesRoot = Join-Path $tempRoot 'custom-notes\Security Notes'
$assetsRoot = Join-Path $tempRoot 'docs\.vuepress\public\assets\img'
$fixtureInner = Join-Path $tempRoot 'fixture-inner'
$fixtureOuter = Join-Path $tempRoot 'fixture-outer'
$innerZip = Join-Path $fixtureOuter 'ExportBlock-test-Part-1.zip'
$outerZip = Join-Path $tempRoot 'notion-export.zip'

try {
  New-Item -ItemType Directory -Path $fixtureInner, $fixtureOuter -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $fixtureInner 'Test Article 0123456789abcdef0123456789abcdef.md') -Value @'
# Test Article

Intro paragraph.

![](a-random-image-name.png)

More notes.

![](b-random-image-name.png)
'@ -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $fixtureInner 'a-random-image-name.png') -Value 'fake image 1' -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $fixtureInner 'b-random-image-name.png') -Value 'fake image 2' -Encoding UTF8
  Compress-Archive -Path (Join-Path $fixtureInner '*') -DestinationPath $innerZip -Force
  Compress-Archive -Path $innerZip -DestinationPath $outerZip -Force

  & $scriptPath `
    -ZipPath $outerZip `
    -NotesRoot $notesRoot `
    -AssetsRoot $assetsRoot `
    -Tags 'Notion','Example' `
    -Categories 'Web Security','Auth Session'

  $articlePath = Join-Path $notesRoot 'test-article\test-article.md'
  $assetDir = Join-Path $assetsRoot 'test-article'
  $firstImage = Join-Path $assetDir 'test-article-001.png'

  Assert-True (Test-Path -LiteralPath $articlePath) 'article should be written under the custom notes root'
  Assert-True (Test-Path -LiteralPath $assetDir) 'asset directory should be named after the article slug'
  Assert-True (Test-Path -LiteralPath $firstImage) 'first referenced image should be renamed with a stable sequence number'

  $content = Get-Content -LiteralPath $articlePath -Raw
  $images = @(Get-ChildItem -LiteralPath $assetDir -File)

  Assert-True ($images.Count -eq 2) 'all referenced Notion images should be copied'
  Assert-True ($content -match 'title: Test Article') 'frontmatter should keep the original title'
  Assert-True ($content.Contains('  - Notion')) 'frontmatter should include the first provided tag'
  Assert-True ($content.Contains('  - Example')) 'frontmatter should include the second provided tag'
  Assert-True ($content.Contains('  - Web Security')) 'frontmatter should include the first provided category'
  Assert-True ($content.Contains('  - Auth Session')) 'frontmatter should include the second provided category'
  Assert-True ($content -match '/assets/img/test-article/test-article-001\.png') 'markdown should point at the public asset path'
  Assert-True ($content -match '/assets/img/test-article/test-article-002\.png') 'markdown should keep image links independent from the custom notes root'
  Assert-True (-not $content.Contains($notesRoot)) 'markdown image links should not point at the local notes directory'
  Assert-True ($content -notmatch 'a-random-image-name\.png') 'markdown should not keep Notion random image names'

  Write-Output 'import-notion-zip tests passed'
}
finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
