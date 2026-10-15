"""Check public facts against visible copy and stable/preview availability."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse, unquote
import json
import re

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"


class Page(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.skip = 0
        self.words = []
        self.ids = set()
        self.links = []
        self.h1 = 0
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ("script", "style"):
            self.skip += 1
        if tag == "h1":
            self.h1 += 1
        if "id" in attrs:
            assert attrs["id"] not in self.ids, "Duplicate DOM id"
            self.ids.add(attrs["id"])
        if tag == "a" and "href" in attrs:
            self.links.append(attrs["href"])

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self.skip -= 1

    def handle_data(self, text):
        if not self.skip:
            self.words.append(text)


def normalize(text):
    return " ".join(text.split())


checks = 0
for path in DOCS.rglob("index.html"):
    source = path.read_text(encoding="utf-8-sig")
    page = Page(source)
    visible = normalize(" ".join(page.words))
    assert page.h1 == 1, f"Expected one h1: {path}"
    assert "1.1.2" in visible and "1.2.0-preview.1" in visible, f"Missing version distinction: {path}"
    faq_count = 0
    for raw in re.findall(r'<script type="application/ld\+json">(.*?)</script>', source, re.S):
        data = json.loads(raw)
        for node in data.get("@graph", [data]):
            if node.get("@type") != "FAQPage":
                continue
            faq_count += 1
            for item in node["mainEntity"]:
                assert normalize(item["name"]) in visible, f"Invisible FAQ question: {path}"
                assert normalize(item["acceptedAnswer"]["text"]) in visible, f"Schema answer differs from visible FAQ: {path}"
                checks += 1
    assert faq_count <= 1, f"Duplicate FAQ entity: {path}"
    for link in page.links:
        parsed = urlparse(link)
        if parsed.scheme or parsed.netloc or not parsed.fragment:
            continue
        target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path
        if target.is_dir():
            target /= "index.html"
        assert unquote(parsed.fragment) in Page(target.read_text(encoding="utf-8-sig")).ids, f"Broken fragment: {path}: {link}"
        checks += 1
    assert "cloud storage, clipboard access" not in source, f"Outdated clipboard claim: {path}"
    assert "or run a repeating macro" not in source, f"Outdated no-loop claim: {path}"
    checks += 1

for name in ("llms.txt", "llms-full.txt"):
    text = (DOCS / name).read_text(encoding="utf-8")
    for required in ("1.1.2", "1.2.0-preview.1", "clipboard", "recurring-input/", "VERIFICATION.md"):
        assert required in text, f"Missing fact in {name}: {required}"
        checks += 1
print(f"PASS: {checks} discovery checks: visible FAQ/schema parity, version boundaries, fragments and AI summaries.")
