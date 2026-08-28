# PDOS state

Keep this concise. Every fresh PDOS context reads it first.

- Protocol version: 0.4.0-alpha.1
- State revision: 8
- Updated: 2026-08-28
- State confidence: high for source/build, cross-platform automated verification, user-reported Windows 11 and macOS click journeys, and Aqua/Dark Aqua render evidence; v1.1.1 physical-Mac visual confirmation remains pending
- Phase: v1.1.1 macOS dark-mode UX patch published

## Repository identity

- Branch: main
- Observed commit: 94da9bc03a52baa9430cc5c1b6970eea34d05f00

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling a one-time fixed-coordinate click
- Product outcome: separate native Windows EXE and universal macOS app with clock, absolute/delay scheduling, capture, single/double click, cancellation
- Critical journey: configure → capture → confirm → countdown → click, with cancel/F8 safety path
- Non-goals: visual button recognition, recurring macros, background service, persistence across restart, privilege bypass

## Current work

- Current slice: v1.1.1 release published with the macOS Dark Aqua fix, improved scheduling UX, appearance evidence, and updated SEO/AI metadata
- Active workstreams: see `workstreams/`
- Active review: `reviews/REV-20260828-macos-dark-mode-ux.md` verified
- Active remediations: `remediations/REM-20260828-macos-dark-mode-ux-F001.md` verified
- Blocking dependencies: macOS real pointer injection requires a Mac owner to grant Accessibility permission; Apple notarization requires an Apple Developer ID and owner credentials
- Consequential open decisions: Apple Developer ID signing/notarization, external community promotion, and future Windows code signing remain owner-controlled

## Handoff

- What changed: replaced the fixed macOS light background with adaptive AppKit rendering, simplified the time-mode selector and conditional fields, improved hierarchy/status/accessibility, added Aqua/Dark Aqua contrast/visibility smoke tests and PNG capture, published v1.1.1 assets, and updated README/CHANGELOG/site/AI metadata
- Verification evidence: VERIFICATION.md; candidate CI run 33139685219 and main CI run 33139950734; Windows 10/10 and macOS 21/21 tests; Aqua/Dark Aqua smoke tests and human PNG review; universal/codesign/archive/SHA-256 checks; Defender no matching Windows threat; independent release review found no blocking issue; public assets downloaded and re-hashed
- Not verified: v1.1.1 visual confirmation on the user's physical MacBook Air; every Windows mixed-DPI combination; Google index inclusion timing
- Residual risks: Windows is unsigned and macOS is ad-hoc signed/not notarized; fixed coordinates can target changed content even when display geometry is stable; Windows UIPI blocks higher-integrity targets; sleeping/locked desktops cannot click
- Next safe action: ask the user to download v1.1.1 and confirm both time modes and the new Dark appearance on the same MacBook Air

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/product.md` - product anchors and scope
- `plans/active.md` - current implementation plan
- `reviews/REV-20260828-macos-dark-mode-ux.md` - verified finding and evidence
- `remediations/REM-20260828-macos-dark-mode-ux-F001.md` - verified fix lifecycle
