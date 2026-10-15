"""Build the static five-language site. No network or runtime translation required."""
import argparse
import html
import json
import posixpath
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
BASE = 'https://hana-486.github.io/ScheduledClicker/'
REPO = 'https://github.com/HaNa-486/ScheduledClicker'
VERSION = '1.2.0'
DATE = '2026-10-15'
LANGS = {'en': 'English', 'zh-Hant': '繁體中文', 'ja': '日本語', 'ko': '한국어', 'de': 'Deutsch'}
SLUGS = {'home': '', 'download': 'download/', 'windows': 'windows-scheduled-auto-clicker/', 'macos': 'macos-scheduled-auto-clicker/', 'loop': 'recurring-input/', 'codex': 'codex-session-continuation/', 'safety': 'safety-and-verification/', 'faq': 'faq/', 'changelog': 'changelog/'}
ASSETS = {'windows': 'ScheduledClicker.exe', 'macos': 'ScheduledClicker-macOS-universal.zip'}
CHECKSUMS = {'windows': 'ScheduledClicker-Windows.sha256', 'macos': 'ScheduledClicker-macOS-universal.sha256'}
OG = {'en': 'en_US', 'zh-Hant': 'zh_TW', 'ja': 'ja_JP', 'ko': 'ko_KR', 'de': 'de_DE'}

def path(lang, page):
    return ('' if lang == 'en' else lang + '/') + SLUGS[page]

def url(lang, page):
    return BASE + path(lang, page)

def asset(name):
    return f'{REPO}/releases/download/v{VERSION}/{name}'

def catalog(lang):
    return json.loads((ROOT / 'site/content' / (lang + '.json')).read_text(encoding='utf-8'))

