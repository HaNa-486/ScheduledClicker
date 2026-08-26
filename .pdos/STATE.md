# PDOS state

Keep this concise. Every fresh PDOS context reads it first.

- Protocol version: 0.4.0-alpha.1
- State revision: 6
- Updated: 2026-08-26
- State confidence: high for source/build, cross-platform automated verification, and user-reported Windows 11 journeys; macOS interactive Accessibility-authorized clicking remains unverified
- Phase: v1.1.0 Windows + macOS release published

## Repository identity

- Branch: main
- Observed commit: 6ca814860fdf00d36b4db71af103713f0585b321

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling a one-time fixed-coordinate click
- Product outcome: separate native Windows EXE and universal macOS app with clock, absolute/delay scheduling, capture, single/double click, cancellation
- Critical journey: configure → capture → confirm → countdown → click, with cancel/F8 safety path
- Non-goals: visual button recognition, recurring macros, background service, persistence across restart, privilege bypass

## Current work

- Current slice: v1.1.0 Windows + macOS release, CI, security evidence, GitHub Pages, and AI/Google discovery updates published
- Active workstreams: see `workstreams/`
- Active review:
- Active remediations:
- Blocking dependencies: macOS real pointer injection requires a Mac owner to grant Accessibility permission; Apple notarization requires an Apple Developer ID and owner credentials
- Consequential open decisions: Apple Developer ID signing/notarization, external community promotion, and future Windows code signing remain owner-controlled

## Handoff

- What changed: added native Swift/AppKit/Quartz macOS 13+ edition, universal Intel/Apple-silicon packaging, Accessibility permission checks, display-configuration fail-closed behavior, cross-platform CI, v1.1.0 release assets, dual-platform docs/SEO/AI metadata, and a refreshed social card
- Verification evidence: VERIFICATION.md; main CI run 32961884730; Windows 10/10 and macOS 21/21 tests; macOS self-test/plist/universal-architecture/ad-hoc-codesign/archive/SHA-256 checks; Defender no matching Windows threat; independent security review findings resolved; released assets downloaded and re-hashed
- Not verified: macOS physical interactive single/double click with Accessibility permission; every Windows mixed-DPI combination; Google index inclusion timing
- Residual risks: Windows is unsigned and macOS is ad-hoc signed/not notarized; fixed coordinates can target changed content even when display geometry is stable; Windows UIPI blocks higher-integrity targets; sleeping/locked desktops cannot click
- Next safe action: a Mac owner tests exact-time and delay modes on a harmless target, then reports macOS version, Mac architecture, and results

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/product.md` - product anchors and scope
- `plans/active.md` - current implementation plan
