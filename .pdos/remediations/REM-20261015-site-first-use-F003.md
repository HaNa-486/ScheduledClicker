# Remediation: Checksum commands assume current folder

- Remediation ID: REM-20261015-site-first-use-F003
- Review finding: reviews/REV-20261015-site-first-use.md#F-003
- Status: implemented
- Severity: medium
- Autonomy class: auto-decide
- Owner: multilingual website
- Updated: 2026-10-15
- Decision authority: explicit owner instruction to repair all five and publish after verification
- Reason: Copied commands can fail to find the downloaded file.
- Revisit condition: browser, review, CI or live page mismatch

## Evidence

- Implementation: Explain shell, full file path, comparison and mismatch handling.
- Verification: Both shells named, full-path examples and 64-character comparison present in every language. Static checks pass; browser/review/live checks pending.
- Residual risk: fresh-machine OS dialogs and native-speaker editorial review are not established.

## History

- 2026-10-15 open/planned/in_progress/implemented: accepted findings implemented within authorized scope.
