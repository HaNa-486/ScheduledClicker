# 驗證報告

驗證日期：2026-08-28（Asia/Taipei）

Windows 成品：`dist\ScheduledClicker.exe`

版本：1.1.1.0

大小：22,528 bytes

SHA-256：`5215937ABDF90DB24167B217F199FCE221B275438F1F1B027AB8A787B0706C13`

## 結果

- 建置：通過；使用 Windows 內建 .NET Framework 4 編譯器，零第三方套件。
- 核心測試：10/10 通過，涵蓋有效排程、過去時間、超過 365 天、多螢幕負座標、螢幕外座標、無效點擊型別、取消狀態，以及倒數不受系統時鐘前後跳動影響。
- 啟動煙霧測試：通過；程式啟動後持續運行，未提前崩潰。
- Microsoft Defender 自訂掃描：2026-08-28 通過，掃描完成後沒有與新版 EXE 相符的威脅紀錄。
- 靜態敏感能力搜尋：未發現網路連線、下載、程序啟動、登錄檔、剪貼簿、密碼或權杖功能。
- Authenticode：未簽章。這是本機產生的免費成品，沒有購買程式碼簽章憑證。

## Windows 11 實機結果

- 使用者於 2026-08-26 回報：「指定時間」與「倒數延遲」兩種模式皆測試成功。
- 使用者於 2026-08-28 再次確認 Windows 11 的 v1.1.0 功能可用；v1.1.1 只調整版本資訊並接受相同 10/10 核心測試與啟動回歸。
- 此項證據來自使用者在自己的 Windows 11 互動式桌面實測，補足 Codex 隔離桌面無法注入滑鼠輸入的環境限制。
- 混合 DPI 多螢幕的每一種縮放組合仍未逐一驗證；若使用不同縮放比例的多螢幕，請先在各螢幕測試安全位置。

## macOS 1.1.1 release candidate

- 目標：macOS 13 Ventura 或更新版本，universal `arm64` + `x86_64` app。
- 原始碼：Apple Swift、AppKit 與 ApplicationServices，沒有第三方套件。
- 使用者實機證據：2026-08-28 於 MacBook Air 確認 v1.1.0 排程功能可用；同時提供深色外觀截圖，證明固定淺色背景造成白字白底。v1.1.1 針對此缺陷改用 AppKit 語意背景色並重整表單。
- CI：待 v1.1.1 候選 commit 的 GitHub-hosted macOS 15 runner 完成後補入。
- macOS 核心測試：21/21 通過，涵蓋驗證、單調倒數、系統時鐘變動、排程、執行、取消、重新排程、逾期拒絕、顯示器配置變更及原生點擊失敗。
- 介面外觀測試：v1.1.1 建置會分別以 Aqua 與 Dark Aqua 啟動 AppKit 視窗，檢查主要／次要文字對比以及指定時間／倒數延遲欄位可見性；CI 結果待補。
- 安全自我檢查：通過；runner 可讀取顯示器與游標位置，並成功建立單擊 3 事件與雙擊 5 事件序列，但自我檢查不會送出事件。
- 架構：`x86_64 arm64`，同一個 app 同時支援 Intel 與 Apple silicon。
- plist：`plutil -lint` 通過。
- ad-hoc 簽章：`codesign --verify --deep --strict` 通過，app 為 valid on disk 且符合 Designated Requirement；這不是 Apple Developer ID 簽章或 Apple 公證。
- 封裝：ZIP 只包含 `ScheduledClicker.app`、執行檔、Info.plist、Resources 與 `_CodeSignature`。
- macOS ZIP 大小與 SHA-256：待 v1.1.1 CI 候選成品產生後補入。
- CI runner 不會取得使用者的輔助使用權限，因此刻意不注入真實滑鼠點擊。既有 v1.1.0 互動式點擊已由使用者實機確認；v1.1.1 的新版介面仍需使用者在自己的 Mac 做最後視覺確認。

結論：Windows 1.1.1 已通過本機建置、10/10 核心測試、啟動煙霧測試、靜態能力檢查與 Defender 掃描。macOS 1.1.1 在 CI 與外觀測試完成前仍是候選狀態。未簽章／未公證、固定座標誤點、尚未完整覆蓋的 Windows 混合 DPI 組合，以及新版 macOS 介面尚待實機視覺確認，都是已知限制。
