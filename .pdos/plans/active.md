# Active plan

Current status is the first row. Earlier rows record slice-time evidence; Windows acceptance and Mac CI now supersede their historical deferral wording.

| Slice | Outcome | Risk | Verification | Status |
|---|---|---|---|---|
| Mac foreground diagnosis | Live AX keyboard owner, staged activation, copyable diagnostics | Wrong-target input / cancel race | CI 38710315157, 54 loop + 10 focus + full regression; independent review | build 12003 implemented; native retest pending |
| Mac acceptance repair | AX identity, untouched prompt localization, numeric wheel | Wrong-target input / native Safari compatibility | CI 38696929654, 9 focus + 15 numbers + full regression | preview.2 implemented; owner native retest |
| Mac preview + discovery | Universal 1.2.0-preview.1、九頁版本化內容與 AI 摘要 | 原生輸入／公開發布界線 | CI 38688961403、24 Mac renders、9 pages + 71 facts、獨立審查 | candidate verified; native Mac owner testing pending |
| 深淺色視覺重設計 | 中性色層次、圓角元件、小型日月按鈕、Mac 原生外觀 | 日期編輯、可讀性、語系與焦點回歸 | Windows 2066 locale + 153 appearance + 15 picker + 20 date checks；Mac source only | Windows local aesthetic review; Mac deferred |
| 系統外觀／深淺色切換 | 啟動跟隨系統、共用按鈕、兩模式與確認同步 | 對比、停用狀態、選單回歸 | Windows 153 appearance + 2061 locale + 15 native picker；Mac source only | Windows local review; Mac build deferred |
| 共用視窗／完整可見版面 | 同視窗切換、時間左／位置右、全部設定可見、兩模式一致 | 切換競態、關閉取消、文字裁切 | Windows 2050 checks + 40/10 core + 原生共用視窗試跑通過；獨立審查；macOS source only | Windows local review; Mac build explicitly deferred |
| 五語系／固定注意事項 | 系統選語系、兩模式同步切換、固定可見 notices | 誤譯告知、草稿重寫、版面遮蔽 | Windows 1166 checks + 40/10 core + 導航通過；獨立告知審查；macOS source only | Windows local review; Mac build explicitly deferred |
| 有界循環輸入／送出 | 同提示詞或序列，雙座標、次數／截止、暫停／停止，Windows/macOS | 焦點、剪貼簿、重複送出、錯過時間 | Windows 40 核心 + 10 既有測試、UI 編輯／渲染、兩輪原生中文多行輸入通過；macOS 待編譯與實機 | implemented; awaiting macOS verification |
| 核心排程與輸入 | 指定未來時間執行單/雙擊 | 計時競態、錯誤座標 | 10/10 邊界測試通過；隔離桌面拒絕 SendInput，待使用者實機確認 | completed |
| WinForms UI | 時鐘、兩種時間模式、座標擷取、取消 | 操作誤解 | 啟動煙霧測試通過；實際畫面互動待使用者桌面確認 | completed |
| 安全與交付 | 無第三方相依的單一 EXE | 未簽章警示、供應鏈 | 靜態掃描、Defender、SHA-256 均完成 | completed |
| macOS 原生版本 | macOS 13+ universal app 與 Windows 功能對等 | Accessibility 權限、未公證、跨架構 | 21/21 核心測試、自我檢查、universal 架構與 ad-hoc 簽章由 macOS 15 CI 驗證 | completed |
| macOS 深色模式 UX | v1.1.1 在 Aqua／Dark Aqua 都清楚可讀，並簡化時間模式與狀態層級 | 動態色彩、固定框架、實機視覺差異 | CI run 33139685219：兩種外觀啟動、對比／欄位可見性、實際 PNG 人工檢查；獨立審查無阻擋項目 | completed |
| 跨平台文件與探索 | README、安全說明、網站與 AI/社群 metadata 正確反映雙平台 | 過度宣稱互動式實機證據 | CI 證據與未驗證項目分開揭露；Google metadata 靜態檢查 | completed |
| v1.1.2 時鐘與探索維護 | macOS 三位毫秒自然更新；跨平台搜尋與 AI 文件完整 | UI timer 合併、搜尋過度宣稱 | CI 33143381799／33143876718、8 頁 validator、獨立 release review | completed |
| 網站導覽與下載可讀性 | 8 個頁面使用一致導覽，下載按鈕在所有狀態清楚可讀 | 靜態頁面分散維護、CSS specificity | URL/current-page validator、桌面與 375 px 瀏覽器旅程、10.10:1 對比、獨立 re-review | completed |
