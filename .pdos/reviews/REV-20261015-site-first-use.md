# Review: first-use multilingual website

- Review ID: REV-20261015-site-first-use
- Mode: review-and-fix
- Created: 2026-10-15
- Scope: five first-use findings and full five-language website; no runtime/signing/Search Console changes
- Status: reviewed; CI and live deployment pending
- Release assessment: conditionally ready pending CI and live verification
- Authority: owner explicitly approved all five findings and publication after verification.

### F-001

- Title: Opening warnings lack actionable distinctions
- Severity: medium
- Confidence: high
- Status: implemented
- Evidence: Windows only mentioned SmartScreen; Mac used a generic blocked-app instruction.
- User impact: New users stop or apply the wrong exception.
- Root cause: Install copy omitted warning-specific branches.
- Recommended solution: Provide official-source opening steps and stop for malware/corruption/policy blocks.
- Alternatives and tradeoffs: Leaving warning-only text avoids detail but does not complete first use.
- Affected areas: site/content/*.json and generated download pages
- Acceptance criteria: Each language distinguishes warning types and links official guidance; independent review.
- Verification: 2,135 static and 504 discovery checks pass; five-language narrow-browser geometry, direct install links, preserved locale/topic/section and keyboard FAQ verified. Independent safety/discovery review passed after Korean label correction and Fn+F8 clarification. CI/live verification pending.
- Residual risk: fresh-machine warning and native-speaker coverage not established.
- Autonomy class: independent-review-required
- Remediation: remediations/REM-20261015-site-first-use-F001.md

### F-002

- Title: Installation link lands above the wrong steps
- Severity: medium
- Confidence: high
- Status: implemented
- Evidence: Mac installation link targeted the Mac download card, followed by Windows instructions.
- User impact: Mac visitors must search past unrelated instructions.
- Root cause: Card anchor reused for installation.
- Recommended solution: Separate install-windows/install-macos anchors and direct links.
- Alternatives and tradeoffs: Separate platform guides would add page maintenance; shared anchored guide stays consistent.
- Affected areas: generator and download pages
- Acceptance criteria: All five locale platform links resolve directly to matching steps.
- Verification: 2,135 static and 504 discovery checks pass; five-language narrow-browser geometry, direct install links, preserved locale/topic/section and keyboard FAQ verified. Independent safety/discovery review passed after Korean label correction and Fn+F8 clarification. CI/live verification pending.
- Residual risk: fresh-machine warning and native-speaker coverage not established.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261015-site-first-use-F002.md

### F-003

- Title: Checksum commands assume current folder
- Severity: medium
- Confidence: high
- Status: implemented
- Evidence: Relative paths lacked terminal and working-directory instructions.
- User impact: Copied commands can fail to find the downloaded file.
- Root cause: Developer command example omitted prerequisites.
- Recommended solution: Explain shell, full file path, comparison and mismatch handling.
- Alternatives and tradeoffs: Changing folders is valid but more error-prone than full paths for beginners.
- Affected areas: localized verification sections
- Acceptance criteria: Both shells named, full-path examples and 64-character comparison present in every language.
- Verification: 2,135 static and 504 discovery checks pass; five-language narrow-browser geometry, direct install links, preserved locale/topic/section and keyboard FAQ verified. Independent safety/discovery review passed after Korean label correction and Fn+F8 clarification. CI/live verification pending.
- Residual risk: fresh-machine warning and native-speaker coverage not established.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261015-site-first-use-F003.md

### F-004

- Title: App languages exceed website languages
- Severity: medium
- Confidence: high
- Status: implemented
- Evidence: Website had English text and brief Chinese summaries.
- User impact: Japanese/Korean/German visitors lacked installation guidance.
- Root cause: Full website localization was absent.
- Recommended solution: Render all nine topics in five languages with same-topic switches and localized discovery.
- Alternatives and tradeoffs: Machine translation overlay is lighter but does not provide stable language URLs or maintained safety copy.
- Affected areas: site content, generator, docs, sitemap, summaries
- Acceptance criteria: 45 complete pages with reciprocal alternates, unique metadata, no fallback and browser checks.
- Verification: 2,135 static and 504 discovery checks pass; five-language narrow-browser geometry, direct install links, preserved locale/topic/section and keyboard FAQ verified. Independent safety/discovery review passed after Korean label correction and Fn+F8 clarification. CI/live verification pending.
- Residual risk: fresh-machine warning and native-speaker coverage not established.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261015-site-first-use-F004.md

### F-005

- Title: No direct issue-report route
- Severity: low
- Confidence: high
- Status: implemented
- Evidence: Nine public pages linked GitHub root but no Issues destination.
- User impact: Users do not know where or what to report.
- Root cause: Support entry was omitted from navigation/content.
- Recommended solution: Add report section and Issues link with required details and privacy reminder.
- Alternatives and tradeoffs: A new email channel requires ownership and maintenance; existing Issues is available.
- Affected areas: all locale pages
- Acceptance criteria: Every page has direct Issues link and localized reporting instructions including account requirement.
- Verification: 2,135 static and 504 discovery checks pass; five-language narrow-browser geometry, direct install links, preserved locale/topic/section and keyboard FAQ verified. Independent safety/discovery review passed after Korean label correction and Fn+F8 clarification. CI/live verification pending.
- Residual risk: fresh-machine warning and native-speaker coverage not established.
- Autonomy class: auto-decide
- Remediation: remediations/REM-20261015-site-first-use-F005.md
