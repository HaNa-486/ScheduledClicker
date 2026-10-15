"""Validate full localized pages, navigation, files, fragments and search metadata."""
import importlib.util
import json
import re
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin, urlparse, unquote

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
spec = importlib.util.spec_from_file_location('site_builder', ROOT / 'scripts/generate-site.py')
site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(site)

class Page(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.tags = []
        self.ids = set()
        self.words = []
        self.hidden = 0
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        self.tags.append((tag, a))
        if 'id' in a:
            assert a['id'] not in self.ids, 'Duplicate id: ' + a['id']
            self.ids.add(a['id'])
        if tag in ('script', 'style'):
            self.hidden += 1

    def handle_endtag(self, tag):
        if tag in ('script', 'style'):
            self.hidden -= 1

    def handle_data(self, value):
        if not self.hidden:
            self.words.append(value)

def check():
    expected = site.outputs()
    actual = {p.relative_to(DOCS).as_posix() for p in DOCS.rglob('index.html')}
    assert actual == {p for p in expected if p.endswith('index.html')}, 'Page inventory differs'
    pages = {name: Page((DOCS / name).read_text(encoding='utf-8')) for name in actual}
    titles, descriptions = set(), set()
    checks = 0
    for lang in site.LANGS:
        t = site.catalog(lang)
        for key in site.SLUGS:
            filename = site.path(lang, key) + 'index.html'
            source = (DOCS / filename).read_text(encoding='utf-8')
            assert source == expected[filename], 'Generated output drift: ' + filename
            p = pages[filename]
            canonical = site.url(lang, key)
            tags = p.tags
            assert [a['lang'] for tag, a in tags if tag == 'html'] == [lang]
            assert sum(tag == 'h1' for tag, a in tags) == 1
            assert [a['href'] for tag, a in tags if tag == 'link' and a.get('rel') == 'canonical'] == [canonical]
            alternates = {a['hreflang']: a['href'] for tag, a in tags if tag == 'link' and a.get('rel') == 'alternate'}
            assert alternates == {**{x: site.url(x, key) for x in site.LANGS}, 'x-default': site.url('en', key)}
            switches = [a for tag, a in tags if tag == 'a' and a.get('class') == 'language-link']
            assert len(switches) == 5
            for a in switches:
                assert urljoin(canonical, a['href']) == site.url(a['hreflang'], key), 'Language switch lost topic'
                assert (a.get('aria-current') == 'page') == (a['hreflang'] == lang)
            title = re.search(r'<title>(.*?)</title>', source).group(1)
            desc = next(a['content'] for tag, a in tags if tag == 'meta' and a.get('name') == 'description')
            assert title not in titles and desc not in descriptions, 'Duplicate page metadata'
            titles.add(title); descriptions.add(desc)
            visible = ' '.join(' '.join(p.words).split())
            assert t['support.text'] in visible and t['ui.latest'] in visible
            assert any(a.get('href') == site.REPO + '/issues' for tag, a in tags if tag == 'a')
            assert '/actions/runs/' not in source and '1.2.0-preview' not in source
            for tag, a in tags:
                if tag == 'img':
                    assert a.get('alt') and a.get('src')
                for attr in ('href', 'src'):
                    if attr not in a:
                        continue
                    dest = urlparse(urljoin(canonical, a[attr]))
                    if not (dest.scheme == 'https' and dest.netloc == 'hana-486.github.io'):
                        continue
                    assert dest.path.startswith('/ScheduledClicker/'), a[attr]
                    target = unquote(dest.path.removeprefix('/ScheduledClicker/'))
                    if target.endswith('/') or not target:
                        target += 'index.html'
                    assert (DOCS / target).is_file(), (filename, a[attr])
                    if dest.fragment:
                        assert unquote(dest.fragment) in pages[target].ids, (filename, a[attr])
                    checks += 1
            graph = json.loads(re.search(r'<script type="application/ld\+json">(.*?)</script>', source, re.S).group(1))['@graph']
            for node in graph:
                if node['@type'] in ('WebPage', 'FAQPage'):
                    assert node['inLanguage'] == lang
                if node['@type'] == 'SoftwareApplication':
                    assert node['softwareVersion'] == '1.2.0'
                    assert node['downloadUrl'] in [site.asset(x) for x in site.ASSETS.values()]
                if node['@type'] == 'FAQPage':
                    for item in node['mainEntity']:
                        assert item['name'] in visible and item['acceptedAnswer']['text'] in visible, 'FAQ not visible'
                        checks += 1
            if key == 'download':
                for platform in ('windows', 'macos'):
                    assert {'install-' + platform, 'verify-' + platform, platform}.issubset(p.ids)
                    assert site.asset(site.ASSETS[platform]) in source and site.asset(site.CHECKSUMS[platform]) in source
                for text_key in ('installWin.warning', 'installMac.warning', 'verify.intro', 'verify.win', 'verify.mac', 'installMac.replacement'):
                    assert t[text_key] in visible
            checks += 12
    urls = {x.text for x in ET.parse(DOCS / 'sitemap.xml').findall('{*}url/{*}loc')}
    assert urls == {site.url(lang, key) for lang in site.LANGS for key in site.SLUGS}
    assert 'AHw8DVZLFAuCxIebG7sZ5jkFwvi1Ugxtm0zogfJEuKo' in (DOCS / 'index.html').read_text(encoding='utf-8')
    for lang in site.LANGS:
        for name in ('llms.txt', 'llms-full.txt'):
            source = (DOCS / site.path(lang, 'home') / name).read_text(encoding='utf-8')
            assert 'v1.2.0' in source and 'VERIFICATION.md' in source and site.REPO + '/issues' in source
            for key in site.SLUGS:
                assert site.url(lang, key) in source
    for name in ('robots.txt', 'social-preview.jpg', 'languages.js', 'styles.css'):
        assert (DOCS / name).is_file()
    print(f'PASS: {checks} checks across 45 pages: localized metadata, reciprocal languages, navigation, fragments, files, FAQ/schema and sitemap.')

if __name__ == '__main__':
    check()
