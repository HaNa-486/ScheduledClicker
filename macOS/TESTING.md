# macOS 1.2.0 preview local acceptance

The universal ZIP supports macOS 13+ on Apple silicon and Intel. CI builds both architectures, checks the ad-hoc signature, and renders five languages in light/dark appearance. It does not grant Accessibility permission or send real input on a user's desktop.

1. Extract the app ZIP, compare `shasum -a 256 ScheduledClicker-macOS-universal.zip` with the adjacent checksum, and move the app to Applications. Allow opening through macOS Privacy & Security if needed. The app is not Apple-notarized.
2. Grant this app Accessibility permission. If replacing an older copy, check that permission applies to the newly installed app and reopen it.
3. Open [ManualTarget.html](Tests/ManualTarget.html) in a browser. This disposable target has no network requests and records text only in its page memory. Start with non-sensitive sample text.
4. Capture its input and Send positions. Select one trial round, insert or replace explicitly, and confirm. Check that exactly one entry appears and Unicode/newlines are preserved. Trial sends real input and overwrites the system clipboard.
5. Test two rounds with a 30-second completion-relative interval, using different prompts. Confirm order and count, then test pause/resume and cancel during the between-round wait. The deadline continues to apply while paused. Pressing Pause after a round has started stops the loop; inspect the draft and start a new schedule instead of expecting a mid-round resume.
6. Set a long step delay, start a trial and press F8 (Fn+F8 where required) before paste. Check that remaining input is stopped. Also test closing the app while waiting.
7. Open the target in two separate, non-overlapping windows of the same browser. Capture window A. After the focus click but before paste, focus window B without covering A. Confirm the app stops, neither window receives text, and a harmless baseline clipboard string remains unchanged. This is the pending focused-sibling-window acceptance case; CI does not establish it.
8. Check both modes, all five languages and the sun/moon action. Settings and prompt text should remain. Restart should select the system language and appearance again. Keep the computer awake/unlocked and the target layout fixed during each input test.

Report the macOS version, Intel/Apple silicon, preview build, step and observed result. Do not use a real conversation until the harmless target passes. A completed send click does not prove message delivery in another app.
