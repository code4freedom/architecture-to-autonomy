$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

function Decode-Html([string]$value) {
  return [System.Net.WebUtility]::HtmlDecode($value)
}

function Normalize-Text([string]$value) {
  $t = Decode-Html $value
  $t = $t -replace "\s+", " "
  return $t.Trim()
}

function Extract-MetaDescription([string]$raw) {
  $m = [regex]::Match($raw, '<meta name="description" content="([^"]*)">')
  if ($m.Success) { return Normalize-Text $m.Groups[1].Value }
  return ""
}

function To-DisplayDate([string]$isoDate) {
  return ([datetime]::Parse($isoDate)).ToString("MMMM d, yyyy")
}

function Clean-BodyHtml([string]$html) {
  $out = $html
  $out = $out -replace "<!---->", ""
  $out = $out -replace "<span[^>]*>", ""
  $out = $out -replace "</span>", ""
  $out = $out -replace "<h3>", "<h2>"
  $out = $out -replace "</h3>", "</h2>"
  $out = $out -replace '<img[^>]*data-li-src="([^"]+)"[^>]*>', '<img src="$1" alt="Inline image" loading="lazy" />'
  $out = $out -replace 'src="//:0"', ""
  $out = $out -replace '<a\s+[^>]*href="([^"]+)"[^>]*>', '<a href="$1" target="_blank" rel="noopener noreferrer">'
  $out = $out -replace "&nbsp;", " "
  return $out.Trim()
}

function Extract-BodyHtml([string]$raw) {
  $blocks = [regex]::Matches($raw, '<div class="article-main__content" data-test-id="publishing-text-block">(.*?)</div>', "Singleline")
  if ($blocks.Count -gt 0) {
    $parts = @()
    foreach ($b in $blocks) {
      $parts += $b.Groups[1].Value
    }
    return (Clean-BodyHtml ($parts -join "`n"))
  }

  $legacyStartTag = '<div class="article-main__content max-w-[744px]">'
  $legacyStart = $raw.IndexOf($legacyStartTag)
  if ($legacyStart -ge 0) {
    $legacyStart += $legacyStartTag.Length
    $legacyEnd = $raw.IndexOf('<!---->    </article>', $legacyStart)
    if ($legacyEnd -gt $legacyStart) {
      $segment = $raw.Substring($legacyStart, $legacyEnd - $legacyStart).Trim()
      $segment = $segment -replace "<!---->", ""
      $segment = [regex]::Replace($segment, "</div>\s*$", "")
      return (Clean-BodyHtml $segment)
    }
  }

  return ""
}

function Infer-Tags([string]$title, [string]$desc) {
  $t = ($title + " " + $desc).ToLowerInvariant()
  $tags = New-Object System.Collections.Generic.List[string]

  if ($t -match "ai|agent|autonomous") { $tags.Add("ai strategy") }
  if ($t -match "cloud|private cloud|platform|vmware") { $tags.Add("platform") }
  if ($t -match "api|programmable") { $tags.Add("api economy") }
  if ($t -match "market|competitive|analysis") { $tags.Add("strategy") }
  if ($t -match "customer experience|experience") { $tags.Add("customer value") }
  if ($t -match "decision|lead|leadership") { $tags.Add("leadership") }

  if ($tags.Count -eq 0) { $tags.Add("enterprise architecture") }
  if ($tags.Count -lt 3) {
    if (-not $tags.Contains("enterprise architecture")) { $tags.Add("enterprise architecture") }
    if ($tags.Count -lt 3 -and -not $tags.Contains("technology strategy")) { $tags.Add("technology strategy") }
  }

  return ($tags | Select-Object -Unique | Select-Object -First 3)
}

$meta = Get-Content temp\linkedin\metadata.json -Raw | ConvertFrom-Json
$generated = @()

