# Remediation: wait from operation completion

- Remediation ID: REM-20261013-loop-input-F002
- Review finding: reviews/REV-20261013-loop-input.md#F-002
- Status: implemented
- Severity: medium
- Autonomy class: auto-decide
- Owner: current feature workstream
- Updated: 2026-10-13T07:17:54Z
- Decision authority: User-authorized feature implementation and local reversible timing correction
- Reason: Preserve configured settling delay after slow native operations.
- Revisit condition: Equivalent Swift tests can execute on macOS.

## Plan

- Recommended solution: Inject monotonic completion clock on both platforms.
- Acceptance criteria: Slow focus, paste and send still receive full following delay.
- Verification plan: Fake actions advance injected clock four seconds; assert no early next step.
- Rollback: Revert loop feature if timing tests fail; retain one-shot feature.

## Evidence

- Implementation: Both LoopEngine constructors require completionClock; each successful action samples it.
- Verification: Correction implemented and independently re-reviewed; Windows tests pass; macOS execution pending.
- Residual risk: macOS equivalent tests not executed; no all-platform verified claim.

## History

- 2026-10-13 open: saved independent review finding.
- 2026-10-13T07:17:54Z planned: Independent finding accepted within authorized feature scope..
- 2026-10-13T07:17:54Z in_progress: Implementing correction with regression coverage..
- 2026-10-13T07:17:54Z implemented: Correction implemented and independently re-reviewed; Windows tests pass; macOS execution pending..
