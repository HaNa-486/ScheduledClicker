# Remediation: Mac live keyboard owner and target activation

- Remediation ID: REM-20261015-macos-input-F004
- Review finding: reviews/REV-20261015-macos-input.md#F-004
- Status: implemented
- Severity: high
- Autonomy class: independent-review-required
- Owner: Mac foreground diagnosis
- Updated: 2026-10-15T09:13:13Z
- Decision authority: Owner scope and independent reviewer
- Reason: Candidate delivered; native journey not yet verified
- Revisit condition: Owner native retest

## Plan

- Recommended solution: Live AX keyboard PID, staged activation, revalidation, captured app/build labels and copyable diagnostics.
- Acceptance criteria: Normal native paste plus sibling refusal, cancellation/deadline and diagnostic privacy pass.
- Verification plan: CI policy/state tests and independent source review, followed by owner Safari/Word acceptance.
- Rollback: Use simple mode; withhold stable release if native journey fails.

## Evidence

- Implementation: 05861ea; Mac build 12003. No browser/app-specific exemption.
- Verification: CI 38710315157; VERIFICATION.md; independent review
- Residual risk: No native external paste/send or physical F8 verification. Original mismatch trigger remains unproven.

## History

- 2026-10-15 open: Repeated native error and caret evidence recorded.
- 2026-10-15T09:13:13Z planned: VERIFICATION.md; CI 38710315157 and independent review.
- 2026-10-15T09:13:13Z in_progress: 05861ea implementation.
- 2026-10-15T09:13:13Z implemented: CI 38710315157; VERIFICATION.md; independent review.
