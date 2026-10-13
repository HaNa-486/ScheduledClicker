# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 17
- Updated: 2026-10-13
- State confidence: high for Windows loop source/build/core/UI/native-input evidence; macOS loop source reviewed but uncompiled and runtime unverified
- Phase: unified-window Windows local candidate ready for owner testing; macOS build explicitly deferred

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: ae5d546

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: single shared window, consistent two-mode layout, all loop settings initially visible; five-language routing retained
- Active workstream: `workstreams/2026-10-13-loop-input.md`
- Active review: `reviews/REV-20261013-unified-window.md`; independent lifecycle/concurrency/privacy source review complete
- Active remediations: unified-window F001 implemented and Windows verified, Mac pending; localization F001 macOS status overlap implemented (native pending); F002 focus-dependent test failure verified fixed. Prior loop F001/F002 remain unverified across platforms.
- Blocking dependencies: no local macOS compiler; user explicitly deferred all public push/macOS builds until Windows testing and review are complete. No permission question is pending.
- Consequential open decisions: public branch/PR publication, final merge/release, signing/notarization remain owner-controlled

## Handoff

- What changed: one shared native window and header; loop timing left, capture positions right, prompt area below and fixed notices/actions/status. No settings page scrollbar. Idle switching retains state; active/paused execution or capture blocks switching until stopped; close cancels. Shared catalog now has 211 keys. Mac source follows the same structure.
- Verification evidence: Windows build; 2050 localization/catalog/startup/state/layout/dialog checks; 40 loop core, 10 original core and shared-window navigation/lifecycle checks pass. Five-language renders generated and Chinese/English/German visually inspected. Disposable native shared-host trial passes paste/replace/send, registered hotkey queued cancellation, mode reuse and close cancellation. Catalog consistency check passes; independent source review found no concrete defect.
- Not verified: macOS compilation, 40 Swift tests, new Aqua/Dark Aqua loop renders, native clipboard/paste/send/F8 and wrong-sibling-window rejection; physical-key F8 routing in the unified host; all mixed-DPI and small-desktop scenarios
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input; unsigned/ad-hoc-signed distribution
- Release assessment: not-ready for cross-platform release; Windows candidate available locally; existing tracked release executable preserved
- Next safe action: owner tests the Windows unified-window candidate locally and reports review findings; only after a later explicit request, build/verify macOS. Do not push or start macOS CI now.

## Read next

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
