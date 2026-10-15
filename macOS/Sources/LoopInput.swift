import Cocoa

struct LoopTarget {
    let point: CGPoint
    let window: CGWindowID
    let process: pid_t
    let bounds: CGRect
    var layer: Int = 0
    var appName: String { NSRunningApplication(processIdentifier: process)?.localizedName ?? "PID \(process)" }

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
            guard let app = NSRunningApplication(processIdentifier: pid), app.activationPolicy != .prohibited else {
                throw loopError("擷取到無法接受鍵盤輸入的系統視窗，請重新擷取。 [capture.process=\(pid)]")
            }
            return LoopTarget(point: point, window: id, process: pid, bounds: bounds, layer: (item[kCGWindowLayer as String] as? Int) ?? 0)
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
    private var trace: [String] = []
    var activatesTarget: Bool { true }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "12003-dev" }
    var diagnostics: String {
        (["ScheduledClicker build \(Self.build)", "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"] + trace).joined(separator: "\n")
    }
    private func record(_ value: String) { trace.append(value); if trace.count > 30 { trace.removeFirst() } }

    func prepare() throws {
        trace.removeAll()
        guard let input, let submit, input.window == submit.window else {
            throw loopError("請擷取同一目標視窗的輸入框與送出按鈕。")
        }
        guard let snapshot = ActiveDisplays.snapshot() else { throw loopError("無法讀取螢幕配置。") }
        displays = snapshot
        record("target PID=\(input.process) app=\(input.appName) window=\(input.window) layer=\(input.layer)")
    }

    private func check(_ target: LoopTarget, focus: Bool) throws {
        guard AXIsProcessTrusted() else { throw loopError("需要輔助使用權限。") }
        guard displays == ActiveDisplays.snapshot() else { throw loopError("螢幕配置已改變，請重新擷取。") }
        let current = try LoopTarget.capture(target.point)
        guard current.window == target.window, current.process == target.process, current.bounds == target.bounds else {
            throw loopError("目標視窗移動、被遮住或已關閉，請檢查後重新擷取。")
        }
        if focus {
            try checkForeground(target)
            _ = try focusedWindowMatches(target)
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

    private func checkForeground(_ target: LoopTarget) throws {
        let actual = try NativeFocusAccess().focusedApplicationProcess()
        let workspace = NSWorkspace.shared.frontmostApplication?.processIdentifier
        record("foreground expected=\(target.process) AX=\(actual) workspace=\(workspace.map(String.init) ?? "nil")")
        guard actual == target.process else {
            throw loopError("焦點已離開原本的目標視窗，已停止。 [focus.frontmost expected=\(target.process) actual=\(actual) build=\(Self.build)]")
        }
    }

    func activateTarget() throws {
        guard let input, let submit else { throw loopError("請先擷取位置。") }
        try check(input, focus: false); try check(submit, focus: false)
        let actual = try NativeFocusAccess().focusedApplicationProcess()
        record("activation expected=\(input.process) AX=\(actual)")
        if actual == input.process { record("activation already-target"); return }
        guard let app = NSRunningApplication(processIdentifier: input.process), !app.isTerminated,
              app.activationPolicy != .prohibited else { throw loopError("無法啟用目標程式，已停止。 [activate.target]") }
        let accepted: Bool
        if #available(macOS 14.0, *) {
            if NSApp.isActive { NSApp.yieldActivation(to: app) }
            accepted = app.activate(options: [])
        } else { accepted = app.activate(options: [.activateIgnoringOtherApps]) }
        record("activation requested=\(accepted)")
        guard accepted else { throw loopError("無法啟用目標程式，已停止。 [activate.request]") }
        // Request success is not focus success. The engine waits on its timer,
        // then revalidates focus/geometry before clicking. No delayed callbacks.
    }

    private func focusedWindowMatches(_ target: LoopTarget) throws -> Bool {
        try verifyLoopFocus(access: NativeFocusAccess(), process: target.process, point: target.point)
        return true
    }

    func focusInput() throws {
        guard let input, let submit else { throw loopError("請先擷取位置。") }
        try check(input, focus: false); try check(submit, focus: false)
        try checkForeground(input)
        record("input-click")
        try MacMouse.click(at: input.point, clickType: .single)
    }

    func paste(_ prompt: String, replaceDraft: Bool) throws {
        guard let input else { throw loopError("請先擷取位置。") }
        try check(input, focus: true)
        record("paste-validated")
        NSPasteboard.general.clearContents()
        guard NSPasteboard.general.setString(prompt, forType: .string) else { throw loopError("無法寫入剪貼簿。") }
        record("clipboard-written")
        if replaceDraft { try chord(0) } // A
        try chord(9) // V
        record("paste-key-posted")
    }

    func send() throws {
        guard let submit else { throw loopError("請先擷取位置。") }
        try check(submit, focus: true)
        record("send-validated")
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
    func focusedApplicationProcess() throws -> pid_t
    func focusedWindow(_ process: pid_t) throws -> Element
    func focusedElement(_ process: pid_t) throws -> Element
    func element(at point: CGPoint) throws -> Element
    func window(of element: Element) throws -> Element
    func topLevel(of element: Element) throws -> Element
    func process(of element: Element) throws -> pid_t
    func equal(_ lhs: Element, _ rhs: Element) -> Bool
}

func verifyLoopFocus<A: LoopFocusAccess>(access: A, process: pid_t, point: CGPoint) throws {
    let actual = try access.focusedApplicationProcess()
    guard actual == process else { throw loopError("焦點已離開原本的目標視窗，已停止。 [focus.application]") }
    let hit = try access.element(at: point)
    let focused = try access.focusedWindow(process)
    let keyboard = try access.focusedElement(process)
    let hitWindow = try access.window(of: hit)
    let keyboardWindow = try access.window(of: keyboard)
    func require(_ value: Bool, _ code: String) throws {
        if !value { throw loopError("焦點已離開原本的目標視窗，已停止。 [focus.\(code)]") }
    }
    // Web content can live in a remote accessibility process (Safari/WebKit).
    // Bind the owning windows to the captured process, not the leaf elements.
    try require(access.process(of: focused) == process, "focused-pid")
    try require(access.process(of: hitWindow) == process, "hit-window-pid")
    try require(access.process(of: keyboardWindow) == process, "keyboard-window-pid")
    try require(access.equal(hitWindow, focused), "hit-window")
    try require(access.equal(keyboardWindow, focused), "keyboard-window")
    try require(access.equal(access.topLevel(of: hit), access.topLevel(of: keyboard)), "top-level")
}

private struct NativeFocusAccess: LoopFocusAccess {
    func focusedApplicationProcess() throws -> pid_t {
        let app = try attribute(AXUIElementCreateSystemWide(), kAXFocusedApplicationAttribute as CFString, "AX.focusedApplication")
        return try process(of: app)
    }
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
