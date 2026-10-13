# Five-language native interfaces and visible loop notices

- User-authorized: both simple and loop modes in Chinese, English, Japanese, Korean and German; automatic selection from the local system UI language plus in-window manual selectors.
- Chinese variants, including Simplified Chinese, use the existing Traditional Chinese UI. Japanese, Korean and German use their languages. All other locales fall back to English.
- Manual selection is shared by both modes in the current process. On a fresh launch, select from the OS again. This follows the explicit startup rule; no preferences file is introduced.
- Language switching preserves prompt text, caret/selection, selected round, coordinates, dates, limits, and active execution. Translate the initial sample prompt only when constructing a new loop configuration.
- Translate static controls, app-owned statuses, validation failures, confirmation summaries, confirmation buttons and notices. Unknown OS error descriptions remain as reported by the OS.
- Notices are a fixed footer above loop action buttons, below the settings area. All four notices remain visible on first open and at the supported minimum size. All settings now fit without page scrolling under the superseding `unified-window.md` contract.
- Use one embedded shared catalog for both platforms. No network requests, translation service, prompt persistence, or input-engine changes.
- Delivery constraint: finish Windows local testing/review first. Public push, macOS build/CI and ZIP generation are explicitly deferred until the user later requests them. No permission request is pending.

## Acceptance evidence

- Windows build, 40 loop core and 10 original core tests pass.
- 2050 localization/catalog/state/layout/dialog checks pass, including separate-process OS-locale initialization, composed warning messages, five-language screenshots in both modes and minimum-size loop views.
- Windows renders inspected, including long German controls and localized confirmation text/buttons. Tests run invisibly and exceptions fail the executable rather than opening a blocking .NET error dialog.
- Independent review confirmed privacy/authorization disclosures and no execution from language changes. It found one macOS status-label overlap, corrected and re-reviewed by source rectangle evidence.
- macOS source and tests updated; compilation, Swift tests, native layout/accessibility and multilingual user acceptance remain unverified. No cross-platform release-ready claim.
