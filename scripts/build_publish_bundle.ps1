[CmdletBinding()]
param(
  [string]$RepoRoot = ".",
  [string]$OutputDir = "_site",
  [string]$AllowlistFile = "publish-allowlist.txt"
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path -Path $RepoRoot).Path
$allowlistPath = Join-Path -Path $root -ChildPath $AllowlistFile
$outRoot = Join-Path -Path $root -ChildPath $OutputDir

if (-not (Test-Path -Path $allowlistPath -PathType Leaf)) {
  throw "Allowlist file not found: $allowlistPath"
}

if (Test-Path -Path $outRoot) {
  Remove-Item -Path $outRoot -Recurse -Force
}
New-Item -Path $outRoot -ItemType Directory | Out-Null

$entries = Get-Content -Path $allowlistPath | ForEach-Object { $_.Trim() } | Where-Object {
  $_ -and -not $_.StartsWith("#")
}

if (-not $entries.Count) {
  throw "Allowlist is empty: $allowlistPath"
}

function Get-RelativePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BasePath,
    [Parameter(Mandatory = $true)]
    [string]$TargetPath
  )

  $baseFull = [System.IO.Path]::GetFullPath($BasePath)
  if (-not $baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $baseFull += [System.IO.Path]::DirectorySeparatorChar
  }
  $targetFull = [System.IO.Path]::GetFullPath($TargetPath)

  $baseUri = New-Object System.Uri($baseFull)
  $targetUri = New-Object System.Uri($targetFull)
  $relativeUri = $baseUri.MakeRelativeUri($targetUri)
  return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
}

function Copy-AllowlistedPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Entry
  )

  $source = Join-Path -Path $root -ChildPath $Entry
  if (-not (Test-Path -Path $source)) {
    throw "Allowlisted path is missing: $Entry"
  }

  $item = Get-Item -Path $source
  if ($item.PSIsContainer) {
    Get-ChildItem -Path $source -Recurse -File | Where-Object {
      $_.Name -notmatch '\.backup-\d{8}-\d{6}\.html$'
    } | ForEach-Object {
      $relative = Get-RelativePath -BasePath $root -TargetPath $_.FullName
      $target = Join-Path -Path $outRoot -ChildPath $relative
      $targetDir = Split-Path -Path $target -Parent
      if (-not (Test-Path -Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
      }
      Copy-Item -Path $_.FullName -Destination $target -Force
    }
    return
  }

  $destination = Join-Path -Path $outRoot -ChildPath $Entry
  $destDir = Split-Path -Path $destination -Parent
  if ($destDir -and -not (Test-Path -Path $destDir)) {
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
  }
  Copy-Item -Path $source -Destination $destination -Force
}

foreach ($entry in $entries) {
  Copy-AllowlistedPath -Entry $entry
}

# Optional static host/domain file.
$cnamePath = Join-Path -Path $root -ChildPath "CNAME"
if (Test-Path -Path $cnamePath -PathType Leaf) {
  Copy-Item -Path $cnamePath -Destination (Join-Path -Path $outRoot -ChildPath "CNAME") -Force
}

# Guardrails: do not publish authoring/internal files.
$forbiddenPatterns = @(
  "*.md",
  "*.ps1",
  "*.sh",
  "*.yaml",
  "*.yml"
)

$forbiddenFiles = foreach ($pattern in $forbiddenPatterns) {
  Get-ChildItem -Path $outRoot -Recurse -File -Filter $pattern
}

if ($forbiddenFiles) {
  $list = $forbiddenFiles | ForEach-Object {
    Get-RelativePath -BasePath $outRoot -TargetPath $_.FullName
  }
  throw ("Forbidden files detected in publish bundle:`n- " + ($list -join "`n- "))
}

$publishedFiles = Get-ChildItem -Path $outRoot -Recurse -File
Write-Host ("Publish bundle ready: {0} files at {1}" -f $publishedFiles.Count, $outRoot)
