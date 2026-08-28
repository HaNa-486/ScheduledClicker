# Review: macOS dark-mode readability and scheduling UX

- Review ID: REV-20260828-macos-dark-mode-ux
- Mode: review-and-fix
- Status: verified
- Created: 2026-08-28T03:25:00Z
- Scope: macOS AppKit appearance, scheduling form, status feedback
- Release assessment: conditionally-ready

## Findings

### F-001

- Severity: high
- Confidence: high
- Status: verified
- Evidence: User screenshots `image.png` and `image (1).png` from a MacBook Air in Dark appearance show white labels and controls on the fixed near-white application background. `macOS/Sources/AppDelegate.swift` explicitly set the window to `NSColor(calibratedWhite: 0.97, alpha: 1)` while labels and controls use dynamic system colors.
- User impact: The application remains functionally operable but most controls, instructions, and labels are effectively invisible, so the scheduling journey is not acceptably usable.
- Root cause: A fixed light window background was combined with semantic AppKit foreground/control colors that resolve for Dark Aqua.
- Recommended solution: Use AppKit semantic backgrounds throughout, simplify mode selection, expose only the active time input, strengthen hierarchy and status feedback, and test both Aqua and Dark Aqua appearances.
- Alternatives and tradeoffs: Forcing Aqua would restore contrast but disregard the user's system preference and conceal future appearance defects; a full SwiftUI rewrite would add unnecessary migration risk.
- Affected areas: `macOS/Sources/AppDelegate.swift`, macOS build/smoke verification, release documentation.
- Acceptance criteria: All primary and secondary text is readable in both system appearances; exact-time and delay inputs switch clearly; existing click/scheduling behavior remains unchanged; both appearance smoke tests pass on macOS CI.
- Verification: CI run 33139685219 passed the macOS 21-test core suite, self-test, Aqua UI smoke test, Dark Aqua UI smoke test, universal architecture/signature/package checks, and actual PNG review. Independent release review found no blocking issue. User confirmation on a physical Mac remains a residual step after release.
- Residual risk: Automated contrast and visibility checks do not replace a physical-Mac visual/usability confirmation.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20260828-macos-dark-mode-ux-F001.md
