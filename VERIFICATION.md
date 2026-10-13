# 驗證報告

## 2026-10-13：共用視窗與完整可見版面（尚未發布）

- 兩模式共用一個視窗、時鐘、語系與模式切換；循環時間左／位置右、提示詞置於下方，注意事項與操作／狀態固定可見。Windows 初始 client size 1040 × 680，最小尺寸同初始值，放大時欄位跟著擴展。整頁無捲軸；提示詞框內仍可捲動長文字。此版取代下方歷史紀錄的獨立視窗、返回即停止、設定區捲動行為。
- Windows build 通過；40 循環核心、10 原本核心與 2050 語系／版面／状态檢查通過。檢查每個循環控制項在所有祖先容器內完整可見、提示詞框最低高度、五語系長錯誤訊息、初始與最小視窗。中文／英文／德文原生渲染已人工檢查。
- UI 回歸確認模式切換保留同一 HWND、尺寸、提示詞與游標；共用時鐘更新；兩種排程及擷取期間禁止切換；取消後可切換；關閉視窗停止循環並釋放控制項。
- `UnifiedIntegrationTest.exe` 僅操作自建拋棄式目標：實際確認試跑、共用視窗最小化、中文多行 emoji 貼上、取代草稿、送出、完成後切換／再次啟動、關閉取消均通過。F8 註冊成功且向已註冊 handle 排入 WM_HOTKEY 可在輸入前停止；未模擬實體鍵盤按鍵。保留原有兩輪原生測試歷史證據。
- 獨立來源審查未發現共用視窗的生命週期、並行操作、權限或隱私告知缺陷。確認視窗與剪貼簿／真實輸入／未驗證送達等資訊維持。
- macOS 已同步同視窗與版面原始碼及 smoke 檢查，尚未編譯／原生驗證。所有 DPI、多螢幕與小於最低視窗可用區域的螢幕尚未逐一驗證。依約未公開推送、未啟動 macOS CI、未產生 Mac ZIP。

## 2026-10-13：五語系與固定注意事項（尚未發布）

- Windows `build.ps1` 通過；40/40 循環核心、10/10 原本核心與導航／時鐘回歸通過。
- `LocalizationTests.exe`：1166 項檢查通過，包含 206 組完整翻譯、格式參數、七種新程序啟動語系、中文變體及其他語系 fallback、組合狀態文字、兩模式語系同步、提示詞／游標／設定／執行中計畫保留、注意事項在初始與最小視窗可見、五種語言的實際 modal 確認與取消。
- 產出兩模式、最小循環視窗及確認視窗的五語系 PNG；人工檢查中文、英文、德文、日文、韓文畫面，未發現文字遮蔽。未涵蓋所有 DPI、多螢幕與螢幕閱讀器組合。
- 測試過程曾因 `Form.ActiveForm` 不指向已開啟的確認視窗，出現使用者回報的 `No confirmation dialog`。已改用持有的 dialog 實例，fixture 隱藏執行，UI 例外使測試失敗而非開啟阻塞式 .NET 視窗。上述 1166 結果來自修正後無人工介入的完整新執行；先前被打斷的執行不算驗收證據。
- 共用翻譯表產生器完整性、占位符與產物一致性檢查通過。沒有翻譯服務、網路請求或提示詞儲存。
- 獨立 privacy/authorization 原始碼審查確認各語言保留剪貼簿覆寫、試跑真輸入／送出、取代／插入及未驗證送達的資訊；語系切換不呼叫原生輸入。發現 macOS 狀態文字重疊，已修正並以矩形座標重新審查。
- macOS 原始碼、語系測試與每語言 AppKit smoke 測試已加入，但**未編譯或執行**。依使用者要求，公開推送、macOS CI／ZIP 都等 Windows 本機測試 review 完成後再決定。
- 未修改排程核心或原生輸入邏輯；本輪不重複外部原生輸入測試。原有 Windows 拋棄式目標整合證據見下。

## 2026-10-13：循環輸入開發版（尚未發布）

- Windows 本機 `build.ps1` 編譯通過；新增循環核心 40/40、原本核心 10/10 通過。
- 循環核心涵蓋相同／序列／重複最後一筆、次數／截止（含貼上後截止與暫停期間截止）、逐步取消、失敗不重試、逾期不補送、單調間隔與慢速原生操作後完整等待。
- `LoopUiTests.exe`：提示詞新增、切換與編輯不遺失資料，介面上下捲動渲染通過；本機 PNG 已人工查看。未驗證每種 DPI／輔助技術組合。
- 介面修正後追加驗證：固定標頭時鐘持續變動、返回按鈕位於可見區域、返回會停止已啟動的循環、重新進入保留提示詞且時鐘恢復更新；Windows 自動測試與畫面檢查通過，macOS 對應測試尚未執行。
- `LoopIntegrationTest.exe`：在互動式桌面的拋棄式 WinForms 目標，實際完成兩輪中文、多行、emoji、取代草稿、送出點擊與不同第二輪提示詞。隔離桌面不允許剪貼簿，故原生測試在經工具審核允許的互動式桌面執行；沒有操作外部聊天。
- 獨立審查修正 macOS 同應用程式不同視窗的焦點防護，以及兩平台從原生操作完成後才起算延遲；重新審查沒有發現其他確定的程式缺陷。
- macOS：對應原始碼、40 項核心測試、淺／深色循環 UI 測試與建置流程已加入。**目前未執行 macOS 編譯、測試、原生貼上／送出／F8 或同應用程式不同視窗的拒絕測試。** 原有 v1.1.2 的實機證據不代表新增循環功能通過。
- 網站靜態檢查通過（8 頁）；公開網站與 Release 維持 v1.1.2，不宣稱已發布循環功能。
- 新功能使用系統剪貼簿且會覆寫內容；舊版本「無剪貼簿」檢查結論僅適用下方歷史版本。提示詞不由本工具寫入檔案，但可能保留於系統剪貼簿歷程或目標應用程式。
- 評估：Windows 可供本機試用；雙平台發布 **not-ready**，待 macOS CI 與實機驗證。候選執行檔位置、雜湊與機器資訊留於忽略的 `.pdos/local/`。

