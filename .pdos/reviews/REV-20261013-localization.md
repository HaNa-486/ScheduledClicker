# Review: localization and fixed notices

- Review ID: REV-20261013-localization
- Mode: review-and-fix
- Status: Windows verified; macOS runtime pending
- Created: 2026-10-13
- Scope: Five-language native UI, fixed notices, confirmation privacy/authorization and test harness
- Release assessment: not-ready for cross-platform release

Independent source review confirmed that all languages retain clipboard overwrite, actual trial input/send, draft replacement/insertion and unverified-delivery disclosures. Language changes do not arm/cancel schedules or invoke native input. Prompt text is excluded from translation. No definite Swift API or syntax issue was identified; this is not compilation evidence.

## Findings

### F-001

- Severity: medium
- Confidence: high
- Status: open
- Evidence: Initial localized AppDelegate status rectangle y38...82 overlapped the status caption y72...92 by 10 points.
- User impact: Status and heading could be unreadable on macOS.
- Root cause: Enlarged translated status field without moving the caption.
- Recommended solution: Enlarge the status box and separate caption/content rectangles.
- Alternatives and tradeoffs: Smaller text would reduce readability; extra space fits below existing actions.
- Affected areas: macOS/Sources/AppDelegate.swift
- Acceptance criteria: Caption and multi-line status do not overlap in every language.
- Verification: Corrected box y24...120, caption y96...114, status y34...90; independent re-review confirms a 6-point gap. Native render pending.
- Residual risk: AppKit text fitting and Accessibility require macOS execution.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261013-localization-F001.md

### F-002

- Severity: medium
- Confidence: high
- Status: open
- Evidence: User screenshot showed a .NET error with `No confirmation dialog` while the actual confirmation was visible. Test code queried Form.ActiveForm, which can refer to another window.
- User impact: A visible test error interrupted the desktop and the default exception handler could let the test continue without a failure exit.
- Root cause: Focus-dependent test discovery and the WinForms default exception dialog.
- Recommended solution: Hold the created confirmation form directly, run fixtures invisibly, and configure unhandled exceptions to fail the test process.
- Alternatives and tradeoffs: Forcing focus would interfere with the desktop; polling active-window state remains nondeterministic.
- Affected areas: Tests/LocalizationTests.cs; Tests/LoopUiTests.cs; ScheduledClicker/Localization.cs dialog factory
- Acceptance criteria: Every localized confirmation is inspected and cancelled without focus dependence or blocking error popups; failures return a nonzero exit.
- Verification: Rebuilt and ran 1166 checks, including five actual modal confirmations. Exit 0 with no manual dismissal. Previous interrupted run is not used as acceptance evidence.
- Residual risk: Native automation integration remains a separate fixture; this test injects no input.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261013-localization-F002.md
