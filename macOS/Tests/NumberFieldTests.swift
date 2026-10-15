import Cocoa

let app = NSApplication.shared
let host = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 120), styleMask: [.titled], backing: .buffered, defer: false)
let field = WheelNumberField(30, range: 0...59)
field.frame = NSRect(x: 20, y: 20, width: 80, height: 28)
host.contentView!.addSubview(field)
var checks = 0
func check(_ ok: Bool, _ name: String) { checks += 1; if !ok { fatalError(name) } }
func wheel(_ delta: CGFloat, precise: Bool = false, momentum: Bool = false, time: TimeInterval = 1) {
    field.adjust(delta: delta, precise: precise, momentum: momentum, timestamp: time)
}
wheel(1); check(field.stringValue == "31", "wheel increases")
wheel(-1); check(field.stringValue == "30", "wheel decreases")
field.stringValue = "59"; wheel(1); check(field.stringValue == "59", "upper bound")
field.stringValue = "0"; wheel(-1); check(field.stringValue == "0", "lower bound")
field.stringValue = "30"; wheel(6, precise: true, time: 2); check(field.stringValue == "30", "trackpad accumulation")
wheel(6, precise: true, time: 2.1); check(field.stringValue == "31", "trackpad threshold")
wheel(120, precise: true, momentum: true); check(field.stringValue == "31", "momentum ignored")
field.isEnabled = false; wheel(1); check(field.stringValue == "31", "disabled field")
field.isEnabled = true; field.stringValue = "invalid"; wheel(1); check(field.stringValue == "invalid", "invalid draft preserved")
field.stringValue = "30"; host.makeFirstResponder(field)
check(field.currentEditor() != nil, "active field editor")
field.currentEditor()?.string = "42"; wheel(1)
check(field.stringValue == "43" && field.currentEditor()?.string == "43", "wheel uses active typed draft")
host.makeFirstResponder(nil)
check(field.stringValue == "43", "field editor does not restore stale value")
host.contentView!.isHidden = true; wheel(1); check(field.stringValue == "43", "hidden mode ignores scroll")
host.contentView!.isHidden = false
let wait = WheelNumberField(1, range: 1...10)
wait.adjust(delta: -1, precise: false, momentum: false, timestamp: 1)
check(wait.stringValue == "1", "step delay minimum")
wait.stringValue = "10"; wait.adjust(delta: 1, precise: false, momentum: false, timestamp: 1)
check(wait.stringValue == "10", "step delay maximum")
print("PASS: \(checks) Mac number field checks (no external input)")
