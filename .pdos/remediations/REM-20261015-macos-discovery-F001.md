# Remediation: Mac header control overlap

- Remediation ID: REM-20261015-macos-discovery-F001
- Review finding: reviews/REV-20261015-macos-discovery.md#F-001
- Status: verified
- Severity: medium
- Autonomy class: independent-review-required
- Owner: Mac preview delivery workstream
- Updated: 2026-10-15T06:03:53Z
- Decision authority: Owner-authorized Mac/content implementation with independent recheck
- Reason: Record completed scoped correction with acceptance evidence.
- Revisit condition: Related UI or loop pause behavior changes

## Plan

- Recommended solution: Shrink mode selector to 412 pt, retain a 13 pt gap; make theme action icon-only with accessible caption.
- Acceptance criteria: No intersecting mode/theme frames, icon-only visual, translated accessible caption.
- Verification plan: CI 38688961403 24 renders and header assertions pass; independent source recheck confirms gap and icon semantics.
- Rollback: Revert scoped correction if acceptance regresses.

## Evidence

- Implementation: Shrink mode selector to 412 pt, retain a 13 pt gap; make theme action icon-only with accessible caption.
- Verification: Acceptance and independent recheck are recorded in REV-20261015-macos-discovery; CI 38688961403 and local discovery validation.
- Residual risk: Other display scaling and assistive technology combinations remain untested.

## History

- 2026-10-15 open: Independent review finding captured during authorized implementation.
- 2026-10-15T06:03:52Z planned: Acceptance and independent recheck are recorded in REV-20261015-macos-discovery; CI 38688961403 and local discovery validation..
- 2026-10-15T06:03:52Z in_progress: Acceptance and independent recheck are recorded in REV-20261015-macos-discovery; CI 38688961403 and local discovery validation..
- 2026-10-15T06:03:52Z implemented: Acceptance and independent recheck are recorded in REV-20261015-macos-discovery; CI 38688961403 and local discovery validation..
- 2026-10-15T06:03:53Z verified: Acceptance and independent recheck are recorded in REV-20261015-macos-discovery; CI 38688961403 and local discovery validation..
