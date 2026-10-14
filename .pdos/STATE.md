# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 20
- Updated: 2026-10-14
- State confidence: high for Windows loop source/build/core/UI/native-input evidence; macOS loop source reviewed but uncompiled and runtime unverified
- Phase: redesigned light/dark Windows local candidate ready for owner testing; macOS build explicitly deferred

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: 2256843

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: research-led visual redesign of both themes, compact accessible appearance action and coherent controls
- Active workstream: `workstreams/2026-10-14-visual-redesign.md`; prior loop work remains paused for owner/Mac validation
- Active review: `reviews/REV-20261013-unified-window.md`; independent lifecycle/concurrency/privacy source review complete
- Active remediations: unified-window F001 implemented and Windows verified, Mac pending; localization F001 macOS status overlap implemented (native pending); F002 focus-dependent test failure verified fixed. Prior loop F001/F002 remain unverified across platforms.
- Blocking dependencies: no local macOS compiler; user explicitly deferred all public push/macOS builds until Windows testing and review are complete. No permission question is pending.
- Consequential open decisions: public branch/PR publication, final merge/release, signing/notarization remain owner-controlled

## Handoff

- What changed: Research-led neutral surfaces, rounded cards/buttons, subdued navigation and notices, compact localized sun/moon action. Themed date fields validate explicit date text before scheduling and support caret-segment adjustments. 214 translation keys. Mac source uses native semantic surfaces and SF Symbols; uncompiled.
- Verification evidence: Windows build; 153 appearance/startup/contrast/state checks and 30 renders; 2066 localization/layout checks; 15 native picker interactions; 20 date validation/rollover/plan-preservation checks; shared-window lifecycle, 40 loop core and 10 original core checks pass. Dark/light and German renders inspected; catalog check passes. Input engine unchanged; no new external input evidence claimed.
- Not verified: macOS compilation, 40 Swift tests, new Aqua/Dark Aqua loop renders, native clipboard/paste/send/F8 and wrong-sibling-window rejection; physical-key F8 routing in the unified host; all mixed-DPI and small-desktop scenarios
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input; unsigned/ad-hoc-signed distribution
- Release assessment: not-ready for cross-platform release; Windows local candidate only, aesthetic acceptance pending; tracked release executable preserved. Native scrollbars/system parts remain OS rendered.
- Next safe action: owner tests the redesigned Windows candidate locally and reports aesthetic/interaction findings; only after a later explicit request, build/verify macOS. Do not push or start macOS CI now.

## Read next

- `specs/visual-design.md` - research, design decisions, changed date editor contract and acceptance

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
