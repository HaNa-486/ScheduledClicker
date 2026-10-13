# Remediation: remove focus dependence from confirmation tests

- Remediation ID: REM-20261013-localization-F002
- Review finding: reviews/REV-20261013-localization.md#F-002
- Status: verified
- Severity: medium
- Autonomy class: auto-decide
- Owner: current feature workstream
- Updated: 2026-10-13
- Decision authority: User-reported test error during authorized feature verification
- Reason: Prevent blocking .NET error dialogs and false acceptance after manual dismissal.
- Revisit condition: Confirmation UI creation or test hosting changes.

## Plan

- Recommended solution: Hold the created dialog, hide test fixtures, throw unhandled UI exceptions to the process-level failure handler.
- Acceptance criteria: Five-language dialog verification completes without focus dependence or manual intervention.
- Verification plan: Full build, navigation and localization suites.
- Rollback: Revert test-only harness changes if modal coverage stops exercising the production factory.

## Evidence

- Implementation: LocalizedDialog.Create is shared with production Show; tests inspect that exact modal form, with zero opacity. Both UI fixtures set ThrowException.
- Verification: Windows build and 1166 checks pass after correction, including all confirmation text/buttons and cancellation; navigation and 40 core tests also pass.
- Residual risk: These UI tests do not exercise external native input.

## History

- 2026-10-13 open: user screenshot and exact test assertion identified.
- 2026-10-13 planned: remove active-window lookup.
- 2026-10-13 in_progress: implement direct form reference and fail-fast tests.
- 2026-10-13 implemented: hidden fixtures and shared dialog factory complete.
- 2026-10-13 verified: fresh tests exited successfully without manual dismissal.
