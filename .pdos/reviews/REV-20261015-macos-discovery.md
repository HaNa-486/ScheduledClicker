# Review: Mac preview and discovery delivery

- Review ID: REV-20261015-macos-discovery
- Mode: review-and-fix
- Status: findings verified; native Mac owner acceptance pending
- Created: 2026-10-15
- Scope: Mac header/UI, privacy/availability claims, preview documentation and pause semantics
- Release assessment: candidate ready for owner testing; not a stable production release

Independent source/content review used the existing read-only reviewer. No additional concrete lifecycle/privacy defect was found. Native wrong-sibling-window rejection remains pending under the existing loop F001 record.

### F-001

- Severity: medium
- Confidence: high
- Status: verified
- Evidence: Native mode selector frame overlapped the theme action by 10 x 25 pt.
- User impact: Overlapping click targets and ambiguous theme control.
- Root cause: Independent absolute frames allocated intersecting rectangles.
- Recommended solution: Shrink mode selector to 412 pt, retain a 13 pt gap; make theme action icon-only with accessible caption.
- Alternatives and tradeoffs: Moving all controls would require wider windows; narrowing existing segmented control preserves the current minimum size.
- Affected areas: macOS/Sources/AppDelegate.swift and UI smoke
- Acceptance criteria: No intersecting mode/theme frames, icon-only visual, translated accessible caption.
- Verification: CI 38688961403 24 renders and header assertions pass; independent source recheck confirms gap and icon semantics.
- Residual risk: Other display scaling and assistive technology combinations remain untested.
- Autonomy class: independent-review-required
- Remediation: remediations/REM-20261015-macos-discovery-F001.md

### F-002

- Severity: medium
- Confidence: high
- Status: verified
- Evidence: Guide and AI summary described pause/resume without distinguishing an in-progress round.
- User impact: User might expect partial pasted work to resume and accidentally duplicate text.
- Root cause: Documentation generalized the waiting state behavior to all loop stages.
- Recommended solution: State that waiting pause preserves remaining delay while mid-round pause stops; inspect draft before restarting.
- Alternatives and tradeoffs: Changing engine to resumable mid-round would alter safety and scope; accurately documenting existing behavior is preferable.
- Affected areas: docs/recurring-input/index.html, docs/llms-full.txt, macOS/TESTING.md
- Acceptance criteria: All three documents match LoopCore.togglePause and retain deadline/draft guidance.
- Verification: Independent read-only recheck confirms all three agree with LoopCore.togglePause; 71 discovery checks pass.
- Residual risk: Native input acceptance is still pending; documentation verification does not imply delivery verification.
- Autonomy class: independent-review-required
- Remediation: remediations/REM-20261015-macos-discovery-F002.md
