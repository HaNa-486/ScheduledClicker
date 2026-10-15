# Remediation: shared window and fully visible loop settings

- Remediation ID: REM-20261013-unified-window-F001
- Review finding: reviews/REV-20261013-unified-window.md#F-001
- Status: implemented
- Severity: medium
- Autonomy class: independent-review-required
- Owner: current feature workstream
- Updated: 2026-10-13
- Decision authority: User explicitly requests shared window and complete initial layout; AUTONOMY requires independent concurrency review.
- Reason: Eliminate hidden controls and inconsistent window navigation.
- Revisit condition: Owner completes Windows review and requests Mac build.

## Plan

- Recommended solution: Shared header/shell, retained per-mode views and two-column loop settings.
- Acceptance criteria: See linked finding and specs/unified-window.md.
- Verification plan: Windows five-language layout, lifecycle and native fixture; Mac compile/render/runtime after authorization.
- Rollback: Revert this scoped refactor while retaining existing localization and core/input code.

## Evidence

- Implementation: Shared shell on both platforms, idle-only mode switches, retained settings, close cancellation and fixed visible footer.
- Verification: Windows build, 2050 locale/layout checks, 40 loop and 10 original core, navigation/lifecycle and disposable native trial integration pass. Independent concurrency/privacy review found no concrete defect.
- Residual risk: Mac native acceptance remains pending; cross-platform remediation is not marked verified.

## History

- 2026-10-13 open: user reports scrolling and inconsistent separate windows.
- 2026-10-13 planned: adopt shared shell and timing/capture columns.
- 2026-10-13 in_progress: refactor retained native content views and lifecycle guards.
- 2026-10-13 implemented: Windows acceptance passes; Mac source reviewed with native execution deferred.
