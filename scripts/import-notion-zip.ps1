<#
.SYNOPSIS
Imports a two-layer Notion Markdown export zip into this Plume blog.

.DESCRIPTION
The importer expects a Notion export where the outer zip contains an inner zip,
and the inner zip contains one or more Markdown files plus images in the same
directory. Each Markdown file is imported into <notes-root>/<slug>/<slug>.md,
while its referenced images are copied to docs/.vuepress/public/assets/img/<slug>/
and renamed in reading order.

.EXAMPLE
pwsh -File .\scripts\import-notion-zip.ps1 -ZipPath E:\Blog\1111.zip -Tags JWT,PortSwigger -Categories "Web 安全","认证与会话"

.EXAMPLE
pwsh -File .\scripts\import-notion-zip.ps1 -ZipPath .\1111.zip -NotesRoot "docs/blog/Web 安全/认证与会话"

.EXAMPLE
pwsh -File .\scripts\import-notion-zip.ps1 -ZipPath .\1111.zip -Force
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$ZipPath,

  [Alias('NotesRoot', 'NoteRoot', 'ArticleRoot')]
  [string]$BlogRoot = 'docs/blog',

  [string]$AssetsRoot = 'docs/.vuepress/public/assets/img',

  [string]$PublicAssetsBase = '/assets/img',

  [string[]]$Tags = @('Notion'),

  [string[]]$Categories = @('Notion 导入'),

  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-AbsolutePath {
  param([string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

function ConvertTo-Slug {
  param([string]$Text)

  $slug = $Text.Trim().ToLowerInvariant()
  $slug = [regex]::Replace($slug, '\s+[0-9a-f]{32}$', '')
  $slug = [regex]::Replace($slug, '[^\p{L}\p{Nd}]+', '-')
  $slug = $slug.Trim('-')

  if ([string]::IsNullOrWhiteSpace($slug)) {
    return "notion-import-$((Get-Date).ToString('yyyyMMddHHmmss'))"
  }

  return $slug
}

function Remove-NotionHashSuffix {
  param([string]$Text)

  return ([regex]::Replace($Text.Trim(), '\s+[0-9a-fA-F]{32}$', '')).Trim()
}

function Normalize-List {
  param([string[]]$Values)

  $result = New-Object System.Collections.Generic.List[string]
  foreach ($value in $Values) {
    foreach ($part in ($value -split ',')) {
      $trimmed = $part.Trim()
      if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
        $result.Add($trimmed)
      }
    }
  }

  return @($result)
}

function ConvertTo-YamlScalar {
  param([string]$Value)

  if ($Value -match '^[\p{L}\p{Nd}_ ./:-]+$') {
    return $Value
  }

  return "'$($Value -replace "'", "''")'"
}

function Get-TitleFromMarkdown {
  param(
    [string]$Content,
    [string]$Fallback
  )

  $match = [regex]::Match($Content, '(?m)^\s*#\s+(.+?)\s*$')
  if ($match.Success) {
    return $match.Groups[1].Value.Trim()
  }

  return $Fallback
}

function Expand-NotionZip {
  param(
    [string]$SourceZip,
    [string]$Destination
  )

  Expand-Archive -LiteralPath $SourceZip -DestinationPath $Destination -Force

  $mdFiles = @(Get-ChildItem -LiteralPath $Destination -Recurse -Force -File -Filter '*.md')
  if ($mdFiles.Count -gt 0) {
    return $Destination
  }

  $innerZips = @(Get-ChildItem -LiteralPath $Destination -Recurse -Force -File -Filter '*.zip')
  if ($innerZips.Count -eq 0) {
    throw "No markdown files or inner zip files found in $SourceZip"
  }

  $innerRoot = Join-Path $Destination 'inner'
  New-Item -ItemType Directory -Path $innerRoot -Force | Out-Null

  foreach ($innerZip in $innerZips) {
    $innerName = [System.IO.Path]::GetFileNameWithoutExtension($innerZip.Name)
    $innerDest = Join-Path $innerRoot $innerName
    New-Item -ItemType Directory -Path $innerDest -Force | Out-Null
    Expand-Archive -LiteralPath $innerZip.FullName -DestinationPath $innerDest -Force
  }

  return $innerRoot
}

function Convert-MarkdownImages {
  param(
    [string]$Content,
    [string]$SourceDirectory,
    [string]$AssetDirectory,
    [string]$Slug,
    [string]$PublicBase
  )

  $imageMap = @{}
  $sequence = 0
  $pattern = '!\[([^\]]*)\]\(([^)\r\n]+)\)'

  $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
    param([System.Text.RegularExpressions.Match]$match)

    $alt = $match.Groups[1].Value
    $rawTarget = $match.Groups[2].Value.Trim()
    $target = $rawTarget.Trim('<', '>').Trim('"', "'")

    if ($target -match '^(https?:|data:|#|/)' ) {
      return $match.Value
    }

    $decodedTarget = [uri]::UnescapeDataString($target)
    $relativeTarget = $decodedTarget -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $sourceImage = Join-Path $SourceDirectory $relativeTarget

    if (-not (Test-Path -LiteralPath $sourceImage)) {
      throw "Referenced image not found: $target in $SourceDirectory"
    }

    $sourceImage = (Resolve-Path -LiteralPath $sourceImage).Path
    if (-not $imageMap.ContainsKey($sourceImage)) {
      $script:sequence += 1
      $extension = [System.IO.Path]::GetExtension($sourceImage).ToLowerInvariant()
      $newName = '{0}-{1:D3}{2}' -f $Slug, $script:sequence, $extension
      $destinationImage = Join-Path $AssetDirectory $newName
      Copy-Item -LiteralPath $sourceImage -Destination $destinationImage -Force
      $imageMap[$sourceImage] = "$PublicBase/$Slug/$newName"
    }

    return "![$alt]($($imageMap[$sourceImage]))"
  }

  $script:sequence = 0
  $rewritten = [System.Text.RegularExpressions.Regex]::Replace($Content, $pattern, $evaluator)

  return [PSCustomObject]@{
    Content = $rewritten
    ImageCount = $script:sequence
  }
}

$zipFullPath = Get-AbsolutePath $ZipPath
$blogRootFullPath = Get-AbsolutePath $BlogRoot
$assetsRootFullPath = Get-AbsolutePath $AssetsRoot
$tagsList = Normalize-List $Tags
$categoriesList = Normalize-List $Categories
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("notion-import-" + [guid]::NewGuid().ToString('N'))

if (-not (Test-Path -LiteralPath $zipFullPath)) {
  throw "Zip file not found: $zipFullPath"
}

try {
  New-Item -ItemType Directory -Path $workRoot -Force | Out-Null
  $contentRoot = Expand-NotionZip -SourceZip $zipFullPath -Destination $workRoot
  $markdownFiles = @(Get-ChildItem -LiteralPath $contentRoot -Recurse -Force -File -Filter '*.md')

  if ($markdownFiles.Count -eq 0) {
    throw "No markdown files found after extracting $zipFullPath"
  }

  foreach ($markdownFile in $markdownFiles) {
    $cleanStem = Remove-NotionHashSuffix ([System.IO.Path]::GetFileNameWithoutExtension($markdownFile.Name))
    $slug = ConvertTo-Slug $cleanStem
    $articleDir = Join-Path $blogRootFullPath $slug
    $assetDir = Join-Path $assetsRootFullPath $slug
    $articlePath = Join-Path $articleDir "$slug.md"

    if ((Test-Path -LiteralPath $articlePath) -and -not $Force) {
      throw "Article already exists: $articlePath. Re-run with -Force to overwrite it."
    }

    if ((Test-Path -LiteralPath $assetDir) -and -not $Force) {
      $existingAssets = @(Get-ChildItem -LiteralPath $assetDir -Force -File -ErrorAction SilentlyContinue)
      if ($existingAssets.Count -gt 0) {
        throw "Asset directory already contains files: $assetDir. Re-run with -Force to overwrite it."
      }
    }

    if ((Test-Path -LiteralPath $assetDir) -and $Force) {
      Remove-Item -LiteralPath $assetDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $articleDir -Force | Out-Null
    New-Item -ItemType Directory -Path $assetDir -Force | Out-Null

    $originalContent = Get-Content -LiteralPath $markdownFile.FullName -Raw
    $title = Get-TitleFromMarkdown -Content $originalContent -Fallback $cleanStem
    $converted = Convert-MarkdownImages `
      -Content $originalContent `
      -SourceDirectory $markdownFile.DirectoryName `
      -AssetDirectory $assetDir `
      -Slug $slug `
      -PublicBase $PublicAssetsBase.TrimEnd('/')

    $finalContent = $converted.Content
    if ($finalContent -notmatch '^\s*---\s*\r?\n') {
      $frontmatter = New-Object System.Collections.Generic.List[string]
      $frontmatter.Add('---')
      $frontmatter.Add("title: $(ConvertTo-YamlScalar $title)")
      $frontmatter.Add("createTime: $($markdownFile.LastWriteTime.ToString('yyyy/MM/dd HH:mm:ss'))")
      $frontmatter.Add("permalink: /posts/$slug/")
      $frontmatter.Add('tags:')
      foreach ($tag in $tagsList) {
        $frontmatter.Add("  - $(ConvertTo-YamlScalar $tag)")
      }
      $frontmatter.Add('categories:')
      foreach ($category in $categoriesList) {
        $frontmatter.Add("  - $(ConvertTo-YamlScalar $category)")
      }
      $frontmatter.Add('---')
      $frontmatter.Add('')

      $finalContent = ($frontmatter -join "`n") + $finalContent
    }

    Set-Content -LiteralPath $articlePath -Value $finalContent -Encoding UTF8

    [PSCustomObject]@{
      Title = $title
      Slug = $slug
      ArticlePath = $articlePath
      AssetDirectory = $assetDir
      ImageCount = $converted.ImageCount
    }
  }
}
finally {
  if (Test-Path -LiteralPath $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
  }
}