## 歷史版本 1.1.2

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
- 使用者實機證據：2026-08-28 於 MacBook Air 確認 v1.1.2 測試正常，三位毫秒會正常變動；先前已確認指定時間、倒數延遲與深色模式介面可讀。v1.1.2 使用約 30 Hz 的 common-mode UI timer 並快取日期格式器；排程引擎沒有變更。
- CI：[`Build and test` run 33143381799](https://github.com/HaNa-486/ScheduledClicker/actions/runs/33143381799)，候選 commit `59dd6ac47f4295a178e8204374891cee4479e714`，Windows 與 macOS jobs 均成功。
- macOS 核心測試：21/21 通過，涵蓋驗證、單調倒數、系統時鐘變動、排程、執行、取消、重新排程、逾期拒絕、顯示器配置變更及原生點擊失敗。
- 介面外觀與時鐘測試：通過；分別以 `NSAppearanceNameAqua` 與 `NSAppearanceNameDarkAqua` 啟動 AppKit 視窗，主要／次要文字對比、兩種模式欄位可見性、timer 間隔及毫秒後兩位在取樣期間確實變化皆通過。
- 介面視覺檢查：CI 保存淺色與深色實際渲染 PNG；人工檢查確認標題、說明、時鐘、卡片、時間／位置控制、主按鈕、停用的取消按鈕與狀態文字在兩種外觀下皆可辨識。使用者另在 MacBook Air 完成 v1.1.2 最終實機確認。
- 安全自我檢查：通過；runner 可讀取顯示器與游標位置，並成功建立單擊 3 事件與雙擊 5 事件序列，但自我檢查不會送出事件。
- 架構：`x86_64 arm64`，同一個 app 同時支援 Intel 與 Apple silicon。
- plist：`plutil -lint` 通過。
- ad-hoc 簽章：`codesign --verify --deep --strict` 通過，app 為 valid on disk 且符合 Designated Requirement；這不是 Apple Developer ID 簽章或 Apple 公證。
- 封裝：ZIP 只包含 `ScheduledClicker.app`、執行檔、Info.plist、Resources 與 `_CodeSignature`。
- macOS ZIP 大小：131,048 bytes。
- macOS ZIP SHA-256：`B7513F075E235A876D3417D84E62CC5C1FF957C24C22004D7B4C4090E92DF0E2`；下載 CI artifact 後以 Windows `Get-FileHash` 二次核對，與 runner 產生的 `.sha256` 完全相符。
- CI runner 不會取得使用者的輔助使用權限，因此刻意不注入真實滑鼠點擊。指定時間、倒數延遲、深色介面與 v1.1.2 三位毫秒動畫均已由使用者在 MacBook Air 實機確認。

結論：Windows 1.1.2 已通過本機建置、10/10 核心測試、啟動煙霧測試、靜態能力檢查、網站檢查與 Defender 掃描；macOS 1.1.2 已通過 21/21 核心測試、淺色／深色與毫秒動畫介面測試、安全自我檢查、universal 架構、plist、ad-hoc 簽章、封裝驗證及 MacBook Air 實機確認。未簽章／未公證、固定座標誤點與尚未完整覆蓋的 Windows 混合 DPI 組合仍是已知限制。

## v1.1.1 發布後核對（歷史紀錄）

- 公開 Release：[`v1.1.1`](https://github.com/HaNa-486/ScheduledClicker/releases/tag/v1.1.1)，非草稿、非預發布版，標籤指向 commit `94da9bc03a52baa9430cc5c1b6970eea34d05f00`。
- 已從公開 Release 重新下載三個資產；GitHub 資產 digest 與本機重算結果確認 Windows EXE SHA-256 為 `5215937ABDF90DB24167B217F199FCE221B275438F1F1B027AB8A787B0706C13`，macOS ZIP 為 `20090A3B1D2E8D823C3343031E530CA82FC1E0B3781BB5FCA2FCAC6A26CCF56B`。

## v1.1.2 發布後核對

- 公開 Release：[`v1.1.2`](https://github.com/HaNa-486/ScheduledClicker/releases/tag/v1.1.2)，非草稿、非預發布版，標籤指向 commit `bee4fa37f37b2acf87faf0b6e2421c7c8233482a`。
- main 正式 CI：[`Build and test` run 33155119817](https://github.com/HaNa-486/ScheduledClicker/actions/runs/33155119817)，Windows 與 macOS jobs 均成功。
- 已從公開 Release 重新下載全部三個資產；GitHub asset digest 與本機 SHA-256 一致：Windows EXE `53305CD519464945E31279DE2BB13ECF6B9E140408A8DD37A13F8A240CD42B97`、macOS ZIP `B7513F075E235A876D3417D84E62CC5C1FF957C24C22004D7B4C4090E92DF0E2`、checksum 文字檔 `691605B4B4D5ABC29ECB0A56539036411EFDA6B63E605D4A707D7671E309A107`。
- GitHub Pages run `33155119176` 成功；8 個 HTML 頁面、Sitemap、`llms.txt`、`llms-full.txt` 與三張真實介面圖的公開 URL 均回傳 HTTP 200，首頁版本為 1.1.2，Sitemap 包含 8 個 canonical URL。