def render(lang, page, t):
    folder = path(lang, page)
    def rel(target):
        anchor = ''
        if '#' in target:
            target, anchor = target.split('#', 1)
            anchor = '#' + anchor
        value = posixpath.relpath(target or '.', folder or '.')
        if target.endswith('/') or not target:
            value = ('./' if value == '.' else value + '/')
        return value + anchor
    def local(key, anchor=''):
        return rel(path(lang, key) + anchor)
    def link(href, label, css='', extra=''):
        return f'<a href="{html.escape(href, quote=True)}"' + (f' class="{css}"' if css else '') + extra + f'>{html.escape(label)}</a>'
    def p(key):
        return '<p>' + html.escape(t[key]) + '</p>'
    def section(key):
        return '<section><h2>' + html.escape(t[key + '.title']) + '</h2>' + p(key + '.text') + '</section>'
    def items(key, ordered=False):
        tag = 'ol' if ordered else 'ul'
        return f'<{tag}>' + ''.join('<li>' + html.escape(x) + '</li>' for x in t[key]) + f'</{tag}>'
    def cards(platforms=('windows', 'macos')):
        result = '<div class="download-grid">'
        for platform in platforms:
            short = 'Win' if platform == 'windows' else 'Mac'
            result += f'<section class="download-card" id="{platform}"><h2>' + ('Windows 11' if platform == 'windows' else 'macOS 13+') + '</h2>'
            result += p('ui.' + ('winCard' if platform == 'windows' else 'macCard'))
            result += '<p><code>' + ASSETS[platform] + '</code></p>'
            result += link(asset(ASSETS[platform]), t['ui.download' + short], 'button primary')
            result += '<p>' + link(local('download', '#install-' + platform), t['ui.installLink'], 'install-link') + '</p>'
            result += '<p>' + link(asset(CHECKSUMS[platform]), t['ui.checksum']) + ' · ' + link(local('download', '#verify-' + platform), t['ui.verify']) + '</p></section>'
        return result + '</div>'
    def verify():
        result = '<section id="checksums"><h2>' + html.escape(t['ui.verify']) + '</h2>' + p('verify.intro')
        for platform, short, command in [('windows', 'win', 'Get-FileHash -LiteralPath "C:\\Users\\YOUR_NAME\\Downloads\\ScheduledClicker.exe" -Algorithm SHA256'), ('macos', 'mac', 'shasum -a 256 "/Users/YOUR_NAME/Downloads/ScheduledClicker-macOS-universal.zip"')]:
            result += f'<section id="verify-{platform}"><h3>' + ('Windows · PowerShell' if platform == 'windows' else 'macOS · Terminal') + '</h3>' + p('verify.' + short) + p('verify.example')
            result += '<pre><code>' + html.escape(command) + '</code></pre><p>' + link(asset(CHECKSUMS[platform]), t['ui.checksum']) + '</p></section>'
        return result + '</section>'
    def install():
        result = ''
        for platform, short, help_url in [('windows', 'Win', 'https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation'), ('macos', 'Mac', 'https://support.apple.com/102445')]:
            result += f'<section id="install-{platform}"><h2>' + html.escape(t['ui.install' + short]) + '</h2>'
            result += items('install' + short + '.steps', True)
            result += '<aside class="callout"><h3>' + html.escape(t['warning.title']) + '</h3>' + p('install' + short + '.warning')
            result += '<p>' + link(help_url, t['ui.officialHelp']) + '</p></aside>'
            if platform == 'macos':
                result += p('installMac.replacement')
            result += '<p>' + link('#verify-' + platform, t['ui.verify']) + ' · ' + link('#report-problem', t['nav.support']) + '</p></section>'
        return result
    def shot(platform):
        key = 'ui.shotWin' if platform == 'windows' else 'ui.shotMac'
        src = 'images/windows-loop-dark.png' if platform == 'windows' else 'images/macos-loop-dark.png'
        return f'<figure class="product-shot preview-shot"><img loading="lazy" src="{rel(src)}" alt="{html.escape(t[key], quote=True)}"><figcaption>{html.escape(t[key])}</figcaption></figure>'
    faq_keys = {'home': ['files', 'modes', 'limits'], 'download': ['files', 'warning'], 'windows': ['prompt', 'warning'], 'macos': ['compatMac', 'tested'], 'loop': ['interval', 'stop', 'limits'], 'codex': ['limits', 'interval'], 'safety': [], 'faq': ['files', 'warning', 'modes', 'languages', 'theme', 'prompt', 'interval', 'stop', 'privacy', 'limits', 'tested', 'compatMac'], 'changelog': []}[page]
    body = ''
    if page in ('home', 'download'):
        body += cards()
    elif page in ('windows', 'macos'):
        body += cards((page,))
    else:
        body += '<div class="actions">' + link(local('download'), t['nav.download'], 'button primary') + '</div>'
    body += '<article class="prose">'
    if page == 'home':
        body += section('modes') + section('languages') + section('theme') + section('privacy')
        body += '<div class="product-shots">' + shot('windows') + shot('macos') + '</div>'
    elif page == 'download':
        body += install() + verify() + '<section id="preview"><h2>' + html.escape(t['upgrade.title']) + '</h2>' + p('upgrade.text') + '</section>'
        body += '<p>' + link(REPO + '/releases/tag/v' + VERSION, t['ui.release']) + '</p>'
    elif page in ('windows', 'macos'):
        body += section('modes') + section('compatWin' if page == 'windows' else 'compatMac') + section('languages') + section('theme') + shot(page)
        body += '<p>' + link(local('download', '#install-' + page), t['ui.installLink']) + ' · ' + link(local('loop'), t['nav.loop']) + '</p>'
    elif page == 'loop':
        body += items('loop.steps', True) + section('prompt') + section('privacy')
    elif page == 'codex':
        body += p('codex.text') + '<p>' + link(local('loop'), t['nav.loop']) + '</p>' + section('stop') + section('privacy')
    elif page == 'safety':
        body += section('privacy') + section('limits') + section('stop') + section('tested') + p('support.diagnostic') + '<p>' + link(REPO + '/blob/main/VERIFICATION.md', t['evidence.link']) + '</p>' + section('warning') + verify()
        body += '<p>' + link(local('download', '#install-windows'), t['ui.installWin']) + ' · ' + link(local('download', '#install-macos'), t['ui.installMac']) + '</p>'
    elif page == 'changelog':
        body += '<h2>v1.2.0 · 2026-10-15</h2>' + p('changelog.current') + p('changelog.site') + items('changelog.old')
        body += '<p>' + link(REPO + '/releases/tag/v' + VERSION, t['ui.release']) + ' · ' + link(REPO + '/releases', t['changelog.history']) + '</p>'
    body += '</article>'
    if faq_keys:
        body += '<section class="faq" id="questions"><h2>' + html.escape(t['ui.questions']) + '</h2>'
        body += ''.join('<details><summary>' + html.escape(t['faq.' + k]) + '</summary>' + p(k + '.text') + '</details>' for k in faq_keys) + '</section>'
    body += '<section class="support-box" id="report-problem"><h2>' + html.escape(t['support.title']) + '</h2>' + p('support.text')
    body += '<div class="actions">' + link(REPO + '/issues', t['support.button'], 'button secondary') + link(local('faq'), t['support.faq']) + '</div></section>'
    title = ('ScheduledClicker v1.2.0 — ' if page != 'download' else '') + t[page + '.title']
    canonical = url(lang, page)
    graph = [{'@type': 'WebPage', '@id': canonical, 'url': canonical, 'name': title, 'description': t[page + '.lead'], 'inLanguage': lang, 'dateModified': DATE}]
    for platform in (('windows',) if page == 'windows' else ('macos',) if page == 'macos' else ('windows', 'macos')):
        graph.append({'@type': 'SoftwareApplication', '@id': url(lang, 'home') + '#' + platform, 'name': 'ScheduledClicker', 'softwareVersion': VERSION, 'operatingSystem': 'Windows 11' if platform == 'windows' else 'macOS 13 or later', 'applicationCategory': 'UtilitiesApplication', 'description': t['home.lead'], 'inLanguage': list(LANGS), 'isAccessibleForFree': True, 'license': REPO + '/blob/main/LICENSE', 'downloadUrl': asset(ASSETS[platform]), 'url': url(lang, platform), 'releaseNotes': REPO + '/releases/tag/v' + VERSION, 'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD'}, 'author': {'@type': 'Person', 'name': 'HaNa-486', 'url': 'https://github.com/HaNa-486'}})
    if faq_keys:
        graph.append({'@type': 'FAQPage', 'inLanguage': lang, 'mainEntity': [{'@type': 'Question', 'name': t['faq.' + k], 'acceptedAnswer': {'@type': 'Answer', 'text': t[k + '.text']}} for k in faq_keys]})
    head = f'<!doctype html>\n<html lang="{lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">\n<title>{html.escape(title)}</title>\n'
    for name, value in [('description', t[page + '.lead']), ('robots', 'index, follow, max-image-preview:large'), ('twitter:card', 'summary_large_image'), ('twitter:title', title), ('twitter:description', t[page + '.lead']), ('twitter:image', BASE + 'social-preview.jpg')]:
        head += f'<meta name="{name}" content="{html.escape(value, quote=True)}">\n'
    if lang == 'en' and page == 'home':
        head += '<meta name="google-site-verification" content="AHw8DVZLFAuCxIebG7sZ5jkFwvi1Ugxtm0zogfJEuKo">\n'
    head += f'<link rel="canonical" href="{canonical}">\n'
    for other in LANGS:
        head += f'<link rel="alternate" hreflang="{other}" href="{url(other, page)}">\n'
    head += f'<link rel="alternate" hreflang="x-default" href="{url("en", page)}">\n'
    for name, value in [('og:type', 'website'), ('og:site_name', 'ScheduledClicker'), ('og:title', title), ('og:description', t[page + '.lead']), ('og:url', canonical), ('og:image', BASE + 'social-preview.jpg'), ('og:locale', OG[lang])]:
        head += f'<meta property="{name}" content="{html.escape(value, quote=True)}">\n'
    for other in LANGS:
        if other != lang:
            head += f'<meta property="og:locale:alternate" content="{OG[other]}">\n'
    head += f'<link rel="stylesheet" href="{rel("styles.css")}?v=20261015-i18n">\n<script type="application/ld+json">' + json.dumps({'@context': 'https://schema.org', '@graph': graph}, ensure_ascii=False, indent=2).replace('</', '<\\/') + '</script></head>\n'
    nav = '<header class="site-header">' + link(local('home'), 'ScheduledClicker', 'brand') + '<div class="language-bar"><span>' + html.escape(t['ui.language']) + '</span><nav aria-label="' + html.escape(t['ui.language']) + '">'
    for other, name in LANGS.items():
        nav += link(rel(path(other, page)), name, 'language-link', f' lang="{other}" hreflang="{other}"' + (' aria-current="page"' if other == lang else ''))
    nav += '</nav></div></header><nav class="site-nav" aria-label="' + html.escape(t['ui.navigation']) + '">'
    for key in SLUGS:
        nav += link(local(key), t['nav.' + key], extra=' aria-current="page"' if key == page else '')
    nav += link('#report-problem', t['nav.support']) + '</nav>'
    intro = '<main class="page-main" id="main"><aside class="version-note">' + html.escape(t['ui.latest']) + '</aside><section class="page-hero"><p class="eyebrow">' + html.escape(t['ui.free']) + '</p><h1>' + html.escape(t[page + '.title']) + '</h1><p class="lead">' + html.escape(t[page + '.lead']) + '</p></section>'
    foot = '<footer><span>ScheduledClicker v1.2.0 · ' + html.escape(t['footer.license']) + '</span><span>' + link(local('download'), t['nav.download']) + ' · ' + link('#report-problem', t['nav.support']) + ' · ' + link(REPO, 'GitHub') + '</span></footer>'
    return head + '<body>' + link('#main', t['ui.skip'], 'skip-link') + nav + intro + body + '</main>' + foot + f'<script src="{rel("languages.js")}" defer></script></body></html>\n'

