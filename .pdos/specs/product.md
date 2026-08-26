# Product

## Problem and user

Windows 11 使用者需要在無人操作的未來時間，於固定螢幕座標執行單擊或雙擊。主要公開使用情境是：ChatGPT Plus／Codex 使用者可依產品畫面顯示的額度重設時間，在合法恢復可用後送出預先準備的提示，讓中斷的 Session 繼續。

## Desired outcome and success signal

單一免安裝 EXE 提供可讀時鐘、指定時間與倒數延遲、座標擷取、單/雙擊、取消及清楚狀態；不依賴第三方套件或網路。

## Scope and non-goals

範圍：Windows 11、目前登入使用者工作階段、固定座標、一次性排程。非目標：依圖片辨識按鈕、重複巨集、背景服務、跨重新啟動持久化、繞過 Windows 權限隔離，或繞過／重設任何第三方服務的用量限制。

## Critical journey

開啟工具 → 選擇時間模式 → 擷取游標位置 → 選擇點擊方式 → 確認排程 → 倒數 → 準時移動游標並點擊；可在執行前以按鈕或 F8 取消。
