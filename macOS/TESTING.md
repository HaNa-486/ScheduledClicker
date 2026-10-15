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

## Current targeted retest (Mac build 12004)

1. Fully quit the older app, replace it with this build, and confirm **build 12004** in the window title. Confirm Accessibility permission belongs to the new copy. Use Safari on the same external display/clamshell setup that failed. Capture labels must say Safari (or Microsoft Word when testing Word), not ScheduledClicker or a system process.
2. Run one harmless trial in ManualTarget.html. Accept only if exactly one complete Unicode entry appears. The Mac loop first requests target activation and waits one configured step delay before the input click; each later action also waits its configured delay. If stopped, click **Copy diagnostics** and paste the result into the report. It includes build, macOS version, target app/PID/AX-window token, observed foreground PIDs and stage/error details; it does not read prompt text, clipboard contents or window titles. Copying diagnostics replaces the clipboard. Also test sibling Safari windows and a modal sheet; do not accept text being sent to either unintended target.
3. Before editing the starter prompt, switch all five languages: 繼續 / Continue / 続けて / 계속 / Weiter. Type a custom prompt (including a manually typed 繼續), switch again, and verify your text stays unchanged. Windows follows the same rule. A running schedule retains its original prompt snapshot.
4. Hover over hours/minutes/seconds in either mode, then the loop step-delay and round count. Mouse wheel adjusts by one per event; trackpad motion accumulates and ignores inertia. Check minimum/maximum, typing then scrolling, disabled fields, and hidden modes. These fields still allow typing. Date pickers retain their native segment/stepper behavior.
5. Keep using the disposable target until normal trial plus wrong-window refusal pass. The repaired focus policy has automated identity tests, but the original Safari failure cannot be declared resolved until this native retest succeeds.

Build 12002 failed owner trials in both Safari and Word with a caret visible and an uncoded foreground error. Build 12003 is a correction candidate, not proof of native repair. Use the disposable browser target for send/count acceptance; a Word scratch document can independently check Unicode paste, but its captured second click is not message delivery. Stop/F8, deadline and wrong-window refusal must still pass.

## Build 12004 Dock capture regression

Build12003 incorrectly selected a Dock compositor rectangle and requested Dock activation. Build12004 captures the system-wide AX hit's owning window instead. It stores original window/top-level identity and AX geometry; it never skips Dock layers or falls back to CG rectangle selection. Only regular accessible app windows are supported.

- Fresh install: press Capture before granting Accessibility. Permission guidance must appear while the app stays visible and idle. Grant permission, reopen if requested, then recapture both points.
- In the previously failing setup, capture Safari/Word input and second-click positions again. Labels must identify the intended app. Run one harmless trial; the caret, full Unicode paste and intended second click must occur. Use ManualTarget.html for actual Send/count assertions.
- A real Dock target or inaccessible element must refuse capture, not choose an app behind it. Failed recapture must clear that side's old target.
- Cover the captured window with another window of the same app at the same frame, or show a modal sheet after capture. The loop must refuse before clipboard writes or paste. A different application, moved window, unavailable target and F8/cancel must also refuse/stop.
- If failure remains, Copy diagnostics should show build12004 and source=AX-hit-test after successful prepare. It must never show Dock as an activated loop target. This is a native acceptance criterion, not a claim established by policy tests.
