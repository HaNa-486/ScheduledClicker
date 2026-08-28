$ErrorActionPreference = 'Stop'

$docsRoot = Join-Path $PSScriptRoot '..\docs'
$pages = @(Get-ChildItem -LiteralPath $docsRoot -Filter index.html -File -Recurse)
if ($pages.Count -ne 8) { throw "Expected 8 indexable HTML pages, found $($pages.Count)." }

$canonicalUrls = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$titles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$descriptions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($page in $pages) {
    $html = Get-Content -LiteralPath $page.FullName -Raw
    foreach ($requiredPattern in @(
        '<title>[^<]+</title>',
        '<meta name="description" content="[^\"]+">',
        '<meta name="robots" content="[^\"]+">',
        '<link rel="canonical" href="https://hana-486\.github\.io/ScheduledClicker/[^\"]*">',
        '<h1[^>]*>.+?</h1>',
        '(?s)<script type="application/ld\+json">.+?</script>'
    )) {
        if ($html -notmatch $requiredPattern) { throw "$($page.FullName) is missing required pattern: $requiredPattern" }
    }

    $canonical = [regex]::Match($html, '<link rel="canonical" href="([^"]+)">').Groups[1].Value
    if (-not $canonicalUrls.Add($canonical)) { throw "Duplicate canonical URL: $canonical" }
    $title = [regex]::Match($html, '<title>([^<]+)</title>').Groups[1].Value
    if (-not $titles.Add($title)) { throw "Duplicate page title: $title" }
    $description = [regex]::Match($html, '<meta name="description" content="([^"]+)">').Groups[1].Value
    if (-not $descriptions.Add($description)) { throw "Duplicate meta description: $description" }

    foreach ($jsonMatch in [regex]::Matches($html, '<script type="application/ld\+json">(.+?)</script>', 'Singleline')) {
        $null = $jsonMatch.Groups[1].Value | ConvertFrom-Json
    }

    foreach ($imageMatch in [regex]::Matches($html, '<img\s+[^>]*>')) {
        $tag = $imageMatch.Value
        if ($tag -notmatch '\salt="[^"]+"') { throw "$($page.FullName) contains an image without useful alt text." }
    }

    foreach ($assetMatch in [regex]::Matches($html, '(?:href|src)="([^"]+)"')) {
        $target = $assetMatch.Groups[1].Value
        if ($target -match '^(?:https?:|mailto:|#)') { continue }
        $targetWithoutFragment = ($target -split '[?#]')[0]
        if ([string]::IsNullOrWhiteSpace($targetWithoutFragment)) { continue }
        $resolved = [System.IO.Path]::GetFullPath((Join-Path $page.DirectoryName $targetWithoutFragment))
        if (Test-Path -LiteralPath $resolved -PathType Container) { $resolved = Join-Path $resolved 'index.html' }
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "$($page.FullName) links to missing local target: $target" }
    }
}

[xml]$sitemap = Get-Content -LiteralPath (Join-Path $docsRoot 'sitemap.xml') -Raw
$sitemapUrls = @($sitemap.urlset.url | ForEach-Object { $_.loc })
if ($sitemapUrls.Count -ne $canonicalUrls.Count) { throw "Sitemap has $($sitemapUrls.Count) URLs but site has $($canonicalUrls.Count) canonicals." }
foreach ($canonical in $canonicalUrls) {
    if ($sitemapUrls -notcontains $canonical) { throw "Canonical URL is missing from sitemap: $canonical" }
}

foreach ($requiredFile in @('robots.txt', 'llms.txt', 'llms-full.txt', 'social-preview.jpg')) {
    if (-not (Test-Path -LiteralPath (Join-Path $docsRoot $requiredFile) -PathType Leaf)) { throw "Missing discovery asset: $requiredFile" }
}

Write-Host "Site validation passed: $($pages.Count) pages, unique metadata, valid JSON-LD, local links, image alt text, and sitemap coverage."
