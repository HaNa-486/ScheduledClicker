import Cocoa

// A compositor rectangle is not an input hit-test: Dock can own large overlay
// surfaces. Capture and revalidation use the same system-wide AX hit identity.
protocol LoopTargetAccess: LoopFocusAccess {
    func bounds(of window: Element) throws -> CGRect
    func isRegularApplication(_ process: pid_t) -> Bool
}

struct LoopTargetIdentity<Element> {
    let window: Element
    let topLevel: Element
    let process: pid_t
    let bounds: CGRect
}

func captureLoopIdentity<A: LoopTargetAccess>(access: A, point: CGPoint) throws -> LoopTargetIdentity<A.Element> {
    let hit = try access.element(at: point)
    let window = try access.window(of: hit)
    let process = try access.process(of: window)
    guard access.isRegularApplication(process) else {
        throw loopError("循環輸入僅支援一般 App 視窗，請重新擷取。 [capture.application]")
    }
    let bounds = try access.bounds(of: window)
    guard [bounds.origin.x, bounds.origin.y, bounds.width, bounds.height].allSatisfy({ $0.isFinite }),
          bounds.width > 0, bounds.height > 0, bounds.contains(point) else {
        throw loopError("無法識別目標視窗，請重新擷取。 [capture.bounds]")
    }
    return LoopTargetIdentity(window: window, topLevel: try access.topLevel(of: hit), process: process, bounds: bounds)
}

func requireSameLoopTarget<A: LoopTargetAccess>(access: A, captured: LoopTargetIdentity<A.Element>, current: LoopTargetIdentity<A.Element>) throws {
    guard captured.process == current.process,
          access.equal(captured.window, current.window),
          access.equal(captured.topLevel, current.topLevel), captured.bounds == current.bounds else {
        throw loopError("目標視窗移動、被遮住或已關閉，請檢查後重新擷取。 [capture.identity]")
    }
}

struct LoopTarget {
    let point: CGPoint
    let identity: LoopTargetIdentity<AXUIElement>
    var process: pid_t { identity.process }
    var appName: String { NSRunningApplication(processIdentifier: process)?.localizedName ?? "PID \(process)" }

    static func capture(_ point: CGPoint) throws -> LoopTarget {
        guard AXIsProcessTrusted() else { throw loopError("需要輔助使用權限。") }
        return LoopTarget(point: point, identity: try captureLoopIdentity(access: NativeFocusAccess(), point: point))
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
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "12004-dev" }
    var diagnostics: String {
        (["ScheduledClicker build \(Self.build)", "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"] + trace).joined(separator: "\n")
    }
    private func record(_ value: String) { trace.append(value); if trace.count > 30 { trace.removeFirst() } }

    func prepare() throws {
        trace.removeAll()
        guard let input, let submit else {
            throw loopError("請擷取同一目標視窗的輸入框與送出按鈕。")
        }
        try requireSameLoopTarget(access: NativeFocusAccess(), captured: input.identity, current: submit.identity)
        guard let snapshot = ActiveDisplays.snapshot() else { throw loopError("無法讀取螢幕配置。") }
        displays = snapshot
        record("target PID=\(input.process) app=\(input.appName) AX-window=\(CFHash(input.identity.window)) source=AX-hit-test")
    }

    private func check(_ target: LoopTarget, focus: Bool) throws {
        guard AXIsProcessTrusted() else { throw loopError("需要輔助使用權限。") }
        guard displays == ActiveDisplays.snapshot() else { throw loopError("螢幕配置已改變，請重新擷取。") }
        let current = try LoopTarget.capture(target.point)
        try requireSameLoopTarget(access: NativeFocusAccess(), captured: target.identity, current: current.identity)
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
              app.activationPolicy == .regular else { throw loopError("無法啟用目標程式，已停止。 [activate.target]") }
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
        try verifyLoopFocus(access: NativeFocusAccess(), captured: target.identity, point: target.point)
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

func verifyLoopFocus<A: LoopFocusAccess>(access: A, captured: LoopTargetIdentity<A.Element>, point: CGPoint) throws {
    let process = captured.process
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
    try require(access.equal(hitWindow, captured.window), "captured-hit-window")
    try require(access.equal(focused, captured.window), "captured-focused-window")
    try require(access.equal(keyboardWindow, captured.window), "captured-keyboard-window")
    try require(access.equal(access.topLevel(of: hit), captured.topLevel), "captured-hit-top-level")
    try require(access.equal(access.topLevel(of: keyboard), captured.topLevel), "captured-keyboard-top-level")
    try require(access.equal(hitWindow, focused), "hit-window")
    try require(access.equal(keyboardWindow, focused), "keyboard-window")
    try require(access.equal(access.topLevel(of: hit), access.topLevel(of: keyboard)), "top-level")
}

private struct NativeFocusAccess: LoopTargetAccess {
    func isRegularApplication(_ process: pid_t) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: process) else { return false }
        return !app.isTerminated && app.activationPolicy == .regular
    }
    func bounds(of window: AXUIElement) throws -> CGRect {
        func value(_ name: CFString, type: AXValueType) throws -> AXValue {
            var raw: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(window, name, &raw)
            guard result == .success, let raw, CFGetTypeID(raw) == AXValueGetTypeID() else {
                throw failure("AX.bounds", result)
            }
            let value = raw as! AXValue
            guard AXValueGetType(value) == type else { throw failure("AX.boundsType", .illegalArgument) }
            return value
        }
        var origin = CGPoint.zero, size = CGSize.zero
        let position = try value(kAXPositionAttribute as CFString, type: .cgPoint)
        let dimensions = try value(kAXSizeAttribute as CFString, type: .cgSize)
        guard AXValueGetValue(position, .cgPoint, &origin), AXValueGetValue(dimensions, .cgSize, &size) else {
            throw failure("AX.boundsValue", .illegalArgument)
        }
        return CGRect(origin: origin, size: size)
    }
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
        let window = try attribute(element, kAXWindowAttribute as CFString, "AX.window")
        guard isWindow(window) else { throw failure("AX.windowRole", .illegalArgument) }
        return window
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
