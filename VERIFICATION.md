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
- 必須通過：真實 macOS runner 編譯、完整核心測試、游標／事件建立自我檢查、雙架構檢查、plist 驗證、ad-hoc 簽章驗證及 ZIP SHA-256。
- 目前狀態：**等待 GitHub macOS CI 證據，不可視為已發布或互動式實機驗證完成。**
- 即使 CI 通過，GitHub runner 也不會取得使用者的輔助使用權限，因此不會真的注入滑鼠點擊。使用者仍需在自己的 Mac 授權後，以無風險目標測試指定時間與倒數延遲。

結論：Windows 版可供一般 Windows 11 使用者試用。macOS 版必須在 CI 與發布資產驗證完成後才可發布；未簽章／未公證、固定座標誤點、尚未完整覆蓋的 Windows 混合 DPI 組合，以及尚未完成的 macOS 互動式實機點擊，都是已知限制。
