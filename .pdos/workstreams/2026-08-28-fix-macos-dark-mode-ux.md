# Workstream: 修正 macOS 深色模式不可讀並改善排程介面；版本 1.1.1；保留既有功能

- Status: active
- Started: 2026-08-28T03:21:18Z
- Updated: 2026-08-28T03:21:18Z
- Branch: main
- Base commit: 4d2119a843d8155226209355b28b6bd127e6ca31
- Scope: 修正 macOS 深色模式不可讀並改善排程介面；版本 1.1.1；保留既有功能
- Files or areas at risk: macOS UI, appearance tests, release metadata, verification, Windows regression

## Coordination

- Overlap checked: no other active workstream overlaps this scope; prior workstreams are completed.
- Dependencies: GitHub-hosted macOS runner for compilation and Aqua/Dark Aqua smoke tests; physical Mac for final human visual confirmation.
- Consequential conflicts: none.

## Handoff

- What changed: Root cause confirmed; adaptive semantic background and restructured scheduling UI are being implemented.
- Verification: Pending local Windows checks and macOS CI.
- Residual risks: Automated appearance checks cannot judge every visual detail on a physical Mac.
- Next safe action: Finish release metadata, run local static/Windows verification, then push a verification branch for macOS CI.
