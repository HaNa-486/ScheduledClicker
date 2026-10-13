# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 15
- Updated: 2026-10-13
- State confidence: high for Windows loop source/build/core/UI/native-input evidence; macOS loop source reviewed but uncompiled and runtime unverified
- Phase: bounded recurring input implemented locally; macOS verification pending

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: 5f05ffe

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: recurring input plus user-requested return-to-simple navigation and fixed live digital clock on both native platforms
- Active workstream: `workstreams/2026-10-13-loop-input.md`
- Active review: `reviews/REV-20261013-loop-input.md`; independent re-review found no further definite source defects
- Active remediations: F001 focused macOS window and F002 completion-clock timing implemented; not marked verified across platforms
- Blocking dependencies: no local macOS compiler; public feature-branch push/CI awaits owner approval at handoff; macOS real input requires Accessibility-enabled desktop
- Consequential open decisions: public branch/PR publication, final merge/release, signing/notarization remain owner-controlled

## Handoff

- What changed: loop windows now have a fixed live clock and explicit return button; returning stops capture/loop and restores simple UI; reopening retains in-memory configuration and restarts timer. Prior loop capabilities retained.
- Verification evidence: Windows build; 40/40 loop core and 10/10 original tests; UI test verifies visible return button, advancing fixed clock, return cancellation, retained settings and timer on modal reopen; updated renders inspected; independent lifecycle review found no actionable defects. Prior two-round native input evidence remains applicable; no input-engine changes this follow-up.
- Not verified: macOS compilation, 40 Swift tests, new Aqua/Dark Aqua loop renders, native clipboard/paste/send/F8 and wrong-sibling-window rejection; all mixed-DPI scenarios
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input; unsigned/ad-hoc-signed distribution
- Release assessment: not-ready for cross-platform release; Windows candidate available locally; existing tracked release executable preserved
- Next safe action: obtain permission to publish feature branch for macOS CI, then run build/tests/render verification and native Mac acceptance before release decisions

## Read next

- `AUTONOMY.md` - project decision boundaries
- `specs/loop-input.md` - authorized behavior and acceptance
- `specs/product.md` - updated scope
- `plans/active.md` - current slice
- `reviews/REV-20261013-loop-input.md` - independent source findings
- `remediations/REM-20261013-loop-input-F001.md` - focused-window correction and pending native acceptance
- `remediations/REM-20261013-loop-input-F002.md` - completion-clock correction and platform evidence
- `../VERIFICATION.md` - current and historical verification separated
