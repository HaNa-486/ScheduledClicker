# Changelog

本專案的重大變更會記錄在此。格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本採用 [Semantic Versioning](https://semver.org/lang/zh-TW/)。

## [1.1.2] - 2026-08-28

### Fixed

- macOS 目前時間改為每秒約 30 次更新，讓三位毫秒正常變化；同時快取日期格式器並在控制項互動期間持續刷新。
- 修正 v1.1.1 GitHub Release 說明把換行顯示成 `\\n` 文字的排版問題。

### Changed

- GitHub 專案描述與 Topics 補齊 macOS、Apple silicon、AppKit 與深色模式資訊。
- GitHub Pages 新增 Windows、macOS、Codex 使用情境、安全驗證、下載、FAQ 與 Changelog 獨立頁面。
- 首頁加入真實介面圖片、FAQ 結構化資料，並擴充軟體版本、截圖與發布資訊的 JSON-LD。

### Verified

- 使用者已在 MacBook Air 實機確認 v1.1.1 功能與深色模式介面可讀，並以螢幕錄影回報毫秒刷新問題。

## [1.1.1] - 2026-08-28

### Fixed

- 修正 macOS 在深色外觀下因固定淺色背景搭配動態系統文字色，造成白字白底、欄位幾乎不可見的問題。

### Changed

- 重整 macOS 介面的標題、目前時間、時間模式、位置擷取、點擊方式、主要操作及狀態資訊層級。
- 將時間模式改為分段選擇，並只顯示目前模式需要的指定時間或倒數欄位。
- macOS 建置新增 Aqua 與 Dark Aqua 介面煙霧測試，檢查文字對比及兩種模式的欄位可見性。

### Verified

- 使用者已在 Windows 11 實機確認 v1.1.0 功能可用，並在 MacBook Air 確認 v1.1.0 的排程功能可用；macOS 深色模式介面缺陷由本版修正。

## [1.1.0] - 2026-08-26

### Added

- 原生 macOS 13+ AppKit 版本，同時支援 Apple silicon 與 Intel Mac。
- macOS 指定時間、單調倒數延遲、三秒位置擷取、單擊／雙擊、即時時鐘、取消及 `F8` 緊急停止。
- macOS 輔助使用權限檢查、逾期五秒取消、完整顯示器配置快照比對及座標防誤點機制。
- 零第三方套件的 universal app 建置、測試、ad-hoc 簽章、ZIP 封裝與 SHA-256 腳本。
- GitHub Actions 的 Windows 回歸測試與真實 macOS runner 建置／測試／安全驗證。

### Changed

- README、Security、Verification、GitHub Pages、結構化資料、AI 可讀摘要與社群預覽更新為 Windows + macOS。

### Security

- 兩個平台都維持本機運作，沒有網路、遙測、帳號、持久化或第三方執行期套件。
- macOS 滑鼠控制必須由使用者在系統設定明確授予輔助使用權限。

## [1.0.0] - 2026-08-26

### Added

- Windows 11 傳統中文 WinForms 使用者介面與即時時鐘。
- 指定未來日期時間與倒數延遲兩種一次性排程。
- 三秒倒數擷取螢幕座標，以及滑鼠單擊／雙擊。
- 排程確認、取消按鈕及排程期間的全域 `F8` 緊急停止。
- Per-Monitor V2 DPI、多螢幕負座標、逾期及螢幕配置變動安全檢查。
- 不受系統時鐘校正影響的單調倒數計時。
- 原始碼建置腳本、核心測試、安全說明與驗證報告。
- MIT License。
- 中英雙語 GitHub README、SEO／AI 搜尋友善 FAQ 與 GitHub Pages 官方落地頁。
- Open Graph 社群分享圖、`SoftwareApplication` 結構化資料、sitemap、robots.txt 與 AI 可讀摘要。

### Verified

- 核心自動測試 10/10 通過。
- Microsoft Defender 掃描未發現威脅。
- 使用者在 Windows 11 實機成功完成指定時間與倒數延遲兩種模式。
