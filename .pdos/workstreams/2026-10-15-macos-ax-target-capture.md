# Workstream: Correct confirmed Dock capture regression using AX hit-window identity

- Status: paused
- Started: 2026-10-15T10:07:19Z
- Updated: 2026-10-15T10:15:51Z
- Branch: codex/recurring-prompt-loop
- Base commit: a946914692abf1fa0f9d49115e6a2a7954f84508
- Scope: Correct confirmed Dock capture regression using AX hit-window identity
- Files or areas at risk: Mac target capture, focus guards, tests, preview delivery

## Coordination

- Overlap checked: Earlier workstreams paused; independent reviewer read-only.
- Dependencies: Mac CI compilation/tests, then owner native acceptance.
- Consequential conflicts:

## Handoff

- What changed: Build12004 AX hit-window capture replaces CG rectangle ownership; permission and sibling checks.
- Residual risks: Native owner input and Dock surface AX behavior remain unverified.
- Verification: CI 38718545337 both platforms pass; 31 identity checks; independent review; ZIP build/hash and render verified.
- Next safe action: Owner recaptures both positions and tests build12004; copy diagnostics on failure.
