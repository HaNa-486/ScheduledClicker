# Remediation: readable download buttons

- Remediation ID: REM-20260828-site-navigation-contrast-F002
- Review finding: reviews/REV-20260828-site-navigation-contrast.md#F-002
- Status: verified
- Severity: high
- Autonomy class: auto-decide
- Owner: Codex
- Updated: 2026-08-28T10:32:48Z
- Decision authority: User explicitly requested correction of the unreadable download buttons.
- Reason: The primary download action must remain readable in every link state.
- Revisit condition: Reopen if computed contrast drops below 4.5:1 or a browser state restores pale text.

## Plan

- Recommended solution: Specific component selector for prose primary buttons, including hover/focus/visited states.
- Acceptance criteria: See review F-002.
- Verification plan: Static CSS check, computed-style contrast measurement, keyboard focus and desktop/mobile browser screenshots.
- Rollback: Revert the CSS component rule; page content and downloads are unchanged.

## Evidence

- Implementation: Explicit prose primary-button selectors cover normal, visited, hover, and focus-visible states; the validator asserts every required safeguard.
- Verification: Browser-computed minimum contrast is 10.10:1 for both download buttons; normal, visited, hover, and focus-visible retain dark text, keyboard focus has a 3 px white outline with 3 px offset, desktop/mobile screenshots are readable, validator passes, and independent re-review reports no findings.
- Residual risk: None beyond browser rasterization differences.

## History

- 2026-08-28T10:20:00Z in_progress: user-provided screenshot established the contrast defect.
- 2026-08-28T10:26:20Z implemented: Explicit prose primary-button selectors restore dark text across normal and visited states, retain dark text on hover, and provide a 3 px white focus outline; browser-computed minimum gradient contrast is 10.10:1 for both buttons..
- 2026-08-28T10:32:48Z verified: Browser-computed minimum contrast is 10.10:1 for both download buttons; normal, visited, hover, and focus-visible retain dark text, keyboard focus has a 3 px white outline with 3 px offset, desktop/mobile screenshots are readable, validator passes, and independent re-review reports no findings..
