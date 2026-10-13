# Workstream: Add bounded recurring prompt input and send workflows on Windows and macOS

- Status: paused
- Started: 2026-10-13T06:53:46Z
- Updated: 2026-10-13T12:06:24Z
- Branch: codex/recurring-prompt-loop
- Base commit: c69f207a4bbda0d8fa1e18a07390ba71cd7e41c1
- Scope: Add bounded recurring prompt input and send workflows on Windows and macOS
- Files or areas at risk: ScheduledClicker,macOS,Tests,build scripts,documentation

## Coordination

- Overlap checked: all prior workstreams completed; clean initial tree; no overlapping active work.
- Dependencies: macOS compiler/runner and Accessibility-enabled native test environment.
- Consequential conflicts: no product scope conflict; public branch publication requires owner decision under skill autonomy rules.

## Handoff

- What changed: Unified native window; two-column loop settings; all settings and notices visible; consistent mode header and footer; five languages retained.
- Verification: Windows build, 2050 localization/layout checks, 40 loop and 10 original core tests, shared-window lifecycle and disposable native trial integration pass. Independent lifecycle/concurrency/privacy source review complete. Mac source only.
- Next safe action: Owner tests Windows unified-window candidate; await explicit later request before Mac build or public push.
- Residual risks: Mac compilation/runtime, physical global F8 and every DPI/small-screen combination remain unverified; no public push or Mac CI authorized.
