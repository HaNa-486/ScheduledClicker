# PDOS state

- Protocol version: 0.4.0-alpha.1
- State revision: 29
- Updated: 2026-10-15
- State confidence: owner accepted Mac build12004 and Windows targeted tests; exact release/public downloads and deployed site verified; detailed native negative-case coverage not itemized
- Phase: v1.2.0 formally released under owner authorization; public downloads and discovery site deployed and verified

## Repository identity

- Branch: main
- Observed commit: acbc2d057abed2003f0ffccd42f9e173fbe38592

## Product anchors

- Primary user: Windows 11 or macOS 13+ desktop user scheduling fixed-coordinate clicks or bounded recurring prompt input/send sequences
- Product outcome: preserve released one-shot workflow; add same/per-round prompts, first time, completion-relative interval, two captured positions, count/deadline bounds, trial, pause and cancel
- Critical journey: configure → capture input/send positions → confirm → focus → paste → send → wait; cancel prevents remaining steps
- Non-goals: AI/quota/delivery recognition, arbitrary macro scripts, background service, persistence across restart, privilege bypass
- Execution premise: awake/unlocked desktop, stationary visible target window and unchanged chat/input layout

## Current work

- Current slice: Completed v1.2.0 release. Windows informational metadata only; Mac remains accepted build12004. Both apps/checksums and nine-page discovery content are public.
- Workstream: `workstreams/2026-10-15-release-120.md` completed; earlier workstreams paused or historical.
- Active review: `reviews/REV-20261015-release-120.md` completed; independent review passed and delivery finding verified.
- Active remediations: Mac normal functional acceptance and Windows targeted tests confirmed by owner. High wrong-window records retain individual native negative-case evidence gaps; do not relabel those cases verified.
- Blocking dependencies: none for the authorized release; native negative-case evidence remains a documented limitation.
- Consequential decisions: User explicitly authorizes formal publication and download/SEO/AI-discovery updates in this turn. No new signing/notarization credentials requested. See `specs/release-120.md` for release and rollback contract.

## Handoff

- What changed: Published v1.2.0 from 3e03d77, merged PR #3 as acbc2d0; uploaded exact CI Windows EXE/Mac universal ZIP and checksums, updated README, nine pages, structured data, FAQ and AI-readable summaries with direct stable URLs.
- Verification evidence: Source CI 38724830343, PR CI 38724838088, main CI 38725336658 and Pages 38725335990 pass. Four anonymous asset GETs match staged CI bytes/hashes; nine live HTML pages and four discovery files match source text. Tag/main ancestry/tree, versions, browser download view and independent review pass. See `../VERIFICATION.md`.
- Not verified individually: owner acceptance did not itemize wrong-sibling refusal, physical F8 or permission-denial cases; every display/DPI/assistive-technology combination and notarization remain outside evidence.
- Residual risks: fixed coordinates cannot identify changed chat/field semantics; send click does not prove delivery; clipboard is overwritten and may retain prompt; cancellation cannot undo completed input. Stable release assets now provide anonymous downloads; Actions artifacts are no longer the public delivery route.
- Release assessment: published with owner authorization after both-platform functional acceptance and all delivery gates passed. Retain conditionally ready evidence classification; do not claim every native failure case verified. Unsigned/ad-hoc and fixed-coordinate limits remain documented.
- Next safe action: handle any concrete post-release user feedback; collect missing native negative-case evidence before broadening safety claims.

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
