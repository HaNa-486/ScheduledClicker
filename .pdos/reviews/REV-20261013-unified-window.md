# Review: unified window lifecycle and layout

- Review ID: REV-20261013-unified-window
- Mode: review-and-fix
- Status: Windows verified; macOS runtime pending
- Created: 2026-10-13
- Scope: Shared-window ownership, switching/capture/execution exclusion, stop/close, disclosures and complete initial layout
- Release assessment: not-ready for cross-platform release

Independent source review by the existing loop reviewer found no concrete lifecycle, concurrency, privacy/authorization or Swift syntax/API defect. This is source evidence, not a Mac compilation claim. Windows embedded hotkey ownership, shared-host minimize/restore and cleanup were checked; Mac idle-only hiding, close cancellation and pending capture callback guard were checked. Existing confirmation and clipboard/real-input/delivery disclosures remain.

Windows follow-up evidence: 2050 localization/layout checks, 40 loop and 10 original core checks, same HWND and preserved settings/caret across mode switches, exclusion during active/paused work or capture, close cancellation. Disposable native integration verifies registered hotkey queue cancellation, shared-host minimization, actual trial Unicode replacement/paste/send and reuse after completion. It does not simulate a physical F8 key.

No new actionable source findings remain. Mac compile/runtime, physical global-hotkey routing, every DPI/small-screen combination and owner acceptance remain unverified. Mac source rectangles allocate separate settings, notice, action and status regions; native text fitting still requires Mac execution. No public push, release or Mac build was performed.

## User-reported finding

### F-001

- Severity: medium
- Confidence: high
- Status: implemented
- Evidence: User screenshots show the capture section below the fold with unused upper-right space; separate simple/loop windows have inconsistent layout.
- User impact: Users must scroll to configure positions and navigate a second window to change modes.
- Root cause: Single-column flow layout in an independent loop form.
- Recommended solution: One shared shell, timing/capture columns and fixed prompt/notice/action/status regions.
- Alternatives and tradeoffs: Enlarging the old vertical window would exceed shorter desktops; using two columns widens the minimum window but keeps every setting visible.
- Affected areas: Windows MainForm/LoopForm and macOS AppDelegate/LoopWindow; localization and UI tests.
- Acceptance criteria: Same window across mode switches, all loop controls and notices visible initially, settings preserved, active work excluded from mode switching and cancelled on close.
- Verification: Windows 2050 layout/localization checks, lifecycle regression and disposable native integration pass; Mac source reviewed but uncompiled.
- Residual risk: Mac runtime and all DPI/small-screen combinations pending.
- Autonomy class: independent-review-required
- Remediation: remediations/REM-20261013-unified-window-F001.md
