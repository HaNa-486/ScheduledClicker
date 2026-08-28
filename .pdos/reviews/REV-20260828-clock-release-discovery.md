# Review: macOS clock, release presentation, and discovery

- Review ID: REV-20260828-clock-release-discovery
- Mode: review-and-fix
- Status: open
- Created: 2026-08-28T04:35:00Z
- Scope: macOS clock presentation, GitHub Release presentation, repository metadata, and GitHub Pages SEO/AEO/AI discovery
- Release assessment: not-ready

## Findings

### F-001

- Severity: medium
- Confidence: high
- Status: in_progress
- Evidence: User-recorded MacBook Air video shows only the hundreds digit visibly changing in the three-digit millisecond clock. `AppDelegate.swift` scheduled UI refresh every 0.1 seconds while rendering `SSS`.
- User impact: The display implies millisecond-resolution animation but visibly updates only at tenth-second resolution, which looks defective and reduces trust in timing feedback.
- Root cause: The clock label was refreshed at 10 Hz and constructed a new `DateFormatter` on every tick.
- Recommended solution: Refresh around 30 Hz, cache formatters, attach the timer to common run-loop modes, and validate the configured interval in the UI smoke test.
- Alternatives and tradeoffs: Showing only one decimal digit would be cheaper but removes the requested millisecond display; 100 Hz would animate more often but wastes resources for no scheduling benefit.
- Affected areas: `macOS/Sources/AppDelegate.swift`, version metadata, macOS CI evidence.
- Acceptance criteria: All three millisecond digits vary naturally in normal use; clock remains responsive during control interaction; scheduling behavior is unchanged.
- Verification: macOS build, core tests, Aqua/Dark Aqua UI smoke tests, screenshots, and physical-Mac follow-up.
- Residual risk: UI timers are not real-time clocks and can be coalesced temporarily when the process is busy; scheduling remains handled separately.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20260828-clock-release-discovery-F001.md

### F-002

- Severity: low
- Confidence: high
- Status: in_progress
- Evidence: Public v1.1.1 Release body visibly contains literal `\\n` sequences instead of Markdown line breaks.
- User impact: Release information is difficult to scan and appears lower quality than v1.1.0.
- Root cause: The release command passed escaped newline characters inside a shell string that GitHub stored literally.
- Recommended solution: Replace the body with structured Markdown and use a file-based body for future releases.
- Alternatives and tradeoffs: Leaving the text unchanged does not affect binaries but harms trust and machine readability.
- Affected areas: GitHub v1.1.1 Release and future release workflow.
- Acceptance criteria: Public v1.1.1 notes render with headings, paragraphs, bullets, downloads, verification, and limitations.
- Verification: Re-read the public Release body through GitHub API and browser rendering.
- Residual risk: Historical screenshots retain the old appearance.
- Autonomy class: human-only
- Remediation: remediations/REM-20260828-clock-release-discovery-F002.md

### F-003

- Severity: medium
- Confidence: high
- Status: in_progress
- Evidence: Repository description mentions Windows only; macOS topics are absent; the site has only one indexable page and a stylized preview; visible FAQ lacks machine-readable FAQ structure.
- User impact: Search engines, GitHub discovery, answer engines, and prospective users receive weaker platform-specific and trust signals.
- Root cause: Cross-platform product work outpaced repository metadata and the original single-page launch site.
- Recommended solution: Correct repository metadata, add focused indexable pages with internal links/canonicals, publish real UI renders, expand accurate JSON-LD, update sitemap and AI summary, and validate all pages.
- Alternatives and tradeoffs: Keyword stuffing or duplicate thin pages would add noise; every new page must answer a distinct user question with substantive content.
- Affected areas: GitHub repository settings, `docs/`, sitemap, structured data, README, and release notes.
- Acceptance criteria: Repository metadata names both platforms; each focused page has unique metadata and useful content; images have descriptive alt text; JSON-LD parses; sitemap lists canonical URLs; no unsupported review/rating claims are added.
- Verification: Static HTML/link/schema checks, local HTTP crawl, live Pages crawl after deploy, and independent review.
- Residual risk: Technical optimization cannot guarantee indexing, ranking, citations, backlinks, or AI inclusion.
- Autonomy class: human-only
- Remediation: remediations/REM-20260828-clock-release-discovery-F003.md

