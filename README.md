# ScheduledClicker — Windows 11 & macOS Scheduled Auto Clicker

[![Release](https://img.shields.io/github/v/release/HaNa-486/ScheduledClicker?label=release)](https://github.com/HaNa-486/ScheduledClicker/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-63d8cd.svg)](LICENSE)
[![Windows 11](https://img.shields.io/badge/Windows-11-58a6ff.svg)](https://github.com/HaNa-486/ScheduledClicker/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-9aa4b2.svg)](https://github.com/HaNa-486/ScheduledClicker/releases/latest)

![ScheduledClicker — Windows and macOS Scheduled Auto Clicker](docs/social-preview.jpg)

**Website:** [hana-486.github.io/ScheduledClicker](https://hana-486.github.io/ScheduledClicker/)

ScheduledClicker is a free, open-source Windows 11 and macOS utility that performs one single or double mouse click at a specific future time or after a delay. Both native editions are local-only, with no ads, accounts, telemetry, network access, or third-party packages.

It was created for workflows such as sending a prepared Codex message after the usage reset time shown in the app. ScheduledClicker does **not** detect, bypass, reset, or increase any ChatGPT or Codex limit—it only performs an ordinary mouse click at the time you choose.

## Key features

**Unreleased source feature:** bounded recurring input/send workflows are being added to both editions. Windows local build, UI and native-input tests are documented in [`VERIFICATION.md`](VERIFICATION.md); macOS build and hardware verification are pending. Released v1.1.2 downloads still provide the one-shot workflow below.

- Schedule one click at an exact future date and time.
- Schedule one click after a seconds, minutes, or hours delay.
- Choose single click or double click at a captured screen coordinate.
- View a live clock, countdown, confirmation, completion, and error states.
- Cancel on screen or use `F8` when the global hotkey is available.
- Run as a portable Windows executable or native universal macOS app with no installer.
- Review the complete C# source, security notes, tests, and SHA-256 report.

## Languages in the local development candidate

Both simple and loop modes support Traditional Chinese, English, Japanese, Korean and German. Startup follows the system UI language: all `zh-*` locales (including Simplified Chinese) use Traditional Chinese; `ja-*`, `ko-*` and `de-*` use their respective translations; other locales use English. The shared window has a language selector for both modes in the current session. Restarting uses the system language again. Switching preserves prompts, caret selection, settings and active schedules.

Both modes share one window, clock, language selector and mode buttons. Loop timing is on the left and position capture on the right, with prompts underneath and fixed notices, actions and status below. All settings fit the initial/minimum window without page scrolling; long prompt text can scroll inside its editor. Stop an active schedule or capture before switching modes; idle switching preserves configuration. The shared catalog and development checks are described in [`localization/README.md`](localization/README.md).

The local candidate now includes light/dark themes. Startup reads the current system app appearance; a shared header button switches both modes and confirmations for this session. Restarting reads the system again. Windows date/time fields and some native control parts retain their standard rendering. macOS source includes the matching appearance toggle; its build remains deferred.

These changes are **unreleased**. Windows is available as a local review candidate; macOS source is updated, but builds and public CI are deferred until the owner finishes Windows testing and requests them.

## Download

Download the latest Windows executable or universal macOS application from [GitHub Releases](https://github.com/HaNa-486/ScheduledClicker/releases/latest).

- **Windows 11:** download `ScheduledClicker.exe`. It is not commercially code-signed, so Windows SmartScreen may show a warning.
- **macOS 13 Ventura or later:** download `ScheduledClicker-macOS-universal.zip`. It supports both Apple silicon and Intel Macs, adapts to both Light and Dark appearance, and version 1.1.2 improves the three-digit millisecond clock animation. The app is ad-hoc signed but not Apple-notarized, so first launch may require Control-clicking the app, choosing **Open**, and confirming in **System Settings → Privacy & Security**.

Compare downloaded files with the SHA-256 values in [`VERIFICATION.md`](VERIFICATION.md), or build directly from the published source.

## Frequently asked questions

### What is ScheduledClicker?

ScheduledClicker is a free Windows 11 and macOS scheduled auto clicker for one timed single or double mouse click at a captured screen position.

### Does the Windows EXE work on a MacBook?

No. The EXE uses Windows WinForms and `user32.dll`, which macOS cannot run natively. Download the separate universal macOS app instead; it uses Apple's AppKit, Quartz, and Accessibility permission model.

### Can it continue a Codex session after usage resets?

Yes. Prepare the message in the same Codex session, keep the window in place, and schedule the click shortly after the reset time displayed by Codex. It does not detect or bypass limits.

### Is ScheduledClicker safe?

The app has no network, telemetry, account, or persistence features and uses no third-party packages. Fixed-coordinate automation can still misclick if a window moves, so test a harmless target first and avoid irreversible actions.

### Is it free and open source?

Yes. The source and executable are published under the permissive MIT License.

---

## 定時滑鼠點擊器

給 Windows 11 與 macOS 使用的免安裝小工具，可在指定時間或一段延遲後，把滑鼠移到預先擷取的位置並執行單擊或雙擊。畫面會持續顯示目前時間與排程倒數。Windows EXE 只能在 Windows 執行；MacBook 請使用獨立的 macOS `.app` 版本。

## 為什麼做這個工具

這個小工具最初是為 ChatGPT Plus 的 Codex 使用情境而設計：當 Codex 顯示目前用量視窗已達上限，並告知可再次使用的時間時，開發者可以事先把「繼續上次中斷的工作」等提示留在原本的 Codex Session，接著設定本工具在重設時間稍後按下送出或繼續按鈕。如此一來，即使開發者正在睡覺，電腦也能在可用額度合法恢復後，自動請 Codex 繼續原本的 Session。

這不是繞過、重設或增加 ChatGPT／Codex 的使用限制；它只會在你指定的時間，模擬一次一般滑鼠單擊或雙擊。Codex 的方案、額度、重設時間與可用選項可能調整，請一律以 Codex 畫面或用量頁面顯示的時間為準。OpenAI 目前的方案說明可參考 [ChatGPT Work 與 Codex Pricing](https://learn.chatgpt.com/docs/pricing)。

本專案是獨立的開源工具，與 OpenAI 沒有隸屬、贊助或官方合作關係。使用時仍應遵守 ChatGPT、Codex 及目標服務的條款。

### 睡前續跑 Codex 的建議流程

1. 在原本的 Codex Session 準備好下一則提示，例如「請繼續上次中斷的工作」，但先不要送出。
2. 查看 Codex 畫面顯示的實際重設時間，將排程設在該時間之後預留一小段緩衝。
3. 擷取送出按鈕或畫面上「繼續」按鈕的位置，並先用無風險內容測試一次。
4. 保持電腦開機、登入且未鎖定；不要移動 Codex 視窗或更改螢幕配置。
5. 啟動排程。若按鈕位置、登入狀態或頁面內容可能改變，請勿無人值守使用。

## Windows 11 使用方式

1. 開啟 `dist\ScheduledClicker.exe`。
2. 選擇「指定時間」或「倒數延遲」。
3. 按「3 秒後擷取滑鼠位置」，接著把滑鼠移到目標位置。
4. 選擇單擊或雙擊，按「啟動排程」並確認。
5. 如需停止，按畫面上的「取消排程」；若 `F8` 未被其他程式占用，也可按 `F8` 緊急停止。

程式必須保持開啟。若目標程式以系統管理員身分執行，本工具也可能需要相同權限，否則 Windows 會阻擋輸入控制。

## macOS 使用方式

1. 從 [GitHub Releases](https://github.com/HaNa-486/ScheduledClicker/releases/latest) 下載 `ScheduledClicker-macOS-universal.zip` 並解壓縮。
2. 第一次開啟時，以 Control-click（或右鍵）點擊 `ScheduledClicker.app`，選擇「打開」。若仍被阻擋，到「系統設定 → 隱私權與安全性」選擇仍要打開。
3. 在工具內擷取位置並啟動排程。macOS 首次控制滑鼠時會要求「輔助使用」權限；請到「系統設定 → 隱私權與安全性 → 輔助使用」允許 `ScheduledClicker`，再回到工具重新啟動排程。
4. 選擇「指定時間」或「倒數延遲」、單擊或雙擊，確認後啟動。工具會自動縮小以免遮住目標；從 Dock 還原後可按取消，鍵盤與權限允許時也可按 `F8`（部分 Mac 鍵盤需按 `Fn+F8`）。

macOS 版需要 macOS 13 Ventura 或更新版本，並同時支援 Apple silicon 與 Intel Mac。程式必須保持開啟，Mac 也必須維持登入、未鎖定且未進入睡眠。

v1.1.1 起介面會跟隨 macOS 的淺色或深色外觀，時間欄位也只會顯示目前選擇的模式。v1.1.2 將三位毫秒時鐘的更新頻率由每秒 10 次提高到約 30 次，使後兩位數也會自然變動；排程引擎與點擊行為不受此畫面更新調整影響。

## 安全設計

### 循環輸入與點擊（開發中，尚未發布）

在同一個視窗頂端選擇「簡單模式」或「循環模式」，共用即時時鐘與語言選單。原本的一次性排程與循環模式不能同時啟動。

循環頁上方左側是時間與停止條件，右側是兩個位置擷取，下方是提示詞。設定、注意事項、操作按鈕與狀態皆在初始／最小視窗完整可見，整頁不需捲動；較長的提示詞可在編輯框內捲動。執行、暫停或擷取期間須先停止目前操作，才能切換模式。切換保留本次開啟期間的提示詞、座標及設定，不會自動重啟排程；完全結束程式後仍不保存設定。

1. 設定**首次執行時間**、**循環間隔**及步驟等待秒數。間隔從上一輪送出點擊操作結束後起算；與服務額度重設無自動連動。
2. 勾選**最多輪次**或**截止時間**，至少一項。若兩者都設定，先達到者停止。
3. 選擇「每輪相同」或「依輪次設定」。後者可逐筆新增／刪除多行提示詞；預設用完停止，也可勾選之後重複最後一筆。同一模式切換不會丟失已編輯的其他輪次。
4. 分別擷取同一目標視窗的**輸入框**與**送出按鈕**。擷取時工具縮小，三秒後記錄滑鼠位置。
5. 預設在輸入游標處插入文字；若勾選「取代輸入框原有文字」，會先全選欄位內容。**貼上會覆寫系統剪貼簿**，原剪貼簿不會自動還原，系統剪貼簿歷程亦可能保留提示詞。
6. 先用無風險目標「試跑一輪」：確認後五秒執行，**真的會輸入並點擊送出**。確認行為正確後再啟動正式循環。
7. 保持電腦喚醒、不鎖屏，目標視窗位置、聊天與輸入框布局固定。工具不偵測 Codex 的忙碌、完成、額度或訊息是否送達。

等待下一輪時可暫停／恢復；恢復後繼續剩餘等待時間，截止時間不延後。若已開始點擊／貼上，停止會取消尚未執行的步驟，**已發生的輸入無法撤回**，須檢查草稿後重新排程。F8（Mac 部分鍵盤為 Fn+F8）、取消或關閉程式視窗可停止。Windows 循環模式要求 F8 註冊成功才能啟動。

每輪依序「點輸入框 → 等待 → 貼上 → 等待 → 點送出」。若目標視窗不可用、螢幕配置改變、步驟遲到超過五秒或輸入 API 回報錯誤，停止且不重試、不補送。介面所列輪數是**已執行送出點擊的輪數**，不等於成功送達的訊息數。程式不保存排程或提示詞，重新開啟後需重新設定。

- 從零撰寫，沒有引用任何第三方套件或網路專案。
- Windows 版只使用 Windows 內建的 .NET Framework、WinForms 與 `user32.dll`；macOS 版只使用 Apple 內建的 Swift、AppKit、Quartz 與 Accessibility API。
- 不連線網路、不讀寫個人檔案、不蒐集資料，也不需要系統管理員權限。
- 啟動前會顯示時間、座標與點擊方式，需再次確認。
- 排程期間會嘗試註冊全域 `F8`；若未被其他程式占用，可用它取消尚未執行的排程，否則畫面會提示改用取消按鈕。
- Windows 的指定時間與倒數延遲已由使用者在 Windows 11 實機確認；macOS 的兩種排程、深色模式介面，以及 v1.1.2 三位毫秒正常變動也已由使用者在 MacBook Air 實機確認。完整建置、安全與實機證據見 [`VERIFICATION.md`](VERIFICATION.md)。

「安全」不代表完全沒有風險：本工具依固定螢幕座標點擊，如果視窗或頁面在排程期間移動，仍可能點到錯誤位置。請先用無風險目標測試，並避免拿它操作付款、刪除、發布或其他不可逆按鈕。Windows EXE 尚未使用商業憑證簽章；macOS app 也未使用 Apple Developer ID 公證。兩者都可能顯示系統安全提醒，可用 `VERIFICATION.md` 的 SHA-256 核對檔案。

## 授權

本專案採用寬鬆的 [MIT License](LICENSE)。任何人都可以在保留著作權與授權聲明的前提下使用、複製、修改、合併、發布、散布、再授權及銷售本軟體副本。授權條款同時聲明軟體按現狀提供、不附帶保證；使用者仍需自行確認自動點擊的目標與風險。

## 從原始碼建置

在 Windows PowerShell 執行：

```powershell
.\build.ps1
```

建置使用 Windows 隨附的 .NET Framework 4 編譯器，不會下載任何相依套件。

在 macOS 13 或更新版本、已安裝 Xcode Command Line Tools 的終端機執行：

```bash
bash ./build-macos.sh
```

腳本會以 Apple `swiftc` 建立同時支援 Apple silicon 與 Intel 的 universal app、執行核心測試與安全自我檢查、做 ad-hoc 簽章並輸出 ZIP 與 SHA-256；不會下載任何相依套件。

## 版本紀錄

請參閱 [`CHANGELOG.md`](CHANGELOG.md)。
