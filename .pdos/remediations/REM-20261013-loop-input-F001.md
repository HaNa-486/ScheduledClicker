# Remediation: bind macOS paste to focused window

- Remediation ID: REM-20261013-loop-input-F001
- Review finding: reviews/REV-20261013-loop-input.md#F-001
- Status: implemented
- Severity: high
- Autonomy class: independent-review-required
- Owner: current feature workstream
- Updated: 2026-10-13T07:17:53Z
- Decision authority: User-authorized feature implementation; independent source review required by AUTONOMY.md
- Reason: Prevent prompt input into another window of the same application.
- Revisit condition: macOS compilation and real focused-sibling-window test available.

## Plan

- Recommended solution: AX owning-window CFEqual identity and top-level checks, retaining captured CG identity/geometry/visibility.
- Acceptance criteria: Wrong sibling window rejects paste before clipboard write or input events.
- Verification plan: Compile on macOS; test two non-overlapping windows of one local test application; inspect clipboard and received text.
- Rollback: Disable recurring input if macOS acceptance fails; retain one-shot feature.

## Evidence

- Implementation: NativeLoopInput.focusedWindowMatches, called from check before Paste changes clipboard.
- Verification: 2026-10-15: geometry/order inference replaced after owner Safari rejection; independent re-review passes. Native sibling-window acceptance still pending.
- Residual risk: Mac builds and deterministic identity tests execute in CI; real Safari paste/sibling-window refusal remains unverified.

## History

- 2026-10-13 open: saved independent review finding.
- 2026-10-13T07:17:53Z planned: Independent finding accepted within authorized feature scope..
- 2026-10-13T07:17:53Z in_progress: Implementing correction with regression coverage..
- 2026-10-13T07:17:53Z implemented: 2026-10-15: geometry/order inference replaced after owner Safari rejection; independent re-review passes. Native sibling-window acceptance still pending..
