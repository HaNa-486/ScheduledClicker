import Cocoa

private func runSelfTest() -> Int32 {
    let bounds = ActiveDisplays.bounds()
    guard !bounds.isEmpty else {
        fputs("Self-test failed: no active display.\n", stderr)
        return 1
    }
    guard let point = MacMouse.currentLocation() else {
        fputs("Self-test failed: cannot read cursor location.\n", stderr)
        return 1
    }
    do {
        let single = try MacMouse.makeClickEvents(at: point, clickType: .single)
        let double = try MacMouse.makeClickEvents(at: point, clickType: .double)
        guard single.count == 3, double.count == 5 else {
            fputs("Self-test failed: unexpected event sequence.\n", stderr)
            return 1
        }
    } catch {
        fputs("Self-test failed: \(error.localizedDescription)\n", stderr)
        return 1
    }
    print("macOS self-test passed: displays, cursor capture, and click-event construction are available.")
    return 0
}

if CommandLine.arguments.contains("--self-test") {
    exit(runSelfTest())
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
