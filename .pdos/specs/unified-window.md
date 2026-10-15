# Unified simple and loop window

- Explicit request: move loop capture controls beside timing; show every setting and notice initially; give both modes a consistent interface in one window.
- One shared top-level window owns clock, language picker, simple/loop navigation and both retained content views. Idle switching neither restarts nor cancels schedules and preserves prompt/caret, dates, limits and captured points.
- Active schedules (including paused loops) and capture prevent mode switching. Stop/cancel first; the shared header explains this. Closing the window cancels both modes and pending capture, timers and hotkey ownership.
- Loop layout: timing/stop bounds left, two capture positions right, prompt controls/editor below, fixed notices, actions and status at the bottom. Simple mode uses matching cards and footer styling.
- Initial client size is 1040 × 680 on both platforms, with no page scrolling. Windows supports enlargement and enforces this minimum; macOS uses the fixed initial size. Long prompt text retains its own editor scrollbar. Small desktops and all DPI combinations remain user-validation risks.
- Existing five-language routing and in-session manual selection remain. Long German labels and error status must fit. No prompt persistence, network access or native input/core behavior changes.
- Evidence: Windows build, 2050 localization/layout checks, 40 loop and 10 original core tests, one-window lifecycle regression, disposable native integration and inspected renders. Independent lifecycle/concurrency/privacy source review found no concrete defect.
- macOS source and smoke checks updated, uncompiled. User explicitly defers Mac builds/publication until Windows review and later authorization.
