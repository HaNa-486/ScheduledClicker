# Review: GitHub Pages navigation consistency and download-button contrast

- Review ID: REV-20260828-site-navigation-contrast
- Mode: review-and-fix
- Status: closed
- Created: 2026-08-28T10:20:00Z
- Scope: All eight indexable GitHub Pages documents and shared stylesheet
- Release assessment: ready

## Findings

### F-001

- Severity: medium
- Confidence: high
- Status: verified
- Evidence: User screenshots show the homepage secondary navigation has five items while individual pages have four or five different items and labels; source confirms every HTML file contains a separately authored navigation set.
- User impact: Navigation changes position, wording, and available destinations between clicks, making the site feel like unrelated templates and making orientation harder.
- Root cause: Focused SEO pages were added independently without a shared navigation contract or regression check.
- Recommended solution: Use one identical primary-navigation label sequence and one identical secondary-navigation label sequence on every page, varying only URLs and `aria-current`; wrap the secondary row on narrow screens so every destination remains visible.
- Alternatives and tradeoffs: Removing the secondary row would be visually simpler but reduce direct internal links and discovery; page-specific links would be shorter but preserve the inconsistency.
- Affected areas: `docs/index.html`, seven focused `docs/*/index.html` pages, `docs/styles.css`, `scripts/validate-site.ps1`.
- Acceptance criteria: Every page exposes the same ordered primary and secondary labels; the current page is indicated; desktop and mobile layouts retain usable navigation without clipping.
- Verification: Static navigation-contract check plus desktop and narrow-width browser journeys across all eight pages.
- Residual risk: The wrapped row uses more vertical space on narrow screens, but all destinations remain visible and reachable.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20260828-site-navigation-contrast-F001.md

### F-002

- Severity: high
- Confidence: high
- Status: verified
- Evidence: User screenshot shows pale blue button text on a cyan gradient. `.prose a` has higher selector specificity than `.primary`, overriding the intended dark button text.
- User impact: The two most important download calls to action are difficult to read and may fail text-contrast expectations.
- Root cause: A generic prose-link color rule unintentionally overrides the primary-button component inside the download prose section.
- Recommended solution: Add an explicit prose primary-button rule with dark text, visible hover/focus states, and regression validation.
- Alternatives and tradeoffs: Making the button background dark would reduce visual prominence; `!important` would fix the symptom but make future CSS maintenance harder.
- Affected areas: `docs/styles.css`, `scripts/validate-site.ps1`, download user journey.
- Acceptance criteria: Both download buttons render dark readable text on the cyan gradient in normal, hover, keyboard-focus, and visited states.
- Verification: Computed-style contrast measurement, keyboard focus inspection, and desktop/mobile screenshots.
- Residual risk: Browser font rasterization varies slightly, but the selected colors have a wide contrast margin.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20260828-site-navigation-contrast-F002.md

## Closure evidence

- Static validation passes across all eight pages, including label, destination URL, ordering, `aria-current`, metadata, JSON-LD, local-link, alt-text, and sitemap checks.
- Desktop browser checks found no page-level overflow; 375 px checks show all seven detailed destinations directly visible in a wrapped row.
- Both download buttons retain dark text in normal, visited, hover, and focus-visible states; measured minimum gradient contrast is 10.10:1 and keyboard focus uses a 3 px white outline with 3 px offset.
- Independent initial review found two low-severity hardening opportunities; both were resolved, and final independent re-review returned no findings or PR blockers.
