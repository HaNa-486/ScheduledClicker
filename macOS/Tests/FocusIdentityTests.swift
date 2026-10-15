import Cocoa

// Test identities, not coordinates: different windows can have identical frames.
final class HitSequence { var calls = 0 }
struct FakeAccess: LoopTargetAccess {
    var sequence: HitSequence?
    var hit = "inputA", keyboard = "inputA", focused = "windowA"
    var unavailable = false
    var foreground: pid_t = 42
    var regular = true, missingWindow = false
    var frame = CGRect(x: 0, y: 0, width: 600, height: 400)
    func bounds(of window: String) throws -> CGRect { frame }
    func isRegularApplication(_ process: pid_t) -> Bool { regular }
    func focusedApplicationProcess() throws -> pid_t { foreground }
    func focusedWindow(_ process: pid_t) throws -> String { focused }
    func focusedElement(_ process: pid_t) throws -> String { keyboard }
    func element(at point: CGPoint) throws -> String {
        if unavailable { throw loopError("AX unavailable") }
        if let sequence { sequence.calls += 1; return sequence.calls == 1 ? "inputA" : "inputB" }
        return hit
    }
    func window(of element: String) throws -> String {
        if missingWindow { throw loopError("AX.window unavailable") }
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
    do { try verifyLoopFocus(access: access, captured: captureLoopIdentity(access: FakeAccess(), point: CGPoint(x: 100, y: 100)), point: CGPoint(x: 100, y: 100)); accepted = true } catch {}
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
// Capture and every later step must remain bound to the original AX window,
// even when current hit and keyboard focus agree on a different same-frame sibling.
let point = CGPoint(x: 100, y: 100)
func expectCapture(_ access: FakeAccess, allowed: Bool, _ reason: String) {
    var accepted = false
    do { _ = try captureLoopIdentity(access: access, point: point); accepted = true } catch {}
    checks += 1
    if accepted != allowed { fatalError(reason) }
}
func expectRevalidation(_ access: FakeAccess, captured: LoopTargetIdentity<String>, allowed: Bool, _ reason: String) {
    var accepted = false
    do {
        let current = try captureLoopIdentity(access: access, point: point)
        try requireSameLoopTarget(access: access, captured: captured, current: current)
        accepted = true
    } catch {}
    checks += 1
    if accepted != allowed { fatalError(reason) }
}
let captured = try captureLoopIdentity(access: FakeAccess(), point: point)
checks += 1
if captured.process != 42 || captured.window != "windowA" { fatalError("Capture owner must come from the hit AX window, never a compositor rectangle or foreground app") }
var otherForeground = FakeAccess(); otherForeground.foreground = 99
expectCapture(otherForeground, allowed: true, "Capturing a visible inactive app must not bind to the frontmost process")
expectCapture(remote, allowed: true, "Remote WebKit leaf resolves to owning app window")
var blocked = FakeAccess(); blocked.regular = false
expectCapture(blocked, allowed: false, "Real Dock/system/accessory hit rejected; never search under it")
blocked = FakeAccess(); blocked.missingWindow = true
expectCapture(blocked, allowed: false, "Element without owning AX window rejects without fallback")
blocked = FakeAccess(); blocked.unavailable = true
expectCapture(blocked, allowed: false, "Unavailable hit testing must not fall back to CG bounds")
for frame in [CGRect(x: 0, y: 0, width: 0, height: 400), CGRect(x: 0, y: 0, width: -1, height: 400), CGRect(x: CGFloat.nan, y: 0, width: 600, height: 400), CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 400), CGRect(x: 500, y: 500, width: 600, height: 400)] {
    blocked = FakeAccess(); blocked.frame = frame
    expectCapture(blocked, allowed: false, "Invalid/off-point window geometry must reject")
}
expectRevalidation(FakeAccess(), captured: captured, allowed: true, "Unchanged target remains usable")
expectRevalidation(remote, captured: captured, allowed: true, "Remote leaf does not alter original window identity")
blocked = FakeAccess(); blocked.hit = "inputB"; blocked.keyboard = "inputB"; blocked.focused = "windowB"
expectRevalidation(blocked, captured: captured, allowed: false, "Same-process same-frame replacement must fail even if hit and focus agree")
blocked = FakeAccess(); blocked.hit = "sheetA"
expectRevalidation(blocked, captured: captured, allowed: false, "New modal top-level container must fail")
blocked = FakeAccess(); blocked.hit = "foreign"
expectRevalidation(blocked, captured: captured, allowed: false, "Foreign overlay must fail")
blocked = FakeAccess(); blocked.frame.origin.x += 1
expectRevalidation(blocked, captured: captured, allowed: false, "Window move must fail")
blocked = FakeAccess(); blocked.frame.size.width += 1
expectRevalidation(blocked, captured: captured, allowed: false, "Window resize must fail")
blocked = FakeAccess(); blocked.unavailable = true
expectRevalidation(blocked, captured: captured, allowed: false, "Closed/minimized/unavailable target must fail")
// This same check is used by prepare to reject mismatched input/send captures.
blocked = FakeAccess(); blocked.hit = "inputB"
expectRevalidation(blocked, captured: captured, allowed: false, "Input and send captures in different same-PID windows cannot prepare")
var changing = FakeAccess(); changing.sequence = HitSequence(); changing.focused = "windowB"; changing.keyboard = "inputB"
let firstHit = try captureLoopIdentity(access: changing, point: point)
try requireSameLoopTarget(access: changing, captured: captured, current: firstHit)
var raceRejected = false
do { try verifyLoopFocus(access: changing, captured: captured, point: point) } catch { raceRejected = true }
checks += 1
if !raceRejected { fatalError("Second hit cannot silently rebind captured A to same-frame sibling B") }
print("PASS: \(checks) focus/capture identity policy checks (no native input)")
