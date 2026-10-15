# Remediation: Mac focus false rejection

- Remediation ID: REM-20261015-macos-input-F001
- Review finding: reviews/REV-20261015-macos-input.md#F-001
- Status: implemented
- Severity: high
- Autonomy class: independent-review-required
- Owner: Mac input acceptance fixes
- Updated: 2026-10-15T07:12:55Z
- Decision authority: Owner requested fixes; independent focus review completed
- Reason: Owner-authorized scoped repair; implementation and independent review recorded.
- Revisit condition: Owner native retest or affected behavior changes

## Plan

- Recommended solution: Compare normalized AX window identities and top-level containers, retain captured CG checks, and emit non-content reason codes.
- Acceptance criteria: Normal Safari trial succeeds; sibling window/sheet/AX failure stops before clipboard or input.
- Verification plan: Independent source recheck passes; automated identity-policy cases cover remote leaves and rejection paths. Native owner retest pending.
- Rollback: Use simple mode and withhold stable release if native input remains unreliable.

## Evidence

- Implementation: Compare normalized AX window identities and top-level containers, retain captured CG checks, and emit non-content reason codes.
- Verification: Independent source recheck passes; automated identity-policy cases cover remote leaves and rejection paths. Native owner retest pending.
- Residual risk: Safari real AX behavior, external-display input and wrong-window acceptance remain unverified.

## History

- 2026-10-15 open: Owner acceptance finding recorded.
- 2026-10-15T07:12:54Z planned: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:54Z in_progress: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:55Z implemented: Owner-authorized scoped repair; implementation and independent review recorded..
