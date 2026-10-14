# Research-led light/dark redesign

- Explicit: owner rejected the first dark palette and large theme button, authorized researching design guidance and revising both themes. Mac remains in scope for source adaptation; public push, CI and Mac binaries remain deferred.
- Prior visual problem: high-contrast card outlines, repeated blue navigation/actions, large appearance action, yellow notice block and white native date fields competed for attention. This was a visual-hierarchy problem as well as a palette problem.

## References and decisions

- [Fluent 2 color](https://fluent2.microsoft.design/color/): use neutral surface roles, reserve stronger color for meaningful emphasis, and adapt colors to dark backgrounds. Applied as charcoal page/card/field steps and corresponding pale neutral light surfaces.
- [Fluent 2 buttons](https://fluent2.microsoft.design/components/web/react/core/button/usage): distinguish action importance. Each visible mode has one primary start action; capture, trial, cancel and navigation use neutral treatments. Focus, hover, pressed and disabled states remain visible.
- [Apple Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode): use native semantic colors and platform appearance. Mac keeps AppKit controls, segmented navigation, semantic surfaces and SF Symbols rather than copying Windows custom painting.
- [Material dark theme design](https://codelabs.developers.google.com/codelabs/design-material-darktheme/): separate surfaces and ensure legible foreground colors. Used as corroborating guidance rather than introducing another component framework.
- Our design choices: rounded cards without bright outlines; low-emphasis fixed notices; a compact sun/moon action beside language selection with translated tooltip and accessible name. One shared theme across modes and owned dialogs.

## Behavior and acceptance

- Startup/system preference and session-only override remain unchanged. No page scrolling at the existing initial/minimum desktop window; prompt text retains its own scrolling.
- Windows buttons retain Button semantics; combo boxes and numeric controls retain native interaction, with themed chrome. Native scrollbars and some OS-rendered parts remain platform controlled.
- Windows dates now use an explicitly formatted, themed text field. Format is `yyyy/MM/dd HH:mm:ss`; caret-based Up/Down or spin clicks adjust year/month/day/hour/minute/second. Invalid or impossible values cannot arm a schedule and are not silently replaced by an old value. The field has a translated accessible name. This is a deliberate change from native date segment editing, not claimed to be identical.
- Keep existing prompt, caret, dates, limits, language and active plan across appearance changes. Keep the native language dropdown open across clock/layout updates.
- Evidence: Windows build; 2066 catalog/layout/state checks; 15 native language-picker interactions; 153 appearance/startup/contrast/state checks and 30 renders; 20 date validation/rollover/schedule checks; shared-window lifecycle and 40 loop/10 original core tests. Human inspection of dark loop, light simple and German loop/dialog renders supplements numeric checks.
- Deferred: macOS compilation/runtime and native renders; complete high-contrast, screen-reader, mixed-DPI and small-desktop coverage. Automated rendering does not establish owner aesthetic acceptance.
- Next: owner reviews the local Windows candidate; build Mac only after a later explicit request.
