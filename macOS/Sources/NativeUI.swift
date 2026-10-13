import Cocoa

final class ModeContentView: NSView { override var isFlipped: Bool { true } }

enum NativeUI {
    static func card(_ title: String, frame: NSRect) -> NSBox {
        let box = NSBox(frame: frame)
        box.boxType = .custom; box.titlePosition = .noTitle
        box.borderColor = .separatorColor; box.borderWidth = 1; box.cornerRadius = 8
        box.fillColor = .controlBackgroundColor
        return box
    }
    static func label(_ text: String, frame: NSRect, heading: Bool = false) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.frame = frame; field.font = heading ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
        return field
    }
}
