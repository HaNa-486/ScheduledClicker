# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 16
- Updated: 2026-10-13
- State confidence: high for Windows loop source/build/core/UI/native-input evidence; macOS loop source reviewed but uncompiled and runtime unverified
- Phase: multilingual Windows local candidate ready for owner testing; macOS build explicitly deferred

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: 7fb0728

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: fixed visible notices and five-language simple/loop interfaces; runtime language switching preserves prompts and schedules
- Active workstream: `workstreams/2026-10-13-loop-input.md`
- Active review: `reviews/REV-20261013-localization.md`; independent privacy/authorization review plus macOS rectangle correction re-review complete
- Active remediations: localization F001 macOS status overlap implemented (native pending); F002 focus-dependent test failure verified fixed. Prior loop F001/F002 remain unverified across platforms.
- Blocking dependencies: no local macOS compiler; user explicitly deferred all public push/macOS builds until Windows testing and review are complete. No permission question is pending.
- Consequential open decisions: public branch/PR publication, final merge/release, signing/notarization remain owner-controlled

## Handoff

- What changed: shared embedded catalog with 206 source keys and five languages; system UI language routing; both mode selectors synchronize within the process; prompts/caret/configuration/active work preserved. Loop notices fixed above actions and visible at initial/minimum size. Mac status overlap corrected. User-reported test-only dialog error fixed by direct dialog reference and invisible fail-fast fixtures.
- Verification evidence: Windows build; 1166 localization/catalog/startup/state/layout/dialog checks; 40 loop core, 10 original core and navigation/clock tests pass. Native Windows UI renders inspected across all five languages. Shared catalog generated-file/placeholder check passes. Independent privacy/authorization review found no lost disclosures or unintended execution; Mac rectangle correction re-reviewed by source.
- Not verified: macOS compilation, 40 Swift tests, new Aqua/Dark Aqua loop renders, native clipboard/paste/send/F8 and wrong-sibling-window rejection; all mixed-DPI scenarios
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input; unsigned/ad-hoc-signed distribution
- Release assessment: not-ready for cross-platform release; Windows candidate available locally; existing tracked release executable preserved
- Next safe action: owner tests the Windows multilingual candidate locally and reports review findings; only after a later explicit request, build/verify macOS. Do not push or start macOS CI now.

## Read next

- `specs/localization.md` - current locale/layout contract and delivery constraint
- `reviews/REV-20261013-localization.md` - latest findings and acceptance
- `AUTONOMY.md` - project decision boundaries
- `specs/loop-input.md` - authorized behavior and acceptance
- `specs/product.md` - updated scope
- `plans/active.md` - current slice
- `reviews/REV-20261013-loop-input.md` - independent source findings
- `remediations/REM-20261013-loop-input-F001.md` - focused-window correction and pending native acceptance
- `remediations/REM-20261013-loop-input-F002.md` - completion-clock correction and platform evidence
- `../VERIFICATION.md` - current and historical verification separated
