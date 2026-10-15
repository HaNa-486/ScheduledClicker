# Remediation: Dock compositor target capture

- Remediation ID: REM-20261015-macos-input-F005
- Review finding: reviews/REV-20261015-macos-input.md#F-005
- Status: implemented
- Severity: high
- Autonomy class: independent-review-required
- Owner: Mac AX target capture
- Updated: 2026-10-15T10:15:51Z
- Decision authority: Owner request and independent review
- Reason: Candidate built and checked; native acceptance pending
- Revisit condition: Owner native retest

## Plan

- Recommended solution: AX hit-window identity at capture and every execution stage; no CG fallback.
- Acceptance criteria: Correct Safari/Word capture/paste, wrong-target refusal, cancellation and permission denial.
- Verification plan: Capture/focus identity policies, full CI and independent review; native owner retest.
- Rollback: Use simple mode and withhold release if native acceptance fails.

## Evidence

- Implementation: 8943758, build12004; stored window/topLevel, same-API geometry, live keyboard owner and capture permission entry point.
- Verification: CI 38718545337; source 8943758; ZIP metadata/hash; independent review; VERIFICATION.md
- Residual risk: Real compositor hit-testing and native paste/send remain unverified.

## History

- 2026-10-15 open: Owner diagnostic confirms Dock target at layer20 and activation before geometry failure.
- 2026-10-15T10:13:39Z planned: Owner trace and source defect in F005.
- 2026-10-15T10:13:40Z in_progress: 8943758; independent review.
- 2026-10-15T10:15:51Z implemented: CI 38718545337; source 8943758; ZIP metadata/hash; independent review; VERIFICATION.md.

- 2026-10-15 owner acceptance: reports all Mac functions now working on the delivered build12004. Normal functional acceptance recorded; individual wrong-target/cancellation/permission-negative cases not itemized. No formal release authorization.
