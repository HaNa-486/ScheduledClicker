# 驗證報告

## 2026-10-15：使用者回報 Mac build12004 功能驗收通過

- 使用者回報「mac os 版本全部功能都能正常使用了」。記錄為最新 Mac 候選版的實機功能驗收；未逐項提供錯誤視窗拒絕、F8 或首次授權負向測試結果，不補造個別案例證據。
- Windows 差異核對：從先前視覺驗收後的 preview.1 基準到目前，功能變更只有未編輯預設提示詞跟隨語系、保護使用者自行編輯文字；另有 preview.2 版本資訊及共用翻譯。從 preview.2 (`7a75cba`) 到目前，Windows 只增加五筆 Mac 所需共用字串，點擊、貼上、排程與介面事件邏輯未改。
- 目前 CI 已通過 Windows 2102 語系／版面及既有完整回歸。若未測過預設提示詞語系變更，只需針對該功能和一次循環試跑短測；無須因 Mac AX/Dock 修正重新執行整套 Windows 驗收。
- 本次是驗收回報與差異確認，沒有正式發布、合併或網站部署授權。以下為歷史證據。


## 2026-10-15：Dock 誤擷取根因修正候選（build 12004）

- 已確認根因：build12003 使用者診斷顯示 target app=Dock、layer20，隨後要求啟用 Dock，並於 input-click 前因目標比對失敗停止。舊程式以 CG 視窗外框涵蓋座標的第一個項目選 owner，誤將 compositor surface 當成可輸入視窗；not-prohibited activation policy 並未排除 Dock。上一版啟用流程放大此擷取錯誤。先前 build12002 的失敗與此相符，但沒有相同 trace，不能把其所有 native 原因一併視為證實。
- 修正：system-wide AX hit-test 找 owning AXWindow/PID，保存原始 window/topLevel identity 與 AX bounds；每個階段直接對照已保存的身分，focused/keyboard/current hit 都必須匹配。移除 CG rectangle 作為目標權威，不以忽略 Dock/nonzero layers 方式點穿遮擋。只支援一般可存取 App 視窗，AX 失敗無 fallback。
- 新增擷取前授權提示；拒絕時不倒數、不最小化，清除該側舊目標。獨立審查指出的第二次 hit 可能重綁 sibling 問題也已修正，A→B 序列 fixture 覆蓋。剪貼簿仍在全部驗證之後寫入。
- [CI 38718545337](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38718545337)，來源 `8943758`，兩平台成功：Mac 21 原核心、54 循環、31 擷取／焦點身分、15 數字、1116 語系檢查與 24 UI renders；Windows 40/10 核心、2102 語系／版面及既有選單、外觀、日期、共用視窗回歸通過。中文深色渲染已檢視。
- [精確 build12004 產物](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38718545337/artifacts/11963866520)：內層 ZIP 379053 bytes，bundle 1.2.0/build12004，SHA-256 `D159B0A4E610A97A9281CB227FDA9E64D204DCBCADB8D4AA2BEECAE3BC55DE61`。下載後比對 checksum 與 Info.plist 通過；CI universal 架構與 ad-hoc 簽章檢查通過。
- 獨立審查修正後無剩餘 source blocker。政策測試不代表 owner 桌面上透明 Dock surface 的 AX 命中結果，Safari/Word 原生擷取／貼上／送出、錯誤 sibling 拒絕與 F8 仍待驗收。build12003 實機失敗已記錄，build12004 是候選而非已確認修復。無正式發布、合併或網站部署。


## 2026-10-15：Mac 前景程式檢查與啟用流程修正候選（build 12003）

