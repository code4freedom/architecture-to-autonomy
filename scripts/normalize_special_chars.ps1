$ErrorActionPreference = "Stop"

function Replace-All([string]$text, [hashtable]$map) {
  $out = $text
  foreach ($k in $map.Keys) {
    $out = $out.Replace($k, $map[$k])
  }
  return $out
}

$files = @("index.html") + (Get-ChildItem "posts" -File -Filter "*.html" | ForEach-Object { $_.FullName })

# Normal smart punctuation and spacing.
$baseMap = @{
  ([string][char]0x2018) = "'"
  ([string][char]0x2019) = "'"
  ([string][char]0x201C) = '"'
  ([string][char]0x201D) = '"'
  ([string][char]0x2013) = "-"
  ([string][char]0x2014) = "-"
  ([string][char]0x2026) = "..."
  ([string][char]0x2122) = "TM"
  ([string][char]0x00D7) = "x"
  ([string][char]0x00A0) = " "
}

# Common mojibake sequences seen in imported content.
$mojibakeMap = @{
  (([string][char]0x00E2) + [char]0x20AC + [char]0x2122) = "'"
  (([string][char]0x00E2) + [char]0x20AC + [char]0x0153) = '"'
  (([string][char]0x00E2) + [char]0x20AC + [char]0x009D) = '"'
  (([string][char]0x00E2) + [char]0x20AC + [char]0x201D) = "-"
  (([string][char]0x00E2) + [char]0x20AC + [char]0x201C) = "-"
  (([string][char]0x00E2) + [char]0x20AC + [char]0x00A6) = "..."
  (([string][char]0x00E2) + [char]0x201D + [char]0x20AC) = "-"
  (([string][char]0x00E2) + [char]0x2020 + [char]0x2019) = "->"
  (([string][char]0x00E2) + [char]0x2020 + [char]0x201C) = "v"
  (([string][char]0x00E2) + [char]0x00A0 + [char]0x00BA) = ""
  (([string][char]0x00E2) + [char]0x0153 + [char]0x201C) = "check"
  (([string][char]0x00E2) + [char]0x2014 + [char]0x2030) = "[lock]"
  (([string][char]0x00E2) + [char]0x2014 + [char]0x2113) = "[loop]"
}

foreach ($file in $files) {
  $raw = Get-Content -Path $file -Raw
  $raw = Replace-All $raw $mojibakeMap
  $raw = Replace-All $raw $baseMap

  # Final hard cleanup: keep plain ASCII only.
  $raw = [regex]::Replace($raw, "[^\u0000-\u007F]", "")

  Set-Content -Path $file -Value $raw -Encoding UTF8
}

Write-Output "normalized"
