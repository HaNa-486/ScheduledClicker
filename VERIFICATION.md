# 驗證報告

驗證日期：2026-08-28（Asia/Taipei）

Windows 成品：`dist\ScheduledClicker.exe`

版本：1.1.2.0

大小：22,528 bytes

SHA-256：`53305CD519464945E31279DE2BB13ECF6B9E140408A8DD37A13F8A240CD42B97`

## 結果

- 建置：通過；使用 Windows 內建 .NET Framework 4 編譯器，零第三方套件。
- 核心測試：10/10 通過，涵蓋有效排程、過去時間、超過 365 天、多螢幕負座標、螢幕外座標、無效點擊型別、取消狀態，以及倒數不受系統時鐘前後跳動影響。
- 啟動煙霧測試：通過；程式啟動後持續運行，未提前崩潰。
- Microsoft Defender 自訂掃描：2026-08-28 通過；防毒功能啟用、定義檔更新於當日，掃描後沒有與新版 EXE 相符的威脅紀錄。
- 網站檢查：8 個頁面的唯一標題／描述／canonical、JSON-LD、內部連結、圖片 alt、Sitemap 覆蓋及 AI 摘要檔案全部通過。
- 靜態敏感能力搜尋：未發現網路連線、下載、程序啟動、登錄檔、剪貼簿、密碼或權杖功能。
- Authenticode：未簽章。這是本機產生的免費成品，沒有購買程式碼簽章憑證。

## Windows 11 實機結果

- 使用者於 2026-08-26 回報：「指定時間」與「倒數延遲」兩種模式皆測試成功。
- 使用者於 2026-08-28 再次確認 Windows 11 的 v1.1.0 功能可用；v1.1.1 與 v1.1.2 都沒有修改 Windows 排程行為，只更新版本資訊並接受相同 10/10 核心測試與啟動回歸。
- 此項證據來自使用者在自己的 Windows 11 互動式桌面實測，補足 Codex 隔離桌面無法注入滑鼠輸入的環境限制。
- 混合 DPI 多螢幕的每一種縮放組合仍未逐一驗證；若使用不同縮放比例的多螢幕，請先在各螢幕測試安全位置。

## macOS 1.1.2 release candidate

- 目標：macOS 13 Ventura 或更新版本，universal `arm64` + `x86_64` app。
- 原始碼：Apple Swift、AppKit 與 ApplicationServices，沒有第三方套件。
- 使用者實機證據：2026-08-28 於 MacBook Air 確認排程功能與 v1.1.1 深色模式介面可讀；螢幕錄影另證明三位毫秒時鐘以 10 Hz 更新時，視覺上幾乎只有第一位變動。v1.1.2 改用約 30 Hz 的 common-mode UI timer 並快取日期格式器；排程引擎沒有變更。
- CI：[`Build and test` run 33143381799](https://github.com/HaNa-486/ScheduledClicker/actions/runs/33143381799)，候選 commit `59dd6ac47f4295a178e8204374891cee4479e714`，Windows 與 macOS jobs 均成功。
- macOS 核心測試：21/21 通過，涵蓋驗證、單調倒數、系統時鐘變動、排程、執行、取消、重新排程、逾期拒絕、顯示器配置變更及原生點擊失敗。
- 介面外觀與時鐘測試：通過；分別以 `NSAppearanceNameAqua` 與 `NSAppearanceNameDarkAqua` 啟動 AppKit 視窗，主要／次要文字對比、兩種模式欄位可見性、timer 間隔及毫秒後兩位在取樣期間確實變化皆通過。
- 介面視覺檢查：CI 保存淺色與深色實際渲染 PNG；人工檢查確認標題、說明、時鐘、卡片、時間／位置控制、主按鈕、停用的取消按鈕與狀態文字在兩種外觀下皆可辨識。此項仍不取代使用者 MacBook Air 的最終確認。
- 安全自我檢查：通過；runner 可讀取顯示器與游標位置，並成功建立單擊 3 事件與雙擊 5 事件序列，但自我檢查不會送出事件。
- 架構：`x86_64 arm64`，同一個 app 同時支援 Intel 與 Apple silicon。
- plist：`plutil -lint` 通過。
- ad-hoc 簽章：`codesign --verify --deep --strict` 通過，app 為 valid on disk 且符合 Designated Requirement；這不是 Apple Developer ID 簽章或 Apple 公證。
- 封裝：ZIP 只包含 `ScheduledClicker.app`、執行檔、Info.plist、Resources 與 `_CodeSignature`。
- macOS ZIP 大小：131,048 bytes。
- macOS ZIP SHA-256：`B7513F075E235A876D3417D84E62CC5C1FF957C24C22004D7B4C4090E92DF0E2`；下載 CI artifact 後以 Windows `Get-FileHash` 二次核對，與 runner 產生的 `.sha256` 完全相符。
- CI runner 不會取得使用者的輔助使用權限，因此刻意不注入真實滑鼠點擊。指定時間、倒數延遲與 v1.1.1 深色介面已由使用者在 MacBook Air 實機確認；v1.1.2 毫秒動畫修正仍需在實機做最後視覺確認。

結論：Windows 1.1.2 已通過本機建置、10/10 核心測試、啟動煙霧測試、靜態能力檢查、網站檢查與 Defender 掃描；macOS 1.1.2 已通過 21/21 核心測試、淺色／深色與毫秒動畫介面測試、安全自我檢查、universal 架構、plist、ad-hoc 簽章與封裝驗證。未簽章／未公證、固定座標誤點、尚未完整覆蓋的 Windows 混合 DPI 組合，以及 v1.1.2 毫秒動畫尚待實機視覺確認，都是已知限制。

## v1.1.1 發布後核對（歷史紀錄）

- 公開 Release：[`v1.1.1`](https://github.com/HaNa-486/ScheduledClicker/releases/tag/v1.1.1)，非草稿、非預發布版，標籤指向 commit `94da9bc03a52baa9430cc5c1b6970eea34d05f00`。
- 已從公開 Release 重新下載三個資產；GitHub 資產 digest 與本機重算結果確認 Windows EXE SHA-256 為 `5215937ABDF90DB24167B217F199FCE221B275438F1F1B027AB8A787B0706C13`，macOS ZIP 為 `20090A3B1D2E8D823C3343031E530CA82FC1E0B3781BB5FCA2FCAC6A26CCF56B`。
