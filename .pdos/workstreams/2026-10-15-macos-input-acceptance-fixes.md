# Workstream: Repair Mac focus false rejection, localized pristine default prompts, numeric wheel controls

- Status: paused
- Started: 2026-10-15T07:00:07Z
- Updated: 2026-10-15T07:15:13Z
- Branch: codex/recurring-prompt-loop
- Base commit: d959e8ab6a009d62d61f1b84fb09fcf32656e639
- Scope: Repair Mac focus false rejection, localized pristine default prompts, numeric wheel controls
- Files or areas at risk: Mac native input/UI, shared localization, Windows loop prompt, tests and preview delivery

## Coordination

- Overlap checked: All earlier workstreams paused; existing reviewer read-only.
- Dependencies: macOS CI and owner Safari/external-display native retest.
- Consequential conflicts:

## Handoff

- What changed: Implemented preview.2 AX owning-window focus verification, pristine prompt localization and Mac numeric wheel controls.
- Residual risks: Original Safari failure not reproduced locally; native Safari/wrong-window and physical wheel/F8 require owner retest; no stable release.

- Verification: CI 38696929654 at 7a75cba: both platforms pass; 9 focus-policy and 15 number-field checks; independent source review; candidate hash/version checked.
- Next safe action: Owner retests Safari, sibling window/sheet and physical numeric wheel on preview.2 build 12002.
