# Remediation: Mac numeric wheel interaction

- Remediation ID: REM-20261015-macos-input-F003
- Review finding: reviews/REV-20261015-macos-input.md#F-003
- Status: implemented
- Severity: medium
- Autonomy class: auto-decide
- Owner: Mac input acceptance fixes
- Updated: 2026-10-15T07:12:56Z
- Decision authority: Owner requested fixes; independent focus review completed
- Reason: Owner-authorized scoped repair; implementation and independent review recorded.
- Revisit condition: Owner native retest or affected behavior changes

## Plan

- Recommended solution: Use bounded WheelNumberField in both modes, scoped local event handling for active field editor, precise-delta accumulation and no inertia.
- Acceptance criteria: Wheel changes enabled visible hovered numeric field; typed draft is honored; bounds/disabled/hidden/inertia respected.
- Verification plan: 15 native field/model checks pass in CI including active field-editor preservation; independent source recheck passes. Physical mouse/trackpad retest pending.
- Rollback: Use simple mode and withhold stable release if native input remains unreliable.

## Evidence

- Implementation: Use bounded WheelNumberField in both modes, scoped local event handling for active field editor, precise-delta accumulation and no inertia.
- Verification: 15 native field/model checks pass in CI including active field-editor preservation; independent source recheck passes. Physical mouse/trackpad retest pending.
- Residual risk: Hardware event routing and natural-scroll preferences still require owner Mac retest; date fields retain native stepper behavior.

## History

- 2026-10-15 open: Owner acceptance finding recorded.
- 2026-10-15T07:12:56Z planned: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:56Z in_progress: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:56Z implemented: Owner-authorized scoped repair; implementation and independent review recorded..