- 實機證據：使用者確認已替換 build 12002，Safari 與 Word 都無法循環輸入；輸入框有游標。完整錯誤沒有代碼。對照該版本，無代碼訊息來自外層 NSWorkspace 前景 PID 檢查，發生在剪貼簿寫入前。前景狀態差異或擷取到錯誤 owner 的底層原因仍未確定；不能把游標或程式碼推論當成已證實的 native root cause。
- 修正：改查 system-wide AXFocusedApplication 的鍵盤接收程序；每輪先驗證擷取位置、必要時要求目標程式啟用，等待一個設定的步驟間隔，下一個 tick 再檢查後點擊。貼上前仍檢查 AX owning-window 與 top-level 身分。取消、F8、截止與逾時仍阻止後續步驟，沒有延遲貼上 callback；沒有 Safari/Word 特例。
- 可觀測性：標題顯示 build 12003、擷取位置顯示 App 名稱；新增五語系「複製診斷」。只包含 build/OS、程序/視窗 ID、layer、前景比對與階段/錯誤，不讀取提示詞、剪貼簿內容或視窗標題。使用者主動複製診斷會覆蓋剪貼簿。
- [CI 38710315157](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38710315157)，來源 `05861ea`，兩平台成功：Mac 21 原核心、54 循環、10 焦點策略、15 數字欄位、1111 語系檢查、自我檢查與 24 渲染；Windows 40 循環、10 原核心、2097 語系／版面、15 選單、153 外觀、20 日期及共用視窗通過。中文深色 Mac 循環渲染已檢視，複製診斷按鈕完整可見。
- [精確 Mac 產物](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38710315157/artifacts/11960920186)：內層 ZIP 367612 bytes，bundle 1.2.0/build 12003，SHA-256 `0721C59A0471F34854A05370CB1A60A9FDC9C12010AA9D142587C3584EB26D55`；下載後與 CI checksum、Info.plist 比對通過。CI 驗證 x86_64/arm64 與 ad-hoc 簽章。
- 獨立唯讀審查：未發現新的狀態機、API、診斷隱私或取消流程阻擋問題；審查不是原生輸入驗證。依據 [Apple AXFocusedApplication 文件](https://developer.apple.com/documentation/applicationservices/kaxfocusedapplicationattribute)，該屬性識別目前接受鍵盤輸入的程式。
- 狀態：build 12002 實機驗收失敗；build 12003 僅為修正候選，Safari/Word 貼上、錯誤 sibling 視窗拒絕、外接螢幕與實體 F8 仍待使用者驗收。Windows 功能未改，candidate 版本仍 preview.2。未合併、未正式發布、未部署網站。前次段落為歷史證據。


## 2026-10-15：Mac Safari 焦點、預設提示詞與數字滾輪修正（preview.2）

- 使用者在 MacBook Air 闔蓋、單一外接螢幕的 Safari 上回報：單點成功，循環貼上前顯示焦點離開。原版把 AX 查詢失敗、跨 API 框架不完全相等、同程序視窗順序不符都合併為焦點離開。已確認檢查設計與診斷有問題，但無原機資料，不能斷言是哪一個條件觸發本次故障。
- 修正使用 AX hit test、所屬視窗 PID／CFEqual 及 top-level container；保留原 CG 身份／位置／遮擋、前景 App、桌面／修飾鍵檢查。Safari remote AX leaf 可屬不同程序，必須仍連回相同目標視窗。無法驗證時停止並回報無內容的 AX.*／focus.* 代碼，沒有退回僅比 PID。獨立審查通過。
- 預設提示詞以前只在建立時翻譯；現於閒置切換語系時同步未編輯的初始提示詞。使用者編輯或刪除後永久退出自動翻譯；兩平台一致，執行中的計畫保留原文字。
- Mac 兩模式時／分／秒、循環等待與輪次改用數字滾輪欄位；保留輸入，限制上下限、停用／隱藏、作用中 field editor，累積觸控板 delta 且忽略慣性。日期欄仍為原生分段／步進器。
- [CI 38696929654](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38696929654)，來源 7a75cba，兩平台成功：Mac 21 核心、40 循環、9 焦點策略、15 數字欄位、1091 語系檢查、自我檢查與 24 渲染；Windows 40 循環、10 原核心、2077 語系／版面、15 選單、153 外觀、20 日期及共用視窗通過。英文深色 Mac 循環產物已檢視。
- Mac ZIP 356603 bytes，bundle 1.2.0/build 12002；SHA-256 `87C37E389B9D0EFB77DFD6A7646E7ECEE9FFEA105A8D9789B2CCE97E11319980`，下載後比對 CI checksum 通過。Windows preview.2 EXE 另存候選目錄，既有 tracked EXE 已還原。
- 仍待實機：Safari 正常試跑、同程序不同視窗／sheet 阻擋、外接螢幕滑鼠／觸控板事件、實體 F8。Fake AX 策略與 NS field 測試不能證明原機輸入已修好；維持預覽版，不正式發布。

## 2026-10-15：macOS 預覽版與探索內容（尚未正式發布）

- 使用者已確認 Windows 測試 OK，授權開始 Mac 建置與內容更新；本節取代下方歷史紀錄中的「Mac 尚未編譯／等待授權」。
- [CI 38688961403](https://github.com/HaNa-486/ScheduledClicker/actions/runs/38688961403)，來源 `12dbed9`：Windows 與 macOS 均成功。Mac 21 原本核心、40 循環核心、1086 語系檢查、自我檢查及 24 張 UI 渲染通過。五語系 × 深淺色 × 兩模式加 4 張預設畫面；已檢視中文、德文、日文、韓文實際產物。
- Mac 修正共用標頭模式選擇與主題鈕重疊，保留 13 pt 間隔；主題按鈕只顯示日／月圖示，另有翻譯 tooltip 與 accessible label。加入非重疊與圖示語意檢查。早期一次 UI smoke 僅有泛用失敗，原因未能確定；已補逐項診斷與失敗截圖，時鐘測試改為最多 5 秒觀察到變化，避免依賴固定 0.5 秒取樣。後續兩次完整 CI 通過。
- Windows CI：40 循環、10 原本核心、2066 語系／版面、15 原生選單、153 外觀、20 日期與共用視窗生命週期檢查通過。此輪未改 Windows 輸入核心。
- Mac ZIP：343687 bytes；SHA-256 `26AA4D27AD52B260DE6802FC2BBD6945F75B6E1067672B61B57CF2398C524E44`。CI／下載後雜湊一致；檢查 FAT Mach-O 含 x86_64 與 arm64、bundle 1.2.0/build 12001、簽章資源及封裝路徑。CI codesign 驗證通過；僅 ad-hoc，未 Developer ID 簽章／公證。
- 網站 9 頁 validator、71 項 visible facts／FAQ-schema／local anchor 檢查通過；本機瀏覽器完成指南→預覽下載、FAQ 展開及桌面／375 px 檢查，手機無整頁水平溢出。加入實際 Mac 深淺畫面、版本區別、精確暫停語意、剪貼簿告知與 AI 可讀摘要；無變更爬蟲政策或宣稱排名保證。
- 獨立審查：標頭間距修正確認；發現暫停說明不準確後，已對照 LoopCore.togglePause 修正網站、llms 與 Mac 指南並複查。循環 completion-clock 的慢操作測試已在兩平台通過；wrong-sibling-window 原生驗收仍待 Mac 實測。
- 待驗：Mac 真實 Accessibility 授權、外部貼上／送出、同 App 錯誤視窗拒絕、實體 F8，以及所有 DPI／多螢幕／輔助科技情境。使用 [Mac 測試指南](macOS/TESTING.md) 與離線拋棄式目標。CI 畫面不證明訊息送達。
- 交付狀態：可供 Mac 預覽試用；未合併 main、未正式 Release、網站尚未部署。

## 2026-10-14：研究後重設深淺色介面（本機候選，尚未發布）

- 參照 Fluent 2 色彩／按鈕、Apple Dark Mode 與 Material 深色表面指引；研究連結、設計判斷與驗收記於 [visual-design.md](.pdos/specs/visual-design.md)。以中性色表面、圓角卡片／按鈕、單一主要操作、低強調提醒與小型日／月圖示取代前版視覺。此節取代下方「日期欄位仍為原生白底」的歷史限制。
- Windows 日期輸入改為主題化文字欄位，格式 yyyy/MM/dd HH:mm:ss，可依游標所在年月日時分秒以方向鍵／箭頭調整；不再宣稱與原生分段日期控制項完全相同。無效日期不能排程，也不會悄悄沿用舊日期。已驗證不可能日期、閏日、月底／秒進位、時分調整、無效值保留、簡單模式確認／取消及循環無效日期拒絕；未送出外部輸入。
- Windows build、2066 語系／版面／狀態、153 外觀／對比／狀態、15 次原生選單操作、20 日期編輯／排程、共用視窗生命週期、40 循環與 10 原本核心檢查通過。214 keys 五語系完整且 placeholder 一致；30 張深淺色／五語系／兩模式與確認 PNG 已產出，檢視中文與德文深色循環、中文淺色簡單及德文確認畫面。測試只使用自建程序；未改使用者系統主題。
- 按鈕保留 Button 事件／鍵盤語意，圖示有翻譯 tooltip／accessible name；原生語言選單仍能跨時鐘更新保持展開。日期欄位有可存取名稱。未完整驗證螢幕閱讀器、高對比、全部 DPI／多螢幕；OS 捲軸與部分系統繪製仍可能維持原生外觀。自動檢查通過不代表使用者已接受美感。
- Mac source 使用 AppKit 原生色彩、圓角表面、分段模式選擇與 SF Symbols 日／月圖示；尚未編譯或原生渲染驗證。依原約定不公開推送、不跑 Mac CI、不產生 Mac ZIP。保留既有 tracked release EXE；新 Windows 試用檔只放本機候選目錄。

## 2026-10-14：深淺色外觀（尚未發布）

- Windows 啟動讀取使用者的應用程式外觀設定；深色值 0、淺色值 1、缺失／無法讀取時淺色 fallback。僅讀設定，沒有寫入登錄檔。共用標頭新增五語系深淺色切換按鈕，手動選擇只維持本次程序。
- 簡單／循環頁、提示詞、注意事項、狀態、確認／錯誤視窗同步使用主題。自繪語言／提示詞選單及停用按鈕、勾選項和輪次文字保持可讀；主按鈕 hover 也使用足夠對比。日期時間欄位、部分原生箭頭／捲軸／邊框保留 Windows 原生繪製，不宣稱每個 native 元件全部深色化。標題列透過 [Microsoft DWM 深色屬性](https://learn.microsoft.com/windows/apps/desktop/modernize/apply-windows-themes) 請求外觀。
- Windows build、2061 語系／版面檢查、15 次原生語言選單操作、共用視窗生命週期、40 循環與 10 原本核心測試通過。新增 153 項外觀／啟動選擇／對比／狀態檢查，涵蓋兩主題、兩模式、五語系與確認視窗；產出 30 張外觀 PNG。中文深色循環、英文淺色簡單、德文深色確認及停用控制文字已人工檢查。
- 檢查主要文字、提醒、強調、hover／停用文字的應用程式配色達 4.5:1；確認切換不改變提示詞、游標選取、時間、語系、視窗身份或執行中排程。實際系統啟動值與讀值一致，深淺值及缺失值的映射另以可重現測試確認；沒有為測試修改使用者系統主題。
- macOS 原始碼以啟動時有效外觀為初始值，增加手動切換與既有 smoke 中的往返驗證。尚未編譯／執行，仍等 Windows owner review 後另行授權。無公開推送、無 CI／Mac ZIP。
- 未驗證所有 DPI、Windows 高對比與多螢幕組合；沒有重跑原生輸入／送出整合，因本次僅調整外觀，排程與輸入核心未變動。

## 2026-10-14：Windows 語言下拉選單立即收起修正（尚未發布）

- 使用者錄影顯示語言選單無法保持展開，文字短暫錯位。已以原生選單操作重現；切換翻譯資料本身可正常執行。
- Root cause：共享標頭的時鐘 Label 使用 AutoSize，每 100 ms 更新文字便觸發父容器 layout。語言 ComboBox 設為右上錨定並指定 28 px 高度，但在測試環境 native control 實際高度為 25 px（PreferredHeight 也可能為 26 px）。DefaultLayout 反覆套用快取的錨定尺寸，造成 SetWindowPos → WM_SIZE，Windows 將展開中的清單收起。追蹤呼叫堆疊確認來源為 MainForm.UpdateClock → Label.OnTextChanged → header layout → ComboBox.SetBoundsCore。
- 修正：固定時鐘顯示區域，更新文字不再重新排版標頭；將右上錨定移到外層 Panel，內層 ComboBox 保持預設錨定與原生高度，避免重新套用錯誤高度。沒有改動翻譯表、排程或原生輸入引擎；macOS 未涉及此 WinForms 缺陷。
- 新增 LanguagePickerTests：實際向選單箭頭傳入 native 滑鼠訊息，保持時鐘運作並強制父容器／標頭重排，確認清單仍展開，再用 native 鍵盤訊息選取每一種語言。簡單 → 循環 → 簡單共 15 次操作通過，兩模式按鈕皆翻譯且提示詞保留。
- 同一項測試對修正前 Program.cs 回報 `Language list closed during clock/header layout`，修正後退出碼 0。舊測試直接設定 SelectedIndex，未涵蓋使用者展開清單的路徑，這是先前漏檢原因。
- 完整 Windows build、2050 語系／版面檢查、共用視窗生命週期、40 循環核心、10 既有核心及 catalog check 通過。沒有重跑外部輸入引擎測試，因本次未變更該流程。
- 僅交付本機 Windows 修正版；未公開推送，macOS 建置依原約定延後。未宣稱所有 DPI／多螢幕組合均通過。

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
