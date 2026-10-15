import Cocoa

// Test identities, not coordinates: different windows can have identical frames.
struct FakeAccess: LoopFocusAccess {
    var hit = "inputA", keyboard = "inputA", focused = "windowA"
    var unavailable = false
    var foreground: pid_t = 42
    func focusedApplicationProcess() throws -> pid_t { foreground }
    func focusedWindow(_ process: pid_t) throws -> String { focused }
    func focusedElement(_ process: pid_t) throws -> String { keyboard }
    func element(at point: CGPoint) throws -> String {
        if unavailable { throw loopError("AX unavailable") }; return hit
    }
    func window(of element: String) throws -> String {
        if element == "foreign" { return "foreignWindow" }
        return element.hasSuffix("B") ? "windowB" : "windowA"
    }
    func topLevel(of element: String) throws -> String {
        element == "sheetA" ? "sheetA" : try window(of: element)
    }
    func process(of element: String) throws -> pid_t { ["foreign", "foreignWindow", "remoteInput"].contains(element) ? 99 : 42 }
    func equal(_ lhs: String, _ rhs: String) -> Bool { lhs == rhs }
}
var checks = 0
func expect(_ access: FakeAccess, allowed: Bool, _ reason: String) {
    var accepted = false
    do { try verifyLoopFocus(access: access, process: 42, point: CGPoint(x: 100, y: 100)); accepted = true } catch {}
    checks += 1
    if accepted != allowed { fatalError(reason) }
}
expect(FakeAccess(), allowed: true, "Same window identity accepts independently of AX/CG geometry")
var inactive = FakeAccess(); inactive.foreground = 99
expect(inactive, allowed: false, "Old focused-window data must not pass when another application owns keyboard focus")
var remote = FakeAccess(); remote.hit = "remoteInput"; remote.keyboard = "remoteInput"
expect(remote, allowed: true, "Web content leaf PID may differ when owning AX window identity matches")
var sample = FakeAccess(); sample.focused = "windowB"; sample.keyboard = "inputB"
expect(sample, allowed: false, "Same-process sibling window must not receive input")
sample = FakeAccess(); sample.hit = "inputB"
expect(sample, allowed: false, "Hit testing another window must fail")
sample = FakeAccess(); sample.keyboard = "sheetA"
expect(sample, allowed: false, "Modal sheet with same containing window must fail")
sample = FakeAccess(); sample.keyboard = "inputB"
expect(sample, allowed: false, "Focused element cannot belong to a different window")
sample = FakeAccess(); sample.hit = "foreign"
expect(sample, allowed: false, "Foreign hit process must fail")
sample = FakeAccess(); sample.keyboard = "foreign"
expect(sample, allowed: false, "Foreign keyboard process must fail")
sample = FakeAccess(); sample.unavailable = true
expect(sample, allowed: false, "Unavailable AX must fail closed")
print("PASS: \(checks) focus identity policy checks (no native input)")
