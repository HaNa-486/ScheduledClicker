# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 24
- Updated: 2026-10-15
- State confidence: high for Windows owner acceptance and both-platform CI/core/UI evidence; Mac native external input remains unverified
- Phase: preview.2 native retest failed; foreground diagnosis and activation correction in progress, no release

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: d07f0cf

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: Owner confirms new app replaced, caret visible, Safari and Word fail with complete no-code focus message. Under build12002 this maps to NSWorkspace foreground PID guard; wrong captured owner vs foreground-state discrepancy remain unproven. Add live AX keyboard-owner check, separate bounded activation phase and content-free diagnostics.
- Workstream: `workstreams/2026-10-15-macos-foreground-diagnosis.md` active; earlier workstreams paused.
- Active review: `reviews/REV-20261015-macos-input.md`; independent focus/privacy source recheck passes, no native Safari claim.
- Active remediations: localized starter F002 verified; focus F001 and wheel F003 implemented pending owner native acceptance. Earlier loop wrong-window F001 remains unverified.
- Blocking dependencies: none for candidate/source delivery. Native Mac Accessibility, paste/send and physical F8 require a Mac desktop.
- Consequential open decisions: production merge, stable release, site deployment and Developer ID signing/notarization remain owner-controlled. Current user request authorizes feature-branch push and Mac CI after Windows acceptance.

## Handoff

- What changed: preview.2 / Mac build 12002 uses AX owning-window identity and top-level checks, content-free focus diagnostics, localized untouched starter prompts on both platforms and bounded Mac wheel number fields. Discovery source/download links updated to this candidate.
- Verification evidence: CI 38696929654 at 7a75cba both platforms pass. Mac 21/40 core, 9 focus-policy, 15 number-field, 1091 localization checks and 24 UI renders; Windows full regression plus 2077 localization checks. ZIP hash/version verified. See `../VERIFICATION.md`.
- Not verified: Mac native external clipboard/paste/send, wrong sibling window rejection, physical F8 routing, every display/DPI/assistive-technology combination, notarization and live site publication.
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input. CI artifacts expire and require GitHub sign-in.
- Release assessment: native Mac loop acceptance failed on preview.1; preview.2 also failed Safari and Word native retest, not a stable cross-platform release. Windows owner accepted the local redesign. Tracked prior release executable preserved; website source is not deployed.
- Next safe action: owner repeats Safari trial and sibling-window refusal using preview.2/build 12002, plus numeric wheel and untouched prompt language checks; no formal release until accepted.

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