def outputs():
    result = {}
    expected = catalog('en')
    for lang in LANGS:
        t = catalog(lang)
        assert t.keys() == expected.keys(), f'Catalog keys differ: {lang}'
        for key, value in t.items():
            assert type(value) is type(expected[key]) and value, (lang, key)
            if isinstance(value, list):
                assert len(value) == len(expected[key]) and all(isinstance(v, str) and v for v in value), (lang, key)
        for page in SLUGS:
            result[path(lang, page) + 'index.html'] = render(lang, page, t)
        summary = '# ScheduledClicker v1.2.0 — ' + t['summary.title'] + '\n\n' + t['home.lead'] + '\n\n'
        summary += '\n'.join(f'- [{t[page + ".title"]}]({url(lang, page)})' for page in SLUGS) + '\n\n'
        summary += '\n'.join(t[key + '.text'] for key in ['files', 'languages', 'privacy', 'limits', 'tested', 'warning']) + '\n\n'
        summary += '\n'.join(f'- {name}: {asset(name)}' for name in [*ASSETS.values(), *CHECKSUMS.values()]) + '\n'
        summary += '\n- VERIFICATION.md: ' + REPO + '/blob/main/VERIFICATION.md\n'
        summary += '\n' + t['support.text'] + '\n' + REPO + '/issues\n'
        if lang == 'en':
            summary += '\n## Languages\n' + '\n'.join(f'- [{LANGS[x]}]({url(x, "home")})' for x in LANGS) + '\n'
        result[path(lang, 'home') + 'llms.txt'] = summary
        full = summary + '\n' + '\n\n'.join(t[k] for k in ['installWin.warning', 'installMac.warning', 'installMac.replacement', 'verify.intro', 'verify.win', 'verify.mac'])
        full += '\n\n' + '\n'.join(t['installWin.steps'] + t['installMac.steps'] + t['loop.steps']) + '\n'
        result[path(lang, 'home') + 'llms-full.txt'] = full
    result['sitemap.xml'] = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + '\n'.join(f'  <url><loc>{url(lang, page)}</loc><lastmod>{DATE}</lastmod></url>' for lang in LANGS for page in SLUGS) + '\n</urlset>\n'
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = outputs()
    for name, content in data.items():
        target = DOCS / name
        if args.check:
            assert target.exists() and target.read_text(encoding='utf-8') == content, f'Stale generated file: {name}'
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding='utf-8', newline='\n')
    print(f'{"Verified" if args.check else "Generated"} {len(data)} files: 45 HTML pages, 10 AI summaries and sitemap.')

if __name__ == '__main__':
    main()
