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

    private func focusedWindowMatches(_ target: LoopTarget) throws -> Bool {
        try verifyLoopFocus(access: NativeFocusAccess(), process: target.process, point: target.point)
        return true
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

// Compare accessibility identities within one API. AX and CG rectangles need
// not be byte-for-byte equal, and helper windows need not be the focused window.
protocol LoopFocusAccess {
    associatedtype Element
    func focusedWindow(_ process: pid_t) throws -> Element
    func focusedElement(_ process: pid_t) throws -> Element
    func element(at point: CGPoint) throws -> Element
    func window(of element: Element) throws -> Element
    func topLevel(of element: Element) throws -> Element
    func process(of element: Element) throws -> pid_t
    func equal(_ lhs: Element, _ rhs: Element) -> Bool
}

func verifyLoopFocus<A: LoopFocusAccess>(access: A, process: pid_t, point: CGPoint) throws {
    let hit = try access.element(at: point)
    let focused = try access.focusedWindow(process)
    let keyboard = try access.focusedElement(process)
    guard try access.process(of: hit) == process,
          access.process(of: focused) == process,
          access.process(of: keyboard) == process,
          access.equal(access.window(of: hit), focused),
          access.equal(access.window(of: keyboard), focused),
          access.equal(access.topLevel(of: hit), access.topLevel(of: keyboard)) else {
        throw loopError("焦點已離開原本的目標視窗，已停止。")
    }
}

private struct NativeFocusAccess: LoopFocusAccess {
    private func failure(_ stage: String, _ error: AXError) -> NSError {
        loopError("無法驗證目標視窗焦點（\(stage):\(error.rawValue)）；請確認目標 App 的輔助使用支援。")
    }
    private func attribute(_ element: AXUIElement, _ name: CFString, _ stage: String) throws -> AXUIElement {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, name, &value)
        guard result == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { throw failure(stage, result) }
        return value as! AXUIElement
    }
    private func isWindow(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success && (role as? String) == (kAXWindowRole as String)
    }
    func focusedWindow(_ process: pid_t) throws -> AXUIElement {
        try attribute(AXUIElementCreateApplication(process), kAXFocusedWindowAttribute as CFString, "AX.focusedWindow")
    }
    func focusedElement(_ process: pid_t) throws -> AXUIElement {
        try attribute(AXUIElementCreateApplication(process), kAXFocusedUIElementAttribute as CFString, "AX.focusedElement")
    }
    func element(at point: CGPoint) throws -> AXUIElement {
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(point.x), Float(point.y), &element)
        guard result == .success, let element else { throw failure("AX.hitTest", result) }
        return element
    }
    func window(of element: AXUIElement) throws -> AXUIElement {
        if isWindow(element) { return element }
        return try attribute(element, kAXWindowAttribute as CFString, "AX.window")
    }
    func topLevel(of element: AXUIElement) throws -> AXUIElement {
        if isWindow(element) { return element }
        return try attribute(element, kAXTopLevelUIElementAttribute as CFString, "AX.topLevel")
    }
    func process(of element: AXUIElement) throws -> pid_t {
        var pid: pid_t = 0
        let result = AXUIElementGetPid(element, &pid)
        guard result == .success else { throw failure("AX.pid", result) }
        return pid
    }
    func equal(_ lhs: AXUIElement, _ rhs: AXUIElement) -> Bool { CFEqual(lhs, rhs) }
}