foreach ($m in $meta) {
  $raw = Get-Content (Join-Path "temp/linkedin" $m.File) -Raw
  $body = Extract-BodyHtml $raw
  if ([string]::IsNullOrWhiteSpace($body)) {
    throw "Could not extract body for $($m.File)"
  }

  $desc = Extract-MetaDescription $raw
  if ([string]::IsNullOrWhiteSpace($desc)) { $desc = "Originally published on LinkedIn by Samir Roshan." }

  $displayDate = To-DisplayDate $m.Date
  $slug = $m.Slug
  $postPath = Join-Path "posts" ("$slug.html")
  $readTime = $m.ReadingTime
  if ([string]::IsNullOrWhiteSpace($readTime)) { $readTime = "5 min read" }

  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$($m.Title) | Architecture to Autonomy</title>
  <meta name="description" content="$desc" />
  <link rel="icon" type="image/svg+xml" href="../assets/a2a-logo.svg" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=Space+Grotesk:wght@400;500;700&display=swap" rel="stylesheet" />
  <style>
    :root {
      --bg: #f3f6fb;
      --surface: #ffffff;
      --ink: #0f172a;
      --muted: #475569;
      --brand: #0f766e;
      --line: #d5deea;
      --max: 860px;
      --radius: 18px;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Space Grotesk", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(900px 500px at 8% -20%, rgba(15, 118, 110, 0.12), transparent 60%),
        radial-gradient(850px 420px at 100% -10%, rgba(234, 88, 12, 0.12), transparent 55%),
        linear-gradient(180deg, #f3f6fb 0%, #eef2f7 100%);
      line-height: 1.7;
    }
    a { color: inherit; text-decoration: none; }
    .container { width: min(var(--max), calc(100% - 2rem)); margin: 0 auto; }
    .topbar {
      position: sticky;
      top: 0;
      z-index: 20;
      backdrop-filter: blur(8px);
      background: rgba(243, 246, 251, 0.9);
      border-bottom: 1px solid rgba(148, 163, 184, 0.25);
    }
    .topbar .container {
      min-height: 66px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    }
    .brand { display: inline-flex; align-items: center; gap: 0.65rem; font-weight: 700; font-size: 1rem; }
    .logo { width: 30px; height: 30px; border-radius: 8px; box-shadow: 0 8px 18px rgba(15, 23, 42, 0.2); }
    .back-link {
      font-size: 0.92rem;
      color: #334155;
      border: 1px solid rgba(51, 65, 85, 0.2);
      border-radius: 999px;
      padding: 0.38rem 0.7rem;
      background: rgba(255, 255, 255, 0.8);
    }
    .hero { padding: 2.2rem 0 1.3rem; }
    .hero-card {
      background: linear-gradient(145deg, rgba(255, 255, 255, 0.95), #eef6ff 70%);
      border: 1px solid rgba(148, 163, 184, 0.35);
      border-radius: calc(var(--radius) + 4px);
      box-shadow: 0 16px 38px rgba(15, 23, 42, 0.12);
      padding: 2rem;
      position: relative;
      overflow: hidden;
    }
    .hero-card::after {
      content: "";
      position: absolute;
      right: -110px;
      bottom: -120px;
      width: 280px;
      height: 280px;
      border-radius: 50%;
      background: radial-gradient(circle at center, rgba(15, 118, 110, 0.22), transparent 70%);
      pointer-events: none;
    }
    .kicker {
      font-family: "IBM Plex Mono", monospace;
      font-size: 0.75rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      display: inline-flex;
      align-items: center;
      gap: 0.45rem;
      color: var(--brand);
      border: 1px solid rgba(15, 118, 110, 0.35);
      border-radius: 999px;
      padding: 0.34rem 0.64rem;
      background: rgba(15, 118, 110, 0.08);
      margin-bottom: 0.9rem;
    }
    h1 {
      margin: 0 0 0.85rem;
      font-size: clamp(1.95rem, 4.1vw, 3.4rem);
      line-height: 1.08;
      letter-spacing: -0.02em;
      max-width: 16ch;
    }
    .dek { margin: 0; font-size: clamp(1rem, 1.7vw, 1.25rem); color: var(--muted); max-width: 58ch; }
    .meta {
      margin-top: 1.15rem;
      display: flex;
      flex-wrap: wrap;
      gap: 0.55rem;
      font-family: "IBM Plex Mono", monospace;
      font-size: 0.78rem;
      color: #334155;
    }
    .meta span {
      display: inline-flex;
      align-items: center;
      gap: 0.3rem;
      padding: 0.32rem 0.58rem;
      border-radius: 999px;
      border: 1px solid rgba(51, 65, 85, 0.2);
      background: rgba(255, 255, 255, 0.75);
    }
    article {
      margin: 1.2rem 0 2.4rem;
      background: var(--surface);
      border: 1px solid rgba(148, 163, 184, 0.3);
      border-radius: var(--radius);
      box-shadow: 0 10px 26px rgba(15, 23, 42, 0.08);
      padding: 1.6rem;
    }
    article h2 { margin: 1.5rem 0 0.6rem; font-size: 1.35rem; line-height: 1.25; }
    article p { margin: 0 0 1rem; color: #1e293b; font-size: 1.04rem; }
    article ul, article ol { margin: 0 0 1rem 1.2rem; }
    article li { margin-bottom: 0.55rem; }
    article img { width: 100%; height: auto; border-radius: 12px; border: 1px solid var(--line); margin: 0.5rem 0 1rem; }
    article div.slate-resizable-image-embed { margin: 0.5rem 0 1rem; }
    article a { color: #0a66c2; text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 3px; }
    .source {
      margin-top: 1.5rem;
      padding-top: 1rem;
      border-top: 1px dashed rgba(100, 116, 139, 0.5);
      color: #334155;
      font-size: 0.95rem;
    }
    .source a { font-weight: 600; }
    .bottom-nav {
      margin: 0 0 3rem;
      display: flex;
      justify-content: space-between;
      gap: 0.8rem;
      flex-wrap: wrap;
    }
    .pill-btn {
      display: inline-flex;
      align-items: center;
      gap: 0.45rem;
      padding: 0.55rem 0.8rem;
      border-radius: 999px;
      border: 1px solid rgba(51, 65, 85, 0.2);
      background: rgba(255, 255, 255, 0.82);
      font-weight: 600;
      color: #1e293b;
    }
    .pill-btn.linkedin { background: #0a66c2; color: #ffffff; border-color: #0a66c2; }
    @media (max-width: 760px) {
      .hero-card { padding: 1.35rem; }
      article { padding: 1.15rem; }
    }
  </style>
</head>
<body>
  <header class="topbar">
    <div class="container">
      <a class="brand" href="../index.html">
        <img class="logo" src="../assets/a2a-logo.svg" alt="Architecture to Autonomy logo" />
        <span>Architecture to Autonomy</span>
      </a>
      <a class="back-link" href="../index.html#posts">Back to posts</a>
    </div>
  </header>

  <main>
    <section class="hero">
      <div class="container">
        <div class="hero-card">
          <span class="kicker">Republished from LinkedIn</span>
          <h1>$($m.Title)</h1>
          <p class="dek">$desc</p>
          <div class="meta">
            <span>By Samir Roshan</span>
            <span>Published $displayDate</span>
            <span>$readTime</span>
          </div>
        </div>
      </div>
    </section>

    <section>
      <div class="container">
        <article>
$body
          <p class="source">
            Originally published on LinkedIn on $displayDate.
            <a href="$($m.Url)/" target="_blank" rel="noopener noreferrer">Read original post</a>.
          </p>
        </article>

        <div class="bottom-nav">
          <a class="pill-btn" href="../index.html#posts">Back to all posts</a>
          <a class="pill-btn linkedin" href="https://www.linkedin.com/in/samirroshan/" target="_blank" rel="noopener noreferrer">Connect on LinkedIn</a>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
"@

  Set-Content -Path $postPath -Value $html

  $summary = $desc
  if ($summary.Length -gt 150) { $summary = $summary.Substring(0, 147).TrimEnd() + "..." }
  $tags = Infer-Tags $m.Title $desc

  $generated += [PSCustomObject]@{
    Title = $m.Title
    Date = $m.Date
    DisplayDate = $displayDate
    Url = "posts/$slug.html"
    Summary = $summary
    Tags = @($tags)
  }
}

$fixedPosts = @(
  [PSCustomObject]@{
    Title = "The Agentic Enterprise Needs a New Platform Stack"
    Date = "2026-03-05"
    DisplayDate = "March 5, 2026"
    Url = "posts/agentic-enterprise-platform-stack.html"
    Summary = "Why enterprises need a new architecture foundation for autonomous AI systems."
    Tags = @("platform architecture", "agentic systems", "enterprise AI")
  },
  [PSCustomObject]@{
    Title = "Leading from Altitude: Why Strategic Distance Drives Better Decisions"
    Date = "2025-10-27"
    DisplayDate = "October 27, 2025"
    Url = "posts/leading-from-altitude-strategic-distance.html"
    Summary = "Why technology leaders need deliberate distance to improve clarity, strategy, and long-term execution."
    Tags = @("leadership", "strategy", "operating model")
  }
)

$allPosts = @($fixedPosts + $generated) | Sort-Object { [datetime]$_.Date } -Descending

$cards = @()
foreach ($p in $allPosts) {
  $tagSpans = ($p.Tags | Select-Object -First 3 | ForEach-Object { '              <span class="tag">' + $_ + '</span>' }) -join "`n"
  $cards += @"
          <article class="card post-card">
            <div>
              <h3>$($p.Title)</h3>
              <p>Published $($p.DisplayDate). $($p.Summary)</p>
            </div>
            <div class="tag-row">
$tagSpans
            </div>
            <p><a class="read-btn" href="$($p.Url)">Open post</a></p>
          </article>
"@
}

$newPostsSection = @"
    <section id="posts">
      <div class="container">
        <div class="section-head">
          <h2>Published Posts</h2>
          <span class="mono">chronological feed</span>
        </div>
        <div class="grid">
$($cards -join "`n")
        </div>
      </div>
    </section>
"@

$index = Get-Content index.html -Raw
$updated = [regex]::Replace($index, '(?s)<section id="posts">.*?</section>\s*<section>', ($newPostsSection + "`r`n    <section>"), 1)
if ($updated -eq $index) { throw "Failed to replace posts section in index.html" }
Set-Content -Path index.html -Value $updated

$generated | Sort-Object Date -Descending | Format-Table Date, Title, Url -AutoSize
