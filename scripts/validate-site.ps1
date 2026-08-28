$ErrorActionPreference = 'Stop'

$docsRoot = Join-Path $PSScriptRoot '..\docs'
$pages = @(Get-ChildItem -LiteralPath $docsRoot -Filter index.html -File -Recurse)
if ($pages.Count -ne 8) { throw "Expected 8 indexable HTML pages, found $($pages.Count)." }

$canonicalUrls = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$titles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$descriptions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$expectedPrimaryLabels = @('Windows', 'macOS', 'Download', 'FAQ', 'GitHub')
$expectedDetailLabels = @('Windows details', 'macOS details', 'Codex workflow', 'Safety & verification', 'Download', 'FAQ', 'Changelog')
$expectedPrimaryUrls = @(
    'https://hana-486.github.io/ScheduledClicker/windows-scheduled-auto-clicker/',
    'https://hana-486.github.io/ScheduledClicker/macos-scheduled-auto-clicker/',
    'https://hana-486.github.io/ScheduledClicker/download/',
    'https://hana-486.github.io/ScheduledClicker/faq/',
    'https://github.com/HaNa-486/ScheduledClicker'
)
$expectedDetailUrls = @(
    'https://hana-486.github.io/ScheduledClicker/windows-scheduled-auto-clicker/',
    'https://hana-486.github.io/ScheduledClicker/macos-scheduled-auto-clicker/',
    'https://hana-486.github.io/ScheduledClicker/codex-session-continuation/',
    'https://hana-486.github.io/ScheduledClicker/safety-and-verification/',
    'https://hana-486.github.io/ScheduledClicker/download/',
    'https://hana-486.github.io/ScheduledClicker/faq/',
    'https://hana-486.github.io/ScheduledClicker/changelog/'
)

function Get-AnchorRecords([string]$fragment, [string]$baseUrl) {
    @([regex]::Matches($fragment, '<a\b([^>]*)>(.*?)</a>', 'Singleline') | ForEach-Object {
        $attributes = $_.Groups[1].Value
        $hrefMatch = [regex]::Match($attributes, '\bhref="([^"]+)"')
        if (-not $hrefMatch.Success) { throw "Navigation anchor is missing href: $($_.Value)" }
        [pscustomobject]@{
            Label = [System.Net.WebUtility]::HtmlDecode(([regex]::Replace($_.Groups[2].Value, '<[^>]+>', '')).Trim())
            Url = ([uri]::new([uri]$baseUrl, $hrefMatch.Groups[1].Value)).AbsoluteUri
            IsCurrent = $attributes -match '\baria-current="page"'
        }
    })
}

function Assert-NavigationContract(
    [string]$pagePath,
    [string]$canonical,
    [object[]]$records,
    [string[]]$expectedLabels,
    [string[]]$expectedUrls,
    [string]$navigationName
) {
    if (($records.Label -join '|') -ne ($expectedLabels -join '|')) {
        throw "$pagePath $navigationName labels differ: $($records.Label -join ', ')"
    }
    if (($records.Url -join '|') -ne ($expectedUrls -join '|')) {
        throw "$pagePath $navigationName destinations differ: $($records.Url -join ', ')"
    }
    for ($index = 0; $index -lt $records.Count; $index++) {
        $shouldBeCurrent = $records[$index].Url -eq $canonical
        if ($records[$index].IsCurrent -ne $shouldBeCurrent) {
            throw "$pagePath $navigationName has an incorrect aria-current state for '$($records[$index].Label)'."
        }
    }
}

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

    $primaryNavigation = [regex]::Match($html, '<nav aria-label="Primary navigation">(.*?)</nav>', 'Singleline')
    if (-not $primaryNavigation.Success) { throw "$($page.FullName) is missing the standard primary navigation." }
    $primaryRecords = Get-AnchorRecords $primaryNavigation.Groups[1].Value $canonical
    Assert-NavigationContract $page.FullName $canonical $primaryRecords $expectedPrimaryLabels $expectedPrimaryUrls 'primary navigation'

    $detailNavigation = [regex]::Match($html, '<div class="subnav" aria-label="Detailed product pages">(.*?)</div>', 'Singleline')
    if (-not $detailNavigation.Success) { throw "$($page.FullName) is missing the standard detailed-product navigation." }
    $detailRecords = Get-AnchorRecords $detailNavigation.Groups[1].Value $canonical
    Assert-NavigationContract $page.FullName $canonical $detailRecords $expectedDetailLabels $expectedDetailUrls 'detailed navigation'

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

$siteStyles = Get-Content -LiteralPath (Join-Path $docsRoot 'styles.css') -Raw
foreach ($contrastSelector in @(
    '.prose a.button.primary,.prose a.button.primary:visited{color:#041020}',
    '.prose a.button.primary:hover{color:#041020;filter:brightness(1.06)}',
    '.prose a.button.primary:focus-visible{color:#041020;outline:3px solid #fff;outline-offset:3px}'
)) {
    if (-not $siteStyles.Contains($contrastSelector)) { throw "Missing download-button contrast safeguard: $contrastSelector" }
}

if (-not $siteStyles.Contains('@media (max-width:850px){nav{display:none}.subnav{flex-wrap:wrap;overflow-x:visible}')) {
    throw 'Narrow-screen detailed navigation must expose all destinations without hidden horizontal overflow.'
}

Write-Host "Site validation passed: $($pages.Count) pages, consistent navigation, download-button contrast safeguards, unique metadata, valid JSON-LD, local links, image alt text, and sitemap coverage."
