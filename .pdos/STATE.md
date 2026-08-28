# PDOS state

Keep this concise. Every fresh PDOS context reads it first.

- Protocol version: 0.4.0-alpha.1
- State revision: 10
- Updated: 2026-08-28
- State confidence: high for source/build, cross-platform automated verification, user-reported Windows 11 and macOS click journeys, and Aqua/Dark Aqua render evidence; v1.1.2 clock animation physical-Mac confirmation remains pending
- Phase: v1.1.2 published and public assets/pages verified

## Repository identity

- Branch: main
- Observed commit: bee4fa37f37b2acf87faf0b6e2421c7c8233482a

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling a one-time fixed-coordinate click
- Product outcome: separate native Windows EXE and universal macOS app with clock, absolute/delay scheduling, capture, single/double click, cancellation
- Critical journey: configure → capture → confirm → countdown → click, with cancel/F8 safety path
- Non-goals: visual button recognition, recurring macros, background service, persistence across restart, privilege bypass

## Current work

- Current slice: v1.1.2 published with macOS millisecond animation fix and eight focused, validated discovery pages
- Active workstreams: see `workstreams/`
- Active review: `reviews/REV-20260828-clock-release-discovery.md` closed; independent release review found no remaining findings
- Active remediations: F001 clock, F002 release formatting, and F003 discovery are verified
- Blocking dependencies: macOS real pointer injection requires a Mac owner to grant Accessibility permission; Apple notarization requires an Apple Developer ID and owner credentials
- Consequential open decisions: Apple Developer ID signing/notarization, external community promotion, and future Windows code signing remain owner-controlled

## Handoff

- What changed: raised the macOS clock UI to about 30 Hz with cached formatters and sub-hundredth smoke validation; corrected v1.1.1 Release formatting and GitHub metadata; added platform, Codex, safety, download, FAQ, and changelog pages with real UI renders, schema, sitemap, and AI summaries
- Verification evidence: VERIFICATION.md; candidate CI 33143381799/33143876718 and main CI 33155119817; Windows 10/10 and macOS 21/21; Aqua/Dark Aqua and clock-animation smoke tests; universal/codesign/archive/SHA-256; site validator; Defender; independent review no findings; public assets re-hashed; live Pages crawl 200
- Not verified: v1.1.2 clock animation on the user's physical MacBook Air; every Windows mixed-DPI combination; Google index inclusion/ranking timing
- Residual risks: Windows is unsigned and macOS is ad-hoc signed/not notarized; fixed coordinates can target changed content even when display geometry is stable; Windows UIPI blocks higher-integrity targets; sleeping/locked desktops cannot click
- Next safe action: ask the user to test v1.1.2 clock animation on the same MacBook Air; Google indexing and ranking remain external and asynchronous

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/product.md` - product anchors and scope
- `plans/active.md` - current implementation plan
- `reviews/REV-20260828-clock-release-discovery.md` - verified findings and evidence
- `remediations/REM-20260828-clock-release-discovery-F001.md` - verified clock fix lifecycle
