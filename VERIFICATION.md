# 驗證報告

驗證日期：2026-08-26（Asia/Taipei）

Windows 成品：`dist\ScheduledClicker.exe`

版本：1.1.0.0

大小：22,528 bytes

SHA-256：`DE9FEE3CCD277EA3627E5070088A5CF67909CD8D68914F779E017DA48BED6C3E`

## 結果

- 建置：通過；使用 Windows 內建 .NET Framework 4 編譯器，零第三方套件。
- 核心測試：10/10 通過，涵蓋有效排程、過去時間、超過 365 天、多螢幕負座標、螢幕外座標、無效點擊型別、取消狀態，以及倒數不受系統時鐘前後跳動影響。
- 啟動煙霧測試：通過；程式啟動後持續運行，未提前崩潰。
- Microsoft Defender 自訂掃描：通過，未發現與新版 EXE 相符的威脅；命令結束碼 0。
- 靜態敏感能力搜尋：未發現網路連線、下載、程序啟動、登錄檔、剪貼簿、密碼或權杖功能。
- Authenticode：未簽章。這是本機產生的免費成品，沒有購買程式碼簽章憑證。

## Windows 11 實機結果

- 使用者於 2026-08-26 回報：「指定時間」與「倒數延遲」兩種模式皆測試成功。
- 此項證據來自使用者在自己的 Windows 11 互動式桌面實測，補足 Codex 隔離桌面無法注入滑鼠輸入的環境限制。
- 混合 DPI 多螢幕的每一種縮放組合仍未逐一驗證；若使用不同縮放比例的多螢幕，請先在各螢幕測試安全位置。

## macOS release candidate

- 目標：macOS 13 Ventura 或更新版本，universal `arm64` + `x86_64` app。
- 原始碼：Apple Swift、AppKit 與 ApplicationServices，沒有第三方套件。
- CI：[`Build and test` run 32950460010](https://github.com/HaNa-486/ScheduledClicker/actions/runs/32950460010)，候選 commit `e320e8262131f4defe6fed19303528bff71d78e8`，Windows 與 macOS jobs 均成功。
- macOS 核心測試：21/21 通過，涵蓋驗證、單調倒數、系統時鐘變動、排程、執行、取消、重新排程、逾期拒絕、顯示器配置變更及原生點擊失敗。
- 安全自我檢查：通過；runner 可讀取顯示器與游標位置，並成功建立單擊 3 事件與雙擊 5 事件序列，但自我檢查不會送出事件。
- 架構：`x86_64 arm64`，同一個 app 同時支援 Intel 與 Apple silicon。
- plist：`plutil -lint` 通過。
- ad-hoc 簽章：`codesign --verify --deep --strict` 通過，app 為 valid on disk 且符合 Designated Requirement；這不是 Apple Developer ID 簽章或 Apple 公證。
- 封裝：ZIP 只包含 `ScheduledClicker.app`、執行檔、Info.plist、Resources 與 `_CodeSignature`。
- macOS ZIP 大小：102,344 bytes。
- macOS ZIP SHA-256：`20303159765B40BF536E88DFBCBE5B21582D0691DBDDCFCB038D30E615F6993F`；下載 CI artifact 後以 Windows `Get-FileHash` 二次核對，與 runner 產生的 `.sha256` 完全相符。
- CI runner 不會取得使用者的輔助使用權限，因此刻意不注入真實滑鼠點擊。使用者仍需在自己的 Mac 授權後，以無風險目標測試指定時間與倒數延遲。

結論：Windows 版可供一般 Windows 11 使用者試用；macOS release candidate 已達到自動化建置與安全驗證門檻，可在 GitHub Release 發布供 macOS 使用者試用。未簽章／未公證、固定座標誤點、尚未完整覆蓋的 Windows 混合 DPI 組合，以及尚未完成的 macOS 互動式實機點擊，都是已知限制。
