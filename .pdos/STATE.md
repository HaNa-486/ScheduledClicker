# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 30
- Updated: 2026-10-15
- State confidence: owner accepted Mac build12004 and Windows targeted tests; exact release/public downloads and deployed site verified; detailed native negative-case coverage not itemized
- Phase: Implementing owner-authorized five-language first-use website; publish after verification. v1.2.0 runtime remains unchanged.

## Repository identity

- Branch: codex/multilingual-install-guide
- Observed commit: 2e1f82a

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: Fix warning-specific opening help, direct install anchors, checksum instructions, five full website languages and support entry points; synchronize discovery.
- Workstream: `workstreams/2026-10-15-multilingual-install-guide.md` active; release-120 completed.
- Active review: `reviews/REV-20261015-site-first-use.md`; five findings authorized, independent safety/discovery review in progress.
- Active remediations: Mac normal functional acceptance and Windows targeted tests confirmed by owner. High wrong-window records retain individual native negative-case evidence gaps; do not relabel those cases verified.
- Blocking dependencies: Browser validation, independent review and CI before deployment; verify live localized pages afterward.
- Consequential decisions: Owner explicitly authorizes these website fixes and publication after checks; signing and Search Console deferred. See specs/multilingual-install-guide.md.

## Handoff

- What changed: Published v1.2.0 from 3e03d77, merged PR #3 as acbc2d0; uploaded exact CI Windows EXE/Mac universal ZIP and checksums, updated README, nine pages, structured data, FAQ and AI-readable summaries with direct stable URLs.
- Verification evidence: Source CI 38724830343, PR CI 38724838088, main CI 38725336658 and Pages 38725335990 pass. Four anonymous asset GETs match staged CI bytes/hashes; nine live HTML pages and four discovery files match source text. Tag/main ancestry/tree, versions, browser download view and independent review pass. See `../VERIFICATION.md`.
- Not verified individually: owner acceptance did not itemize wrong-sibling refusal, physical F8 or permission-denial cases; every display/DPI/assistive-technology combination and notarization remain outside evidence.
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input. Stable release assets now provide anonymous downloads; Actions artifacts are no longer the public delivery route.
- Release assessment: published with owner authorization after both-platform functional acceptance and all delivery gates passed. Retain conditionally ready evidence classification; do not claim every native failure case verified. Unsigned/ad-hoc and fixed-coordinate limits remain documented.
- Next safe action: Finish browser and independent review, repair any blockers, publish and verify live locale pages.

## Read next

- `specs/multilingual-install-guide.md` and `reviews/REV-20261015-site-first-use.md` - current website scope and review

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
