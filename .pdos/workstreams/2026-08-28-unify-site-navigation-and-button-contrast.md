# Workstream: Fix inconsistent GitHub Pages navigation and low-contrast download buttons across all indexable pages

- Status: active
- Started: 2026-08-28T10:15:26Z
- Updated: 2026-08-28T10:32:48Z
- Branch: codex/site-navigation-contrast
- Base commit: 71b9a72801ec1f9d15dd39d5ff89c0529d0e51b4
- Scope: Fix inconsistent GitHub Pages navigation and low-contrast download buttons across all indexable pages
- Files or areas at risk: docs HTML navigation, shared CSS, site validator, responsive/accessibility evidence

## Coordination

- Overlap checked: no other active workstream overlaps the website navigation or shared CSS.
- Dependencies: GitHub Pages deployment and browser rendering evidence.
- Consequential conflicts: none; application binaries and release assets remain out of scope.

## Handoff

- What changed: Unified both navigation tiers across all eight pages, added current-page and keyboard-focus styling, made the detailed row wrap on narrow screens, restored dark text on download buttons in every interactive state, and strengthened the site validator.
- Verification: Site validator and diff check pass; desktop and 375 px browser journeys show no page overflow; all seven detailed destinations are visible at 375 px; download-button minimum gradient contrast is 10.10:1 with a visible 3 px keyboard-focus outline; independent re-review found no remaining findings.
- Residual risks: GitHub-hosted CI and the deployed Pages build still need verification; the wrapped navigation uses additional vertical space on narrow screens.
- Next safe action: Open the scoped PR, require CI success, merge it, then verify the public Pages deployment.
