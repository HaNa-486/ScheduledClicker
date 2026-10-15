# Remediation: Installation link lands above the wrong steps

- Remediation ID: REM-20261015-site-first-use-F002
- Review finding: reviews/REV-20261015-site-first-use.md#F-002
- Status: implemented
- Severity: medium
- Autonomy class: auto-decide
- Owner: multilingual website
- Updated: 2026-10-15
- Decision authority: explicit owner instruction to repair all five and publish after verification
- Reason: Mac visitors must search past unrelated instructions.
- Revisit condition: browser, review, CI or live page mismatch

## Evidence

- Implementation: Separate install-windows/install-macos anchors and direct links.
- Verification: All five locale platform links resolve directly to matching steps. Static checks pass; browser/review/live checks pending.
- Residual risk: fresh-machine OS dialogs and native-speaker editorial review are not established.

## History

- 2026-10-15 open/planned/in_progress/implemented: accepted findings implemented within authorized scope.
