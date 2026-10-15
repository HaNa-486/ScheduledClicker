# Review: bounded recurring input

- Review ID: REV-20261013-loop-input
- Mode: review-and-fix
- Status: implementation reviewed; macOS evidence pending
- Created: 2026-10-13
- Scope: Authorized Windows/macOS recurring prompt feature; independent concurrency/privacy source review
- Release assessment: not-ready

Original findings below are preserved; remediation records hold current evidence. Independent re-review found no further definite source defects after fixes. macOS execution is still required.

## Findings

### F-001

- Severity: high
- Confidence: high
- Status: open
- Evidence: Original macOS/Sources/LoopInput.swift check validated only frontmostApplication PID before paste; another non-overlapping window from that PID could retain focus.
- User impact: Prompt or select-all replacement could go to the wrong window.
- Root cause: Application identity was used instead of focused-window identity.
- Recommended solution: Require matching AX focused-window geometry and frontmost captured CGWindow identity before clipboard mutation or keyboard input.
- Alternatives and tradeoffs: PID-only checks are insufficient; strict AX checks may reject unsupported applications but avoid guessing.
- Affected areas: macOS/Sources/LoopInput.swift
- Acceptance criteria: Focusing a different non-overlapping sibling window prevents clipboard mutation and keyboard injection.
- Verification: Independent re-review accepts source ordering; macOS native sibling-window test remains pending.
- Residual risk: Same-window chat/field changes remain outside generic coordinate detection.
- Autonomy class: independent-review-required
- Remediation: remediations/REM-20261013-loop-input-F001.md

### F-002

- Severity: medium
- Confidence: high
- Status: open
- Evidence: Original LoopCore.cs and LoopCore.swift computed due from mono sampled before each native action.
- User impact: Slow native calls consumed the configured settling delay and shortened the interval.
- Root cause: Pre-action clock samples used for post-action waits.
- Recommended solution: Inject a monotonic completion clock and sample after successful actions.
- Alternatives and tradeoffs: Increasing fixed delays masks latency and cannot guarantee the configured interval.
- Affected areas: ScheduledClicker/LoopCore.cs; macOS/Sources/LoopCore.swift; corresponding tests
- Acceptance criteria: Artificially slow focus, paste and send each retain the full configured subsequent delay.
- Verification: Windows slow-action regressions pass; equivalent Swift regressions authored but not executed.
- Residual risk: OS event acceptance does not prove the target application consumed an event.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261013-loop-input-F002.md
