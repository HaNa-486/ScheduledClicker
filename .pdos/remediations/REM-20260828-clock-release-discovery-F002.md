# Remediation: v1.1.1 Release formatting

- Remediation ID: REM-20260828-clock-release-discovery-F002
- Review finding: reviews/REV-20260828-clock-release-discovery.md#F-002
- Status: verified
- Severity: low
- Autonomy class: human-only
- Owner: Codex
- Updated: 2026-08-28T05:04:14Z
- Decision authority: User explicitly requested the visible Release discrepancy be corrected.
- Reason: Literal escaped newlines were published instead of Markdown line breaks.
- Revisit condition: Reopen if the public body still contains literal `\\n` sequences.

## Plan

- Recommended solution: Update the public body with structured bilingual Markdown and use a file-based body for v1.1.2.
- Acceptance criteria: See review F-002.
- Verification plan: GitHub API body inspection and public-page check.
- Rollback: Restore the prior body from API output if information is accidentally lost.

## Evidence

- Implementation: Pending.
- Verification: GitHub API and public Release inspection confirmed v1.1.1 headings, lists, bilingual notes, download explanations, verification, and limitations render without literal escaped newline text.
- Residual risk: None beyond historical screenshots.

## History

- 2026-08-28T04:35:00Z in_progress: user authorized public Release description correction.

- 2026-08-28T05:04:01Z implemented: Public v1.1.1 Release body now renders structured bilingual Markdown without literal escaped newlines; v1.1.2 notes are stored in a file..
- 2026-08-28T05:04:14Z verified: GitHub API and public Release inspection confirmed v1.1.1 headings, lists, bilingual notes, download explanations, verification, and limitations render without literal escaped newline text..
