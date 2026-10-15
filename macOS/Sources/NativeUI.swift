import Cocoa

final class ModeContentView: NSView { override var isFlipped: Bool { true } }

// The local monitor also handles scrolling while AppKit's shared field editor
// owns focus. It consumes only events over this enabled, visible field.
final class WheelNumberField: NSTextField {
    let range: ClosedRange<Int>
    private var monitor: Any?
    private var accumulated: CGFloat = 0
    private var lastScroll: TimeInterval = 0
    init(_ value: Int, range: ClosedRange<Int>) {
        self.range = range
        super.init(frame: .zero)
        stringValue = String(value)
        alignment = .right
    }
    required init?(coder: NSCoder) { fatalError("Programmatic control") }
    deinit { if let monitor { NSEvent.removeMonitor(monitor) } }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let monitor { NSEvent.removeMonitor(monitor) }; monitor = nil
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, let window = self.window, event.window === window,
                  window.isKeyWindow, self.isEnabled, !self.isHiddenOrHasHiddenAncestor,
                  self.bounds.contains(self.convert(event.locationInWindow, from: nil)) else { return event }
            self.scrollWheel(with: event)
            return nil
        }
    }
    override func scrollWheel(with event: NSEvent) {
        adjust(delta: event.scrollingDeltaY, precise: event.hasPreciseScrollingDeltas,
               momentum: !event.momentumPhase.isEmpty, timestamp: event.timestamp,
               began: event.phase.contains(.began))
    }
    func adjust(delta: CGFloat, precise: Bool, momentum: Bool, timestamp: TimeInterval, began: Bool = false) {
        guard isEnabled, !isHiddenOrHasHiddenAncestor, !momentum, delta.isFinite, delta != 0 else { return }
        if began || timestamp - lastScroll > 0.25 || accumulated * delta < 0 { accumulated = 0 }
        lastScroll = timestamp
        let steps: Int
        if precise {
            accumulated += delta
            steps = Int(accumulated / 12)
            accumulated -= CGFloat(steps) * 12
        } else { steps = delta > 0 ? 1 : -1; accumulated = 0 }
        guard steps != 0 else { return }
        let text = currentEditor()?.string ?? stringValue
        guard let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)), range.contains(value) else { return }
        let next = min(range.upperBound, max(range.lowerBound, value + steps))
        stringValue = String(next)
        if let editor = currentEditor() { editor.string = stringValue; editor.selectedRange = NSRange(location: 0, length: stringValue.utf16.count) }
        sendAction(action, to: target)
    }
}

enum NativeUI {
    static func card(_ title: String, frame: NSRect) -> NSBox {
        let box = NSBox(frame: frame)
        box.boxType = .custom; box.titlePosition = .noTitle
        box.borderColor = .separatorColor; box.borderWidth = 0; box.cornerRadius = 12
        box.fillColor = .controlBackgroundColor
        return box
    }
    static func label(_ text: String, frame: NSRect, heading: Bool = false) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.frame = frame; field.font = heading ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
        return field
    }
}
