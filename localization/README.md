# Native UI translations

`ui.tsv` is the shared UTF-8 catalog: Traditional Chinese source, English, Japanese, Korean, German. Edit this file, then run `python scripts/generate-localization.py`. Commit the generated C# and Swift catalogs. `--check` validates completeness, duplicate keys, placeholder parity and generated-file freshness. End-user builds embed the catalogs; there is no network lookup or runtime file dependency.

Startup maps `zh-*` (including Simplified Chinese) to the existing Traditional Chinese UI, `ja-*`, `ko-*`, and `de-*` to their respective languages, and everything else to English. Both modes in the shared window expose an endonym language menu. The choice is shared across modes for the current process; restarting uses the system UI language again. Only the untouched initial sample prompt follows language changes while idle. Editing or deleting it ends automatic translation; custom prompts and active plan snapshots stay unchanged.

`LocalizedView` binds only explicitly included static UI text, excluding editable fields, prompt lists, clocks, coordinates and dynamic status. Dynamic app-owned messages pass through `L.T` / `L.t` at the display boundary. The scheduling engines retain their original reasons and behavior. Parameterized source messages use `{0}`, `{1}`, etc.; a specific full-message match is tried before known literal phrases in composed reason/draft/F8 messages. Unknown platform error text is preserved. Never pass user prompts through the UI renderer.

Windows `LocalizationTests` checks OS locale startup in separate processes, all catalog entries, composed statuses, both windows and confirmation dialogs in every language, prompt/caret/configuration preservation, active-loop preservation, and fixed notices at initial/minimum size. Test fixtures are invisible, never inject native input, and report exceptions as test failures instead of opening a blocking .NET dialog.

Equivalent Swift catalog tests and multi-language AppKit smoke renders are wired into `build-macos.sh`. Both-platform CI and owner functional acceptance passed for v1.2.0; see VERIFICATION.md for scoped evidence.
