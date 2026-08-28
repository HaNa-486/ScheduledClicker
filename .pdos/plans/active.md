# Active plan

| Slice | Outcome | Risk | Verification | Status |
|---|---|---|---|---|
| 核心排程與輸入 | 指定未來時間執行單/雙擊 | 計時競態、錯誤座標 | 10/10 邊界測試通過；隔離桌面拒絕 SendInput，待使用者實機確認 | completed |
| WinForms UI | 時鐘、兩種時間模式、座標擷取、取消 | 操作誤解 | 啟動煙霧測試通過；實際畫面互動待使用者桌面確認 | completed |
| 安全與交付 | 無第三方相依的單一 EXE | 未簽章警示、供應鏈 | 靜態掃描、Defender、SHA-256 均完成 | completed |
| macOS 原生版本 | macOS 13+ universal app 與 Windows 功能對等 | Accessibility 權限、未公證、跨架構 | 21/21 核心測試、自我檢查、universal 架構與 ad-hoc 簽章由 macOS 15 CI 驗證 | completed |
| macOS 深色模式 UX | v1.1.1 在 Aqua／Dark Aqua 都清楚可讀，並簡化時間模式與狀態層級 | 動態色彩、固定框架、實機視覺差異 | CI run 33139685219：兩種外觀啟動、對比／欄位可見性、實際 PNG 人工檢查；獨立審查無阻擋項目 | completed |
| 跨平台文件與探索 | README、安全說明、網站與 AI/社群 metadata 正確反映雙平台 | 過度宣稱互動式實機證據 | CI 證據與未驗證項目分開揭露；Google metadata 靜態檢查 | completed |
| v1.1.2 時鐘與探索維護 | macOS 三位毫秒自然更新；跨平台搜尋與 AI 文件完整 | UI timer 合併、搜尋過度宣稱 | CI 33143381799／33143876718、8 頁 validator、獨立 release review | completed |
