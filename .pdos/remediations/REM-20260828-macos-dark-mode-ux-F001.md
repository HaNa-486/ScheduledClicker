# Remediation: macOS dark-mode readability and scheduling UX

- Remediation ID: REM-20260828-macos-dark-mode-ux-F001
- Review finding: reviews/REV-20260828-macos-dark-mode-ux.md#F-001
- Status: verified
- Severity: high
- Autonomy class: auto-decide
- Owner: Codex
- Updated: 2026-08-28T03:46:20Z
- Decision authority: User explicitly reported the defect and requested correction, testing, security checks, SEO updates, commit, and push.
- Reason: Fixed light background conflicts with Dark Aqua semantic foreground colors.
- Revisit condition: Reopen if CI appearance checks fail or physical Mac confirmation finds unreadable or confusing controls.

## Plan

- Recommended solution: Replace fixed background styling with adaptive AppKit semantic colors and redesign the form hierarchy without changing scheduler behavior.
- Acceptance criteria: Both appearances are readable, both time modes remain functional, Windows behavior is unchanged, and release evidence is updated.
- Verification plan: Run Windows regression/security checks and macOS CI core, appearance, architecture, signing, and package checks.
- Rollback: Revert the v1.1.1 UI commit and keep v1.1.0 assets available while correcting the appearance implementation.

## Evidence

- Implementation: Adaptive semantic background, simplified time-mode selector, conditional inputs, improved hierarchy/status presentation, accessibility labels, appearance validation, and CI-rendered UI evidence completed at candidate `c6ed3e6`.
- Verification: CI run 33139685219: Windows 10/10, macOS 21/21, Aqua/Dark Aqua smoke tests, readable PNG review, universal architecture, codesign and package checks; independent review found no blocking finding.
- Residual risk: Physical-Mac visual confirmation remains required after automated checks.

## History

- 2026-08-28T03:25:00Z in_progress: user-provided screenshots reproduced the root cause in source and authorized remediation began.

- 2026-08-28T03:46:18Z implemented: Adaptive AppKit background, restructured UI, mode visibility checks, and UI screenshot capture implemented at candidate c6ed3e6..
- 2026-08-28T03:46:20Z verified: CI run 33139685219: Windows 10/10, macOS 21/21, Aqua/Dark Aqua smoke tests, readable PNG review, universal architecture, codesign and package checks; independent review found no blocking finding..
