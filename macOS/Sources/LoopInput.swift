import Cocoa

struct LoopTarget {
    let point: CGPoint
    let window: CGWindowID
    let process: pid_t
    let bounds: CGRect

    static func capture(_ point: CGPoint) throws -> LoopTarget {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            throw loopError("無法識別目標視窗，請重新擷取。")
        }
        for item in windows {
            guard let raw = item[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: raw as CFDictionary), bounds.contains(point),
                  let id = item[kCGWindowNumber as String] as? UInt32,
                  let pid = item[kCGWindowOwnerPID as String] as? Int32,
                  (item[kCGWindowAlpha as String] as? Double ?? 1) > 0 else { continue }
            return LoopTarget(point: point, window: id, process: pid, bounds: bounds)
        }
        throw loopError("目標位置沒有可操作的視窗。")
    }
}

func loopError(_ message: String) -> NSError {
    NSError(domain: "LoopInput", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
}

final class NativeLoopInput: LoopActions {
    var input: LoopTarget?
    var submit: LoopTarget?
    private var displays: DisplaySnapshot?

    func prepare() throws {
        guard let input, let submit, input.window == submit.window else {
            throw loopError("請擷取同一目標視窗的輸入框與送出按鈕。")
        }
        guard let snapshot = ActiveDisplays.snapshot() else { throw loopError("無法讀取螢幕配置。") }
        displays = snapshot
    }

    private func check(_ target: LoopTarget, focus: Bool) throws {
        guard AXIsProcessTrusted() else { throw loopError("需要輔助使用權限。") }
        guard displays == ActiveDisplays.snapshot() else { throw loopError("螢幕配置已改變，請重新擷取。") }
        let current = try LoopTarget.capture(target.point)
        guard current.window == target.window, current.process == target.process, current.bounds == target.bounds else {
            throw loopError("目標視窗移動、被遮住或已關閉，請檢查後重新擷取。")
        }
        if focus {
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == target.process,
                  try focusedWindowMatches(target) else {
                throw loopError("焦點已離開原本的目標視窗，已停止。")
            }
        }
        let flags = CGEventSource.flagsState(.combinedSessionState)
        if !flags.intersection([.maskShift, .maskControl, .maskAlternate, .maskCommand]).isEmpty {
            throw loopError("偵測到修飾鍵按住，已停止。")
        }
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any],
              session[kCGSessionOnConsoleKey as String] as? Bool == true,
              session["CGSSessionScreenIsLocked"] as? Bool != true else {
            throw loopError("桌面已鎖定或不可操作，排程已停止。")
        }
    }

    // Check both accessibility focus geometry and front-to-back CG window identity.
    // A sibling window of the same process must never receive the prompt.
    private func focusedWindowMatches(_ target: LoopTarget) throws -> Bool {
        let application = AXUIElementCreateApplication(target.process)
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, &focused) == .success,
              let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return false }
        let window = focused as! AXUIElement
        var rawPosition: CFTypeRef?
        var rawSize: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &rawPosition) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &rawSize) == .success,
              let rawPosition, let rawSize,
              CFGetTypeID(rawPosition) == AXValueGetTypeID(), CFGetTypeID(rawSize) == AXValueGetTypeID() else { return false }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(rawPosition as! AXValue, .cgPoint, &position),
              AXValueGetValue(rawSize as! AXValue, .cgSize, &size),
              CGRect(origin: position, size: size) == target.bounds,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return false }
        let frontWindow = windows.first { ($0[kCGWindowOwnerPID as String] as? Int32) == target.process && ($0[kCGWindowAlpha as String] as? Double ?? 1) > 0 }
        return frontWindow?[kCGWindowNumber as String] as? UInt32 == target.window
    }

    func focusInput() throws {
        guard let input, let submit else { throw loopError("請先擷取位置。") }
        try check(input, focus: false); try check(submit, focus: false)
        try MacMouse.click(at: input.point, clickType: .single)
    }

    func paste(_ prompt: String, replaceDraft: Bool) throws {
        guard let input else { throw loopError("請先擷取位置。") }
        try check(input, focus: true)
        NSPasteboard.general.clearContents()
        guard NSPasteboard.general.setString(prompt, forType: .string) else { throw loopError("無法寫入剪貼簿。") }
        if replaceDraft { try chord(0) } // A
        try chord(9) // V
    }

    func send() throws {
        guard let submit else { throw loopError("請先擷取位置。") }
        try check(submit, focus: true)
        try MacMouse.click(at: submit.point, clickType: .single)
    }

    private func chord(_ key: CGKeyCode) throws {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) else {
            throw loopError("macOS 無法建立鍵盤事件。")
        }
        down.flags = .maskCommand
        up.flags = []
        down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap)
    }
}
