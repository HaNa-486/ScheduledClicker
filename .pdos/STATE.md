# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 19
- Updated: 2026-10-14
- State confidence: high for Windows loop source/build/core/UI/native-input evidence; macOS loop source reviewed but uncompiled and runtime unverified
- Phase: light/dark Windows local candidate ready for owner testing; macOS build explicitly deferred

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: 45c2ee9

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: system-selected startup appearance and manual light/dark button shared by both modes and dialogs
- Active workstream: `workstreams/2026-10-14-appearance.md`; prior loop work remains paused for owner/Mac validation
- Active review: `reviews/REV-20261013-unified-window.md`; independent lifecycle/concurrency/privacy source review complete
- Active remediations: unified-window F001 implemented and Windows verified, Mac pending; localization F001 macOS status overlap implemented (native pending); F002 focus-dependent test failure verified fixed. Prior loop F001/F002 remain unverified across platforms.
- Blocking dependencies: no local macOS compiler; user explicitly deferred all public push/macOS builds until Windows testing and review are complete. No permission question is pending.
- Consequential open decisions: public branch/PR publication, final merge/release, signing/notarization remain owner-controlled

## Handoff

- What changed: Windows reads current app theme at launch; header toggle switches both modes and owned dialogs for this session. Themes cover app backgrounds, text, notices, state colors and disabled controls. Native date/time and some system control parts retain Windows rendering. 213 translation keys. Mac source snapshots appearance and adds manual Aqua/Dark Aqua switching, uncompiled.
- Verification evidence: Windows build; 153 appearance/startup/contrast/state checks and 30 renders; 2061 localization/layout checks; 15 native picker interactions; shared-window lifecycle, 40 loop core and 10 original core checks pass. Dark/light renders inspected, including disabled controls and German confirmation. Catalog check passes. Existing native input evidence remains historical; input engine unchanged.
- Not verified: macOS compilation, 40 Swift tests, new Aqua/Dark Aqua loop renders, native clipboard/paste/send/F8 and wrong-sibling-window rejection; physical-key F8 routing in the unified host; all mixed-DPI and small-desktop scenarios
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input; unsigned/ad-hoc-signed distribution
- Release assessment: not-ready for cross-platform release; Windows candidate available locally; existing tracked release executable preserved; native control parts retain system rendering
- Next safe action: owner tests the Windows appearance candidate locally and reports review findings; only after a later explicit request, build/verify macOS. Do not push or start macOS CI now.

## Read next

- `specs/appearance.md` - startup theme, manual toggle and native appearance boundaries
- `specs/unified-window.md` - current shared-window/layout contract
- `reviews/REV-20261013-unified-window.md` - latest review and evidence
- `specs/localization.md` - locale contract and delivery constraint
- `reviews/REV-20261013-localization.md` - prior findings and acceptance
- `AUTONOMY.md` - project decision boundaries
- `specs/loop-input.md` - authorized behavior and acceptance
- `specs/product.md` - updated scope
- `plans/active.md` - current slice
- `reviews/REV-20261013-loop-input.md` - independent source findings
- `remediations/REM-20261013-loop-input-F001.md` - focused-window correction and pending native acceptance
- `remediations/REM-20261013-loop-input-F002.md` - completion-clock correction and platform evidence
- `../VERIFICATION.md` - current and historical verification separated
