# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 22
- Updated: 2026-10-15
- State confidence: high for Windows owner acceptance and both-platform CI/core/UI evidence; Mac native external input remains unverified
- Phase: Mac preview candidate delivered; discovery source prepared; owner Mac acceptance and production release pending

## Repository identity

- Branch: codex/recurring-prompt-loop
- Observed commit: 12dbed9

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: universal Mac 1.2.0-preview.1 ZIP verified; nine-page website and AI-readable facts updated with stable/preview distinction.
- Workstream: `workstreams/2026-10-15-macos-discovery-delivery.md`, paused for owner Mac acceptance after candidate handoff.
- Active review: `reviews/REV-20261015-macos-discovery.md`; header overlap and pause wording findings fixed and independently rechecked.
- Active remediations: loop F002 verified by both-platform core tests; loop F001 wrong-sibling-window rejection remains implemented, pending native Mac acceptance. Unified-window/localization historical records retain their limited evidence.
- Blocking dependencies: none for candidate/source delivery. Native Mac Accessibility, paste/send and physical F8 require a Mac desktop.
- Consequential open decisions: production merge, stable release, site deployment and Developer ID signing/notarization remain owner-controlled. Current user request authorizes feature-branch push and Mac CI after Windows acceptance.

## Handoff

- What changed: Mac header spacing and icon-only theme action fixed; diagnostic UI smoke uses bounded observable clock sampling. Universal app version 1.2.0/build 12001. Website, FAQ/schema, sitemap, README, changelog and llms files describe current preview without changing stable download links or crawler policy.
- Verification evidence: CI 38688961403 at 12dbed9 passed Windows and Mac. Mac: 21 original + 40 loop + 1086 localization checks, self-test, 24 UI renders; x86_64/arm64, ad-hoc signature and archive/hash verified. Windows existing regression suites passed. Nine-page site validator and 71 discovery checks pass; desktop and 375 px browser journeys checked. See `../VERIFICATION.md`.
- Not verified: Mac native external clipboard/paste/send, wrong sibling window rejection, physical F8 routing, every display/DPI/assistive-technology combination, notarization and live site publication.
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input. CI artifacts expire and require GitHub sign-in.
- Release assessment: ready for Mac owner preview testing, not a stable cross-platform release. Windows owner accepted the local redesign. Tracked prior release executable preserved; website source is not deployed.
- Next safe action: owner runs `macOS/TESTING.md` against the delivered ZIP; resolve native findings before requesting formal release/merge.

## Read next

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
