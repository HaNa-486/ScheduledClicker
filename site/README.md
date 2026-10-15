# Static multilingual site

Edit `content/{en,zh-Hant,ja,ko,de}.json` and `scripts/generate-site.py`, then run:

```text
python scripts/generate-site.py
python scripts/generate-site.py --check
python scripts/validate-site.py
python scripts/validate-discovery.py
```

All nine topics are rendered as complete HTML in each language. English retains its original URLs; the other languages use their locale prefix. Each page has a self-canonical URL and reciprocal same-topic hreflang links, including English as x-default. Language switching is explicit, does not redirect visitors by IP, and works without JavaScript. The optional script preserves section fragments. No tracking, cookies or remote translation is used.

The visible FAQ and JSON-LD use the same content. Application locale lists describe the app, while WebPage/FAQ language and page metadata describe the current translation. `llms` files are supplemental facts, not a ranking or inclusion guarantee. The sitemap lists all 45 pages. Keep the Google verification token and existing English URLs intact.

The canonical runtime download remains GitHub Release v1.2.0; never replace its files as part of a website-only update. Signing/notarization and Search Console are explicitly deferred by the owner.
