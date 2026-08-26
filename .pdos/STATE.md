# PDOS state

Keep this concise. Every fresh PDOS context reads it first.

- Protocol version: 0.4.0-alpha.1
- State revision: 2
- Updated: 2026-08-26
- State confidence: high for source/build; conditional for live mouse injection
- Phase: handoff

## Repository identity

- Branch: master
- Observed commit: 2f160c81c0fd78a7a161d4e08af5aa04bd1ad41b

## Product anchors

- Primary user: Windows 11 desktop user scheduling a one-time fixed-coordinate click
- Product outcome: standalone Traditional Chinese WinForms EXE with clock, absolute/delay scheduling, capture, single/double click, cancellation
- Critical journey: configure → capture → confirm → countdown → click, with cancel/F8 safety path
- Non-goals: visual button recognition, recurring macros, background service, persistence across restart, privilege bypass

## Current work

- Current slice: v1.0 local delivery completed
- Active workstreams: see `workstreams/`
- Active review:
- Active remediations:
- Blocking dependencies: live SendInput journey cannot run inside Codex isolated desktop
- Consequential open decisions: code signing only if the user later wants public distribution

## Handoff

- What changed: built source, tests, docs, manifest, build script, and standalone dist/ScheduledClicker.exe
- Verification evidence: VERIFICATION.md; 10/10 core tests; startup smoke pass; Defender no threats; independent review fixes applied
- Not verified: live click landing on a real user desktop due sandbox access denied
- Residual risks: unsigned executable; fixed coordinates can target changed UI; UIPI blocks higher-integrity windows; live and mixed-DPI click landing await user desktop verification
- Next safe action: user runs a harmless 10-second single-click and double-click test on their Windows 11 desktop

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/product.md` - product anchors and scope
- `plans/active.md` - current implementation plan
