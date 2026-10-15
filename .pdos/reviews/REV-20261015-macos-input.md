# Review: Mac owner acceptance repairs

- Review ID: REV-20261015-macos-input
- Mode: review-and-fix
- Status: implementation reviewed; native Mac retest pending
- Created: 2026-10-15
- Scope: focus privacy guard, starter localization and numeric wheel behavior
- Release assessment: corrected candidate only, no stable release

Independent read-only reviewer checked both focus implementation and followup remote-element handling. The transient missing Swift try markers were corrected and compiled; no remaining source blocker was reported.

### F-001

- Severity: high
- Confidence: high for code facts; native cause remains uncertain
- Status: implemented
- Evidence: Owner: simple click works but Safari loop rejects focus on MacBook Air with one external display, lid closed.
- User impact: Loop cannot paste; users cannot complete the Mac critical journey.
- Root cause: Confirmed: old code conflates AX failure, exact AX/CG frame mismatch and first same-PID CG window mismatch. Actual owner trigger remains unproven.
- Recommended solution: Compare normalized AX window identities and top-level containers, retain captured CG checks, and emit non-content reason codes.
- Alternatives and tradeoffs: PID-only or blanket Safari exemptions could type into wrong windows; widening geometry tolerance still infers identity.
- Affected areas: macOS/Sources/LoopInput.swift and FocusIdentityTests.swift
- Acceptance criteria: Normal Safari trial succeeds; sibling window/sheet/AX failure stops before clipboard or input.
- Verification: Independent source recheck passes; automated identity-policy cases cover remote leaves and rejection paths. Native owner retest pending.
- Residual risk: Safari real AX behavior, external-display input and wrong-window acceptance remain unverified.
- Autonomy class: independent-review-required
- Remediation: remediations/REM-20261015-macos-input-F001.md

### F-002

- Severity: medium
- Confidence: high for code facts; native cause remains uncertain
- Status: verified
- Evidence: Owner screenshot: English UI still shows the Chinese starter after language switching.
- User impact: Default prompt does not match the selected interface language.
- Root cause: Starter was translated only during construction; later language changes deliberately excluded all prompt text without tracking untouched starter ownership.
- Recommended solution: Track whether the initial prompt was edited or removed; translate only the untouched starter while idle on both platforms.
- Alternatives and tradeoffs: Translating every prompt would overwrite user content; translating only at startup leaves manual language switches inconsistent.
- Affected areas: ScheduledClicker/LoopForm.cs; macOS/Sources/LoopWindow.swift; localization tests
- Acceptance criteria: Five translations switch before editing; edited text including a literal default word remains unchanged.
- Verification: Windows 2077 localization/state/layout checks pass; Mac smoke exercises pristine switching and edited-default preservation.
- Residual risk: Changes during active schedules retain original plan text; user draft content is never machine translated.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261015-macos-input-F002.md

### F-003

- Severity: medium
- Confidence: high for code facts; native cause remains uncertain
- Status: implemented
- Evidence: Owner reports Mac numeric fields allow typing but lack Windows-like wheel adjustment.
- User impact: Slower and inconsistent numeric configuration.
- Root cause: Mac fields were plain NSTextField without scroll-wheel behavior.
- Recommended solution: Use bounded WheelNumberField in both modes, scoped local event handling for active field editor, precise-delta accumulation and no inertia.
- Alternatives and tradeoffs: Replacing all numeric fields with a large spinner would change layout; retain compact native text fields.
- Affected areas: macOS/Sources/NativeUI.swift, AppDelegate.swift, LoopWindow.swift and NumberFieldTests.swift
- Acceptance criteria: Wheel changes enabled visible hovered numeric field; typed draft is honored; bounds/disabled/hidden/inertia respected.
- Verification: 15 native field/model checks pass in CI including active field-editor preservation; independent source recheck passes. Physical mouse/trackpad retest pending.
- Residual risk: Hardware event routing and natural-scroll preferences still require owner Mac retest; date fields retain native stepper behavior.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261015-macos-input-F003.md
