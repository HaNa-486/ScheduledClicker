# PDOS state

Keep this concise. Every fresh PDOS context reads it first.

- Protocol version: 0.4.0-alpha.1
- State revision: 5
- Updated: 2026-08-26
- State confidence: high for source/build and user-reported Windows 11 journeys; mixed-DPI combinations remain partially verified
- Phase: GitHub release and search landing page published

## Repository identity

- Branch: main
- Observed commit: 472a6c0f2ee9017b81780b2e83e80ff81dbe424d

## Product anchors

- Primary user: Windows 11 desktop user scheduling a one-time fixed-coordinate click
- Product outcome: standalone Traditional Chinese WinForms EXE with clock, absolute/delay scheduling, capture, single/double click, cancellation
- Critical journey: configure → capture → confirm → countdown → click, with cancel/F8 safety path
- Non-goals: visual button recognition, recurring macros, background service, persistence across restart, privilege bypass

## Current work

- Current slice: v1.0 release, GitHub Pages, repository metadata, and AI/Google discovery assets published
- Active workstreams: see `workstreams/`
- Active review:
- Active remediations:
- Blocking dependencies: Google indexing is asynchronous; Search Console submission needs owner Google verification; GitHub repository social-preview upload needs a signed-in web session
- Consequential open decisions: Search Console ownership, external community promotion, and future code signing remain owner-controlled

## Handoff

- What changed: added bilingual discovery copy, FAQ, GitHub About/topics/homepage, v1.0.0 Release asset, GitHub Pages landing page, social card, JSON-LD, sitemap, robots.txt, and llms.txt
- Verification evidence: VERIFICATION.md; 10/10 core tests; startup smoke pass; Defender no threats; independent review fixes; user reported both absolute and delay modes successful on Windows 11
- Not verified: every mixed-DPI multi-monitor combination; Google index inclusion; GitHub repository-level social preview image
- Residual risks: unsigned executable; fixed coordinates can target changed UI; UIPI blocks higher-integrity windows
- Next safe action: owner signs into GitHub web to upload docs/social-preview.png as the repository social preview and verifies the Pages URL in Google Search Console

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/product.md` - product anchors and scope
- `plans/active.md` - current implementation plan
