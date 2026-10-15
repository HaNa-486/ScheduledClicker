# Mac preview and discovery content

- Date: 2026-10-15
- Explicit: owner accepted Windows tests and requested Mac build plus SEO/AEO/AISEO/GEO/LLMO content updates.
- Scope: native universal preview, CI evidence, local test guide and version-aware website source. Production merge/release/deployment is separate.
- Delivery: 1.2.0-preview.1; app bundle 1.2.0/build 12001, macOS 13+, Intel and Apple Silicon. Ad-hoc signed, not Developer ID signed or notarized.
- Verified candidate: CI [38688961403](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38688961403), source 12dbed9. ZIP 343687 bytes, SHA-256 26AA4D27AD52B260DE6802FC2BBD6945F75B6E1067672B61B57CF2398C524E44.
- Acceptance: both-platform regression pass; shared window, language/theme and fixed notices render; binary architecture/signature/archive verified; stable/preview facts and visible FAQ/schema agree; local desktop/mobile discovery journey works.
- Open: real Mac Accessibility, clipboard/paste/send, same-app wrong-window refusal and physical F8. See macOS/TESTING.md; CI smoke does not substitute for these.

## Discovery decisions

- [Google AI features guidance](https://developers.google.com/search/docs/appearance/ai-features) preserves ordinary SEO fundamentals and does not require special AI schema or text files. Prioritize crawlable visible facts, internal navigation and structured data matching page content. No ranking, citation or indexing guarantees.
- [Google software app structured data](https://developers.google.com/search/docs/appearance/structured-data/software-app) informs versioned SoftwareApplication facts. Do not invent ratings or reviews to chase eligibility.
- Nine pages have unique metadata, canonical links, current sitemap and navigation. Add a substantive loop guide, versioned downloads, accurate clipboard/pause/AI limits, actual Mac screenshots and visible FAQ parity checks.
- llms.txt and llms-full.txt are optional factual summaries, not special access or ranking mechanisms. Existing crawler policy is unchanged. Repository-subpath robots.txt is not an origin-root crawler control.
- Five interface languages do not imply five translated website editions. No fabricated hreflang pages. Chinese overview and English guides accurately identify the UI locale mapping.
- Keep v1.1.2 stable download links intact. Preview points to the pinned successful workflow with sign-in/expiry instructions; no nonexistent formal release URL.

## Verification and remaining scope

- Mac: 21 core, 40 loop, 1086 localization checks; self-test and 24 native UI renders; reviewed Chinese, German, Japanese and Korean output. Header non-overlap and accessible icon semantics asserted.
- Windows: full existing CI suite passed; owner accepted local appearance before this work.
- Content: nine-page static validator; 71 visible-fact/FAQ/anchor checks; desktop and 375 px local browser journeys. Website source remains unpublished.
- Implementation/evidence: VERIFICATION.md, reviews/REV-20261015-macos-discovery.md, scripts/validate-discovery.py, macOS/TESTING.md.
