# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 28
- Updated: 2026-10-15
- State confidence: owner reports all Mac build12004 functions usable; Windows redesign accepted earlier; detailed negative-case coverage not itemized
- Phase: owner accepted both platforms and explicitly authorized v1.2.0 release, merge and website updates; release preparation in progress

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: 0f254f8

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: Publish accepted runtime as v1.2.0; Windows informational metadata only, Mac remains accepted build12004. Add exact CI Windows artifact/checksum and align all public download/discovery content.
- Workstream: `workstreams/2026-10-15-release-120.md` active; earlier workstreams paused or historical.
- Active review: `reviews/REV-20261015-release-120.md`; independent read-only release review required, final artifact/link verification pending.
- Active remediations: Mac normal functional acceptance and Windows targeted tests confirmed by owner. High wrong-window records retain individual native negative-case evidence gaps; do not relabel those cases verified.
- Blocking dependencies: successful final CI, artifact checks and independent review before publication; live asset/site verification afterward.
- Consequential decisions: User explicitly authorizes formal publication and download/SEO/AI-discovery updates in this turn. No new signing/notarization credentials requested. See `specs/release-120.md` for release and rollback contract.

## Handoff

- What changed: Build12004 replaces CG first-rectangle owner selection with original AX hit-window/topLevel identity and same-API bounds; all steps revalidate against the captured window. Capture permission request precedes countdown, failed recapture clears that side. Same-frame sibling rebinding is rejected. Exact candidate download and AI summary updated.
- Verification evidence: CI 38718545337 at 8943758 both platforms pass. Mac 21/54 core, 31 capture/focus policy, 15 numbers, 1116 localization and 24 renders; Windows full regression plus 2102 localization. Downloaded build12004 ZIP hash/version checked; independent source review passes. See `../VERIFICATION.md`.
- Not verified individually: owner acceptance did not itemize wrong-sibling refusal, physical F8 or permission-denial cases; every display/DPI/assistive-technology combination, notarization and live site publication remain outside evidence.
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input. CI artifacts expire and require GitHub sign-in.
- Release assessment: conditionally ready subject to exact CI/artifact and live-link gates. Owner authorizes release after both-platform functional acceptance; do not claim every native failure case verified. Unsigned/ad-hoc and fixed-coordinate limits remain documented.
- Next safe action: finish CI and independent review, stage the exact release assets, merge and publish under owner authorization, then verify public downloads and deployed site.

## Read next

- `specs/release-120.md` and `reviews/REV-20261015-release-120.md` - current release evidence and scope

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
