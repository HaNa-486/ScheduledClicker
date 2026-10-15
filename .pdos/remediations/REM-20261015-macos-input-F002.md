# Remediation: Localized pristine prompt

- Remediation ID: REM-20261015-macos-input-F002
- Review finding: reviews/REV-20261015-macos-input.md#F-002
- Status: verified
- Severity: medium
- Autonomy class: auto-decide
- Owner: Mac input acceptance fixes
- Updated: 2026-10-15T07:12:56Z
- Decision authority: Owner requested fixes; independent focus review completed
- Reason: Owner-authorized scoped repair; implementation and independent review recorded.
- Revisit condition: Owner native retest or affected behavior changes

## Plan

- Recommended solution: Track whether the initial prompt was edited or removed; translate only the untouched starter while idle on both platforms.
- Acceptance criteria: Five translations switch before editing; edited text including a literal default word remains unchanged.
- Verification plan: Windows 2077 localization/state/layout checks pass; Mac smoke exercises pristine switching and edited-default preservation.
- Rollback: Use simple mode and withhold stable release if native input remains unreliable.

## Evidence

- Implementation: Track whether the initial prompt was edited or removed; translate only the untouched starter while idle on both platforms.
- Verification: Windows 2077 localization/state/layout checks; Mac all-language smoke tests in CI 38696658341 verify untouched starter translation and preserve edited text.
- Residual risk: Changes during active schedules retain original plan text; user draft content is never machine translated.

## History

- 2026-10-15 open: Owner acceptance finding recorded.
- 2026-10-15T07:12:55Z planned: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:55Z in_progress: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:55Z implemented: Owner-authorized scoped repair; implementation and independent review recorded..
- 2026-10-15T07:12:56Z verified: Windows 2077 localization/state/layout checks; Mac all-language smoke tests in CI 38696658341 verify untouched starter translation and preserve edited text..
