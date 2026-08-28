# Remediation: consistent site navigation

- Remediation ID: REM-20260828-site-navigation-contrast-F001
- Review finding: reviews/REV-20260828-site-navigation-contrast.md#F-001
- Status: verified
- Severity: medium
- Autonomy class: auto-decide
- Owner: Codex
- Updated: 2026-08-28T10:26:29Z
- Decision authority: User explicitly requested correction of the inconsistent page experience.
- Reason: A public product site needs predictable destinations and stable wording across page transitions.
- Revisit condition: Reopen if any page diverges or navigation clips at supported widths.

## Plan

- Recommended solution: One shared navigation contract implemented in static HTML and asserted by the site validator.
- Acceptance criteria: See review F-001.
- Verification plan: Static contract plus desktop and mobile browser journeys.
- Rollback: Revert the navigation-only commit; no application or release binary is affected.

## Evidence

- Implementation: All eight pages use identical primary and detailed navigation contracts, with normalized URL and current-page assertions in the validator.
- Verification: Static contract check and local-browser journeys verified identical ordered navigation on all eight pages, correct current-page markers, zero desktop or mobile page overflow, and all seven detailed destinations directly visible in a wrapped row at 375 px. Independent re-review found no remaining issue.
- Residual risk: The wrapped navigation consumes additional vertical space on narrow screens.

## History

- 2026-08-28T10:20:00Z in_progress: user-reported inconsistency accepted for repair.
- 2026-08-28T10:26:19Z implemented: All eight pages now use identical primary and detailed-navigation label sequences; static validator passes; browser checks at 1425 px and 375 px show no page-level horizontal overflow and the narrow secondary row scrolls independently..
- 2026-08-28T10:26:29Z verified: Static contract check and local-browser journeys verified identical ordered navigation on all eight pages, one detailed current-page marker on each inner page, zero desktop or mobile page overflow, and independent horizontal navigation scrolling at 375 px..
