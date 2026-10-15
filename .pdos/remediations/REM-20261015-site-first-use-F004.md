# Remediation: App languages exceed website languages

- Remediation ID: REM-20261015-site-first-use-F004
- Review finding: reviews/REV-20261015-site-first-use.md#F-004
- Status: implemented
- Severity: medium
- Autonomy class: auto-decide
- Owner: multilingual website
- Updated: 2026-10-15
- Decision authority: explicit owner instruction to repair all five and publish after verification
- Reason: Japanese/Korean/German visitors lacked installation guidance.
- Revisit condition: browser, review, CI or live page mismatch

## Evidence

- Implementation: Render all nine topics in five languages with same-topic switches and localized discovery.
- Verification: 45 complete pages with reciprocal alternates, unique metadata, no fallback and browser checks. Static checks pass; browser/review/live checks pending.
- Residual risk: fresh-machine OS dialogs and native-speaker editorial review are not established.

## History

- 2026-10-15 open/planned/in_progress/implemented: accepted findings implemented within authorized scope.
