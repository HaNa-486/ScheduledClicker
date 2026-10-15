# Remediation: wait from operation completion

- Remediation ID: REM-20261013-loop-input-F002
- Review finding: reviews/REV-20261013-loop-input.md#F-002
- Status: verified
- Severity: medium
- Autonomy class: auto-decide
- Owner: current feature workstream
- Updated: 2026-10-15T06:02:59Z
- Decision authority: Owner-authorized Mac build and existing auto-decide timing correction
- Reason: Equivalent Swift acceptance tests now executed successfully.
- Revisit condition: Timing engine changes or native delay regression

## Plan

- Recommended solution: Inject monotonic completion clock on both platforms.
- Acceptance criteria: Slow focus, paste and send still receive full following delay.
- Verification plan: Fake actions advance injected clock four seconds; assert no early next step.
- Rollback: Revert loop feature if timing tests fail; retain one-shot feature.

## Evidence

- Implementation: Both LoopEngine constructors require completionClock; each successful action samples it.
- Verification: CI 38688961403 at 12dbed9: Windows 40 loop checks and Mac 40 loop checks pass, including slow focus/paste/send completion-clock delays (macOS/Tests/LoopCoreTests.swift:88-91).
- Residual risk: deterministic core evidence does not validate native Mac clipboard/paste/send or physical F8.

## History

- 2026-10-13 open: saved independent review finding.
- 2026-10-13T07:17:54Z planned: Independent finding accepted within authorized feature scope..
- 2026-10-13T07:17:54Z in_progress: Implementing correction with regression coverage..
- 2026-10-13T07:17:54Z implemented: Correction implemented and independently re-reviewed; Windows tests pass; macOS execution pending..
- 2026-10-15T06:02:59Z verified: CI 38688961403 at 12dbed9: Windows 40 loop checks and Mac 40 loop checks pass, including slow focus/paste/send completion-clock delays (macOS/Tests/LoopCoreTests.swift:88-91)..
