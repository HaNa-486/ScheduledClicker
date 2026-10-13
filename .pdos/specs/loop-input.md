# Bounded recurring input (2026-10-13)

## Authorized outcome

User explicitly requests a generic coordinate-based input/send loop on Windows and macOS, with identical prompts or per-round prompts, and count/deadline stopping. The computer stays awake, unlocked, with the target window open and stationary. No Codex state, quota, delivery, or completion recognition is promised.

## Decisions

- Keep one-shot click intact; open a separate loop setup window, mutually exclusive with one-shot execution.
- First execution uses an absolute date/time. Subsequent intervals run from completion of the preceding input/send sequence, using elapsed time. No catch-up runs.
- Same-prompt mode uses the first entry. Sequence mode uses entries in order, then stops unless explicitly configured to repeat the final entry.
- Require at least one bound: total attempted rounds (1–10000) or an absolute deadline (up to 365 days). If both are set, the first reached wins. A round counts only after the send click has been injected; this does not confirm message delivery.
- Sequence: click input, wait configured 1–10 seconds, paste, wait again, click send. One main-thread state machine; cancellation prevents later steps. A missed step by over five seconds stops without retry.
- Paste uses the system clipboard, replacing its contents. Explicitly disclose this in UI and confirmation. Preserve input drafts by default; optional replace-content sends Select All before Paste. Never log prompt contents or persist them to disk.
- Pause/resume allowed while waiting; interrupting an in-progress round stops it, requiring draft inspection before a new schedule. Deadline is still binding during pause. Closing cancels.
- Capture both coordinates on the same target application; reject changed display geometry and unavailable targets. These checks do not recognize the conversation or semantic input field.
- Trial executes one real round after a five-second countdown and requires confirmation. F8 stops; no background service or restart restoration.

## Acceptance and evidence

- Both native UIs expose first time, interval, prompt mode/editor, two capture points, optional draft replacement, count/deadline, trial/pause/cancel, and unambiguous status.
- Deterministic tests: ordering, same/sequence/repeat-last, count/deadline (including mid-round), failure/no retry, cancellation between steps, pause/resume, lateness, monotonic interval, clock changes.
- Build Windows locally and macOS with an available macOS runner; test real input against a disposable local target only. Track missing hardware evidence honestly.
- Independent concurrency/privacy review required by AUTONOMY.md; public release/merge remains owner-controlled.
