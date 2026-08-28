# PDOS state

Keep this concise. Every fresh PDOS context reads it first.

- Protocol version: 0.4.0-alpha.1
- State revision: 13
- Updated: 2026-08-28
- State confidence: high for source/build, cross-platform automated verification, user-reported Windows 11 and macOS click journeys, Aqua/Dark Aqua render evidence, and v1.1.2 three-digit clock animation on a physical MacBook Air
- Phase: website navigation and download-contrast fix deployed and publicly verified

## Repository identity

- Branch: main
- Observed commit: 6606f51e971e39471ba2920a462bcaae160d6aed

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling a one-time fixed-coordinate click
- Product outcome: separate native Windows EXE and universal macOS app with clock, absolute/delay scheduling, capture, single/double click, cancellation
- Critical journey: configure → capture → confirm → countdown → click, with cancel/F8 safety path
- Non-goals: visual button recognition, recurring macros, background service, persistence across restart, privilege bypass

## Current work

- Current slice: consistent two-tier navigation and readable download calls to action across all eight discovery pages
- Active workstreams: see `workstreams/`
- Active review: `reviews/REV-20260828-site-navigation-contrast.md` closed; independent final re-review found no remaining findings
- Active remediations: navigation F001 and download-contrast F002 are verified
- Blocking dependencies: macOS real pointer injection requires a Mac owner to grant Accessibility permission; Apple notarization requires an Apple Developer ID and owner credentials
- Consequential open decisions: Apple Developer ID signing/notarization, external community promotion, and future Windows code signing remain owner-controlled

## Handoff

- What changed: normalized both navigation tiers on every page, added accurate current-page/focus states, exposed every detailed destination at narrow widths, restored high-contrast download-button text, and extended static regression checks to URLs and `aria-current`.
- Verification evidence: PR #1; candidate CI 33163921638/33163951291; main CI 33164047528; Pages deployment 33164047159; eight-page public-site crawl; desktop and 375 px browser journeys; no page overflow; all seven detailed destinations visible; download buttons measured at 10.10:1 minimum contrast with visible focus outline; independent re-review no findings.
- Not verified: every Windows mixed-DPI combination; Google index inclusion/ranking timing
- Residual risks: Windows is unsigned and macOS is ad-hoc signed/not notarized; fixed coordinates can target changed content even when display geometry is stable; Windows UIPI blocks higher-integrity targets; sleeping/locked desktops cannot click
- Next safe action: no website blocker remains; monitor real-user feedback and keep future site changes on the branch → PR → CI → review → merge path

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/product.md` - product anchors and scope
- `plans/active.md` - current implementation plan
- `reviews/REV-20260828-site-navigation-contrast.md` - verified website findings and evidence
- `remediations/REM-20260828-site-navigation-contrast-F001.md` - verified navigation lifecycle
- `remediations/REM-20260828-site-navigation-contrast-F002.md` - verified contrast lifecycle
