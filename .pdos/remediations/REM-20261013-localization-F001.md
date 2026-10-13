# Remediation: separate macOS status caption and text

- Remediation ID: REM-20261013-localization-F001
- Review finding: reviews/REV-20261013-localization.md#F-001
- Status: implemented
- Severity: medium
- Autonomy class: auto-decide
- Owner: current feature workstream
- Updated: 2026-10-13
- Decision authority: User-authorized localized layout correction
- Reason: Remove definite overlapping status rectangles.
- Revisit condition: User authorizes macOS build/testing after Windows review.

## Plan

- Recommended solution: Enlarge bottom status box, move caption, preserve readable multi-line content.
- Acceptance criteria: No overlap in five-language native renders.
- Verification plan: Source geometry review now; macOS screenshots later.
- Rollback: Revert status layout change only if native rendering fails.

## Evidence

- Implementation: Status box y24...120; caption y96...114; status y34...90.
- Verification: Independent re-review confirms 6-point separation; native execution pending.
- Residual risk: Not marked verified without macOS rendering.

## History

- 2026-10-13 open: independent reviewer identified rectangle overlap.
- 2026-10-13 planned: separate caption and status area.
- 2026-10-13 in_progress: adjust source rectangles.
- 2026-10-13 implemented: source independently re-reviewed; native evidence deferred.
