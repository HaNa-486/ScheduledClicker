# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 27
- Updated: 2026-10-15
- State confidence: owner reports all Mac build12004 functions usable; Windows redesign accepted earlier; detailed negative-case coverage not itemized
- Phase: owner reports Mac build12004 functional acceptance; no release authorized

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: b3ef835

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: Build12003 native diagnostic confirms target was Dock at layer20; activation then failed geometry before click. Root cause is CG bounding-rectangle first-hit selecting compositor owner, amplified by activation. Replace capture with stored AX hit-window/topLevel identity and same-API bounds; build12004 CI and artifact verification pass; owner now reports all Mac functions work normally.
- Workstream: `workstreams/2026-10-15-macos-ax-target-capture.md` paused for native acceptance; earlier workstreams paused.
- Active review: `reviews/REV-20261015-macos-input.md`; independent focus/privacy source recheck passes, no native Safari claim.
- Active remediations: localized starter F002 verified; focus F001, foreground F004, target capture F005 and wheel F003 implemented with broad owner functional acceptance; individual negative-case acceptance remains unitemized. Earlier loop wrong-window F001 remains unverified.
- Blocking dependencies: none for candidate/source delivery. Native Mac Accessibility, paste/send and physical F8 require a Mac desktop.
- Consequential open decisions: production merge, stable release, site deployment and Developer ID signing/notarization remain owner-controlled. Current user request authorizes feature-branch push and Mac CI after Windows acceptance.

## Handoff

- What changed: Build12004 replaces CG first-rectangle owner selection with original AX hit-window/topLevel identity and same-API bounds; all steps revalidate against the captured window. Capture permission request precedes countdown, failed recapture clears that side. Same-frame sibling rebinding is rejected. Exact candidate download and AI summary updated.
- Verification evidence: CI 38718545337 at 8943758 both platforms pass. Mac 21/54 core, 31 capture/focus policy, 15 numbers, 1116 localization and 24 renders; Windows full regression plus 2102 localization. Downloaded build12004 ZIP hash/version checked; independent source review passes. See `../VERIFICATION.md`.
- Not verified individually: owner acceptance did not itemize wrong-sibling refusal, physical F8 or permission-denial cases; every display/DPI/assistive-technology combination, notarization and live site publication remain outside evidence.
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input. CI artifacts expire and require GitHub sign-in.
- Release assessment: native Mac loop acceptance failed on preview.1; preview.2 also failed Safari and Word native retest, build12003 also failed with confirmed Dock miscapture. Owner now reports all build12004 Mac functions working. This is functional owner acceptance, not formal release authorization. Windows owner accepted the local redesign. Tracked prior release executable preserved; website source is not deployed.
- Next safe action: If the Windows untouched-starter localization change has not been owner-tested, perform a short language/custom-prompt check; wait for explicit release instruction before merge/publish.

## Read next

- `specs/macos-input-repair.md` and `reviews/REV-20261015-macos-input.md` - current repair contract and limitations

- `specs/macos-preview-discovery.md` - current delivery contract, research and evidence
- `reviews/REV-20261015-macos-discovery.md` - current independent review

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
