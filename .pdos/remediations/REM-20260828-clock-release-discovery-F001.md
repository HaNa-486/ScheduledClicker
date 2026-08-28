# Remediation: macOS millisecond clock presentation

- Remediation ID: REM-20260828-clock-release-discovery-F001
- Review finding: reviews/REV-20260828-clock-release-discovery.md#F-001
- Status: in_progress
- Severity: medium
- Autonomy class: auto-decide
- Owner: Codex
- Updated: 2026-08-28T04:35:00Z
- Decision authority: User supplied physical-Mac evidence and requested all in-scope fixes.
- Reason: Three displayed millisecond digits require a refresh cadence finer than 100 ms.
- Revisit condition: Reopen if macOS CI fails or physical-Mac animation remains misleading.

## Plan

- Recommended solution: 30 Hz common-mode timer with cached formatters and smoke validation.
- Acceptance criteria: See review F-001.
- Verification plan: Cross-platform regression plus macOS appearance/UI tests.
- Rollback: Restore the 10 Hz timer and display tenths only if the higher cadence causes measurable regressions.

## Evidence

- Implementation: In progress.
- Verification: Pending.
- Residual risk: Run-loop coalescing can still skip visual frames without affecting the scheduler.

## History

- 2026-08-28T04:35:00Z in_progress: physical-Mac report accepted and fix started.

