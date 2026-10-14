# Startup appearance and manual light/dark choice

- Explicit: both modes should support dark appearance, select the system appearance when opening the executable and expose an in-window manual toggle.
- Decision: one shared theme for simple mode, loop mode and owned confirmation/error dialogs. Manual choice applies for this process only; restart reads system preference again. Live system changes after startup are outside this slice.
- Windows startup: read HKCU AppsUseLightTheme from Themes/Personalize; DWORD 0 means dark, otherwise light. Missing/unreadable preference falls back to light. Never write system settings. DWM title-bar dark appearance is requested where supported.
- Windows UI: theme roles cover page/card/input backgrounds, primary actions, notices, statuses and disabled controls. The newer visual redesign themes date/text/numeric fields and button chrome; see `visual-design.md` for the changed date editing contract. Scrollbars and some OS parts retain native rendering. Do not claim every native pixel is recolored.
- macOS: snapshot NSApp effective appearance at launch (including existing test override), toggle Aqua/Dark Aqua through NSApp appearance so native controls/dialogs follow. Source only until owner authorizes build.
- Toggle action is localized in all five languages and visible in the shared header. Switching appearance preserves language, mode, prompt/caret, dates, limits and an active schedule. It must not inject input, re-arm or cancel a schedule.
- Acceptance: both themes and both modes in five languages; themed dialogs; normal/notice/accent/hover/disabled text contrast >= 4.5:1 for app-drawn colors; live clock and functional native language list after switching.
- Verification: AppearanceTests plus localization/layout, native language picker and existing lifecycle/core checks. Render inspection supplements numeric contrast checks. Not all DPI/high-contrast/multi-monitor combinations are covered.
- Native API reference: https://learn.microsoft.com/windows/apps/desktop/modernize/apply-windows-themes
