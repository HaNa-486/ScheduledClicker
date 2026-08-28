# Remediation: macOS dark-mode readability and scheduling UX

- Remediation ID: REM-20260828-macos-dark-mode-ux-F001
- Review finding: reviews/REV-20260828-macos-dark-mode-ux.md#F-001
- Status: in_progress
- Severity: high
- Autonomy class: auto-decide
- Owner: Codex
- Updated: 2026-08-28T03:25:00Z
- Decision authority: User explicitly reported the defect and requested correction, testing, security checks, SEO updates, commit, and push.
- Reason: Fixed light background conflicts with Dark Aqua semantic foreground colors.
- Revisit condition: Reopen if CI appearance checks fail or physical Mac confirmation finds unreadable or confusing controls.

## Plan

- Recommended solution: Replace fixed background styling with adaptive AppKit semantic colors and redesign the form hierarchy without changing scheduler behavior.
- Acceptance criteria: Both appearances are readable, both time modes remain functional, Windows behavior is unchanged, and release evidence is updated.
- Verification plan: Run Windows regression/security checks and macOS CI core, appearance, architecture, signing, and package checks.
- Rollback: Revert the v1.1.1 UI commit and keep v1.1.0 assets available while correcting the appearance implementation.

## Evidence

- Implementation: In progress.
- Verification: Pending.
- Residual risk: Physical-Mac visual confirmation remains required after automated checks.

## History

- 2026-08-28T03:25:00Z in_progress: user-provided screenshots reproduced the root cause in source and authorized remediation began.

